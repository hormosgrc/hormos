#!/bin/sh
# ════════════════════════════════════════════════════════════════════
# Hormos — cria e configura o usuário do Linux dentro do WSL.
#
# POR QUE É UM ARQUIVO, E NÃO UMA LINHA NO install.bat:
#
#   A versão anterior era um `wsl -- bash -c "..."` de uma linha, com pipe,
#   redirecionamento, chaves e substituição de comando dentro de aspas duplas
#   do cmd.exe. A lógica do shell estava certa — testada isolada num Ubuntu
#   real, gerava os 14 caracteres. O que quebrou foi a travessia: o cmd
#   entregou ao bash algo diferente do que estava escrito, o arquivo da senha
#   nunca foi criado, e o `chpasswd` recebeu senha VAZIA. Três camadas de
#   aspas é o mesmo erro que já havia sido evitado no PowerShell.
#
# POR QUE CADA PASSO TEM ALTERNATIVA, E NÃO SÓ MENSAGEM DE ERRO:
#
#   Quem roda isto não tem como consertar nada à mão — é o ponto de instalar
#   um appliance. Então cada coisa que pode não existir nesta máquina tem um
#   segundo e um terceiro caminho, e a falha só é anunciada quando TODOS
#   falharam. Em particular:
#
#     · gerar senha      — /dev/urandom, openssl, ou /proc + sha256
#     · aplicar senha    — chpasswd, passwd, ou hash + usermod -p
#     · grupo de sudo    — sudo ou wheel, o que existir
#     · grupo docker     — só se já existir; não inventa grupo
#
# Uso:  preparar-usuario-wsl.sh <usuario>
# Saída: a ÚLTIMA linha é a senha. Tudo mais vai para stderr, para a senha
#        poder ser capturada sem filtro.
# Saídas: 0 pronto · 1 falhou (com o motivo em stderr)
# ════════════════════════════════════════════════════════════════════
set -u

USUARIO="${1:-hormos}"
ARQ_SENHA=/root/.senha-ubuntu
TAM=16

aviso() { printf '      %s\n' "$*" >&2; }
erro()  { printf '  X %s\n' "$*" >&2; }

# ── 0. Pré-condições ────────────────────────────────────────────────
if [ "$(id -u 2>/dev/null)" != "0" ]; then
  erro "este script precisa rodar como root (wsl -u root)."
  exit 1
fi

case "$USUARIO" in
  # O nome vai para useradd e para o wsl.conf. Recusar aqui é melhor que
  # descobrir adiante com meio trabalho feito.
  ''|*[!a-z0-9_-]*|[!a-z_]*)
    erro "nome de usuário inválido: '$USUARIO' (use minúsculas, dígitos, - e _)."
    exit 1 ;;
esac

# ── 1. A senha ──────────────────────────────────────────────────────
# Sem ':' em NENHUMA hipótese: o chpasswd separa usuário de senha nesse
# caractere, e uma senha que o contenha é truncada em silêncio. Sem / + =
# também, que atrapalham quem digita à mão.
gerar_senha() {
  if [ -r /dev/urandom ] && command -v tr >/dev/null 2>&1; then
    s=$(tr -dc 'A-Za-z0-9' < /dev/urandom 2>/dev/null | head -c "$TAM" 2>/dev/null) || s=''
    [ "${#s}" -eq "$TAM" ] && { printf '%s' "$s"; return 0; }
  fi
  if command -v openssl >/dev/null 2>&1; then
    s=$(openssl rand -base64 48 2>/dev/null | tr -dc 'A-Za-z0-9' | head -c "$TAM") || s=''
    [ "${#s}" -eq "$TAM" ] && { printf '%s' "$s"; return 0; }
  fi
  # Último recurso, sem depender de /dev/urandom nem de openssl.
  if command -v sha256sum >/dev/null 2>&1; then
    s=$( { date +%s%N; cat /proc/sys/kernel/random/uuid 2>/dev/null; cat /proc/self/stat 2>/dev/null; } \
         | sha256sum | tr -dc 'A-Za-z0-9' | head -c "$TAM") || s=''
    [ "${#s}" -eq "$TAM" ] && { printf '%s' "$s"; return 0; }
  fi
  return 1
}

if [ -s "$ARQ_SENHA" ]; then
  # Já existe: NÃO regenerar. Rodar o instalador de novo não pode trocar uma
  # senha que a pessoa já anotou.
  SENHA=$(cat "$ARQ_SENHA")
  aviso "senha já existente reaproveitada."
else
  SENHA=$(gerar_senha) || {
    erro "não consegui gerar uma senha (sem /dev/urandom, openssl ou sha256sum)."
    exit 1
  }
  umask 077
  printf '%s' "$SENHA" > "$ARQ_SENHA" || { erro "não consegui gravar $ARQ_SENHA."; exit 1; }
  chmod 600 "$ARQ_SENHA" 2>/dev/null || true
fi

if [ -z "$SENHA" ] || [ "${#SENHA}" -lt 8 ]; then
  erro "a senha saiu vazia ou curta demais — abortando antes de aplicar."
  exit 1
fi

# ── 2. O usuário ────────────────────────────────────────────────────
if id "$USUARIO" >/dev/null 2>&1; then
  aviso "usuário $USUARIO já existe."
else
  useradd -m -s /bin/bash "$USUARIO" 2>/dev/null \
    || adduser --disabled-password --gecos '' "$USUARIO" >/dev/null 2>&1 \
    || { erro "não consegui criar o usuário $USUARIO."; exit 1; }
fi

# Diretório pessoal: o useradd pode não tê-lo criado se /etc/skel faltar, e aí
# o login cai numa pasta que não existe.
HOME_U=$(getent passwd "$USUARIO" | cut -d: -f6)
[ -n "$HOME_U" ] && [ ! -d "$HOME_U" ] && {
  mkdir -p "$HOME_U" && chown "$USUARIO" "$HOME_U" && aviso "criei $HOME_U, que faltava."
}

# ── 3. Aplicar a senha — três caminhos ──────────────────────────────
senha_confere() {
  # 'P' = senha utilizável. 'L' = travada, 'NP' = sem senha.
  if command -v passwd >/dev/null 2>&1; then
    [ "$(passwd -S "$USUARIO" 2>/dev/null | awk '{print $2}')" = "P" ] && return 0
  fi
  # Sem o `passwd`, lê o shadow direto. MEDIDO: sem esta alternativa o terceiro
  # caminho (hash + usermod) nunca conseguia se confirmar — o usermod gravava
  # certo, a verificação dizia que não, e o script anunciava falha tendo tido
  # êxito. E é exatamente o cenário para o qual esse caminho existe: quando
  # chpasswd e passwd não estão disponíveis.
  h=$(getent shadow "$USUARIO" 2>/dev/null | cut -d: -f2)
  case "$h" in
    '$'*) return 0 ;;   # tem hash de senha utilizável
    *)    return 1 ;;   # vazio, '!' (travada) ou '*' (sem login)
  esac
}

aplicou=nao

if printf '%s:%s\n' "$USUARIO" "$SENHA" | chpasswd 2>/dev/null && senha_confere; then
  aplicou=chpasswd
fi

if [ "$aplicou" = nao ] && command -v passwd >/dev/null 2>&1; then
  # O chpasswd passa pelo PAM e pode ser recusado por regra de qualidade de
  # senha. O passwd --stdin não existe no Debian/Ubuntu, então vai pela
  # entrada padrão, duas vezes.
  if printf '%s\n%s\n' "$SENHA" "$SENHA" | passwd "$USUARIO" >/dev/null 2>&1 && senha_confere; then
    aplicou=passwd
  fi
fi

if [ "$aplicou" = nao ]; then
  # Último caminho: calcular o hash aqui e escrevê-lo direto, sem passar pelo
  # PAM. Fecha o caso de pam_pwquality recusando a senha gerada.
  HASH=''
  if command -v openssl >/dev/null 2>&1; then
    HASH=$(openssl passwd -6 "$SENHA" 2>/dev/null) || HASH=''
  fi
  if [ -z "$HASH" ] && command -v python3 >/dev/null 2>&1; then
    # -W ignore: a partir do Python 3.12 o módulo crypt emite DeprecationWarning.
    # Sem silenciá-lo, o aviso ia junto com o hash se o stderr fosse capturado,
    # e o usermod recusava com "failure while writing changes to /etc/shadow".
    HASH=$(python3 -W ignore -c 'import crypt,sys; print(crypt.crypt(sys.argv[1], crypt.mksalt(crypt.METHOD_SHA512)))' "$SENHA" 2>/dev/null) || HASH=''
  fi
  if [ -n "$HASH" ] && usermod -p "$HASH" "$USUARIO" 2>/dev/null && senha_confere; then
    aplicou=hash
  fi
fi

if [ "$aplicou" = nao ]; then
  erro "não consegui definir a senha de $USUARIO (chpasswd, passwd e hash direto falharam)."
  erro "estado: $(passwd -S "$USUARIO" 2>&1 | head -1)"
  exit 1
fi
aviso "senha aplicada via $aplicou."

# ── 4. Grupos ───────────────────────────────────────────────────────
# sudo no Debian/Ubuntu, wheel em outras. Usa o que existir; não inventa.
for g in sudo wheel; do
  if getent group "$g" >/dev/null 2>&1; then
    usermod -aG "$g" "$USUARIO" 2>/dev/null && aviso "no grupo $g." && break
  fi
done

# docker SÓ se o grupo já existir. Criá-lo aqui faria um grupo sem o daemon
# correspondente, e o usuário teria permissão para um socket que não existe —
# parecendo configurado sem estar.
if getent group docker >/dev/null 2>&1; then
  usermod -aG docker "$USUARIO" 2>/dev/null && aviso "no grupo docker."
else
  aviso "grupo docker ainda não existe; será preciso reexecutar após o Docker."
fi

# ── 5. Usuário padrão do WSL ────────────────────────────────────────
# Sem isto, abrir o aplicativo "Ubuntu" entra como root e a pessoa opera tudo
# como root sem saber. Trata as três situações do arquivo, não só a ausência:
# sem arquivo, com [user] já lá (troca o valor), e sem [user] (acrescenta).
CONF=/etc/wsl.conf
if [ ! -f "$CONF" ]; then
  printf '[user]\ndefault=%s\n' "$USUARIO" > "$CONF"
elif grep -q '^[[:space:]]*\[user\]' "$CONF"; then
  if grep -q '^[[:space:]]*default[[:space:]]*=' "$CONF"; then
    # Reescreve o valor em vez de acrescentar uma segunda linha `default=`,
    # que deixaria o arquivo ambíguo.
    sed -i "s|^[[:space:]]*default[[:space:]]*=.*|default=$USUARIO|" "$CONF" \
      || aviso "não consegui reescrever o default em $CONF."
  else
    sed -i "s|^[[:space:]]*\[user\][[:space:]]*$|[user]\ndefault=$USUARIO|" "$CONF" \
      || aviso "não consegui acrescentar o default em $CONF."
  fi
else
  printf '\n[user]\ndefault=%s\n' "$USUARIO" >> "$CONF"
fi
grep -q "default=$USUARIO" "$CONF" 2>/dev/null \
  && aviso "usuário padrão do WSL definido." \
  || aviso "ATENÇÃO: não confirmei o usuário padrão em $CONF."

# ── 6. A senha, na última linha e sozinha ───────────────────────────
printf '%s\n' "$SENHA"
