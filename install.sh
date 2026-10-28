#!/usr/bin/env bash
set -euo pipefail

# ════════════════════════════════════════════════════════════════════
# Hormos — instalador para Linux (Ubuntu/Debian/RHEL) e macOS.
# Windows: use o install.bat (duplo clique).
#
# Basta rodar ./install.sh SEM parâmetros: o instalador pergunta se é
# local ou produção (domínio do cliente), se quer o Analista IA e se
# é reinstalação. Parâmetros continuam valendo para automação:
#
# Uso: ./install.sh [local] [--reset] [--ia]
#   --reset  apaga os volumes (banco zerado, recarrega demo + migrações)
#   --ia     sobe também o Analista IA (Ollama) e baixa o modelo
# ════════════════════════════════════════════════════════════════════
MODE="local"; RESET=""; IA=""
PROD_DOMAIN=""; PROD_AUTH=""; PROD_EMAIL=""
for arg in "$@"; do
  case "$arg" in
    --reset) RESET="--reset" ;;
    --ia)    IA="1" ;;
    *)       MODE="$arg" ;;
  esac
done

cd "$(dirname "$0")"

# ── Plataforma ───────────────────────────────────────────────────────
# O WSL é um caso à parte: é Linux para todos os efeitos, mas o navegador
# que vai abrir o portal é o do WINDOWS, e o serviço do Docker depende de o
# systemd estar habilitado em /etc/wsl.conf — que não é o padrão.
# ── O modelo do Analista IA ─────────────────────────────────────────────────
# UM lugar. Trocar o modelo é trocar estas duas linhas (e a imagem publicada,
# porque o padrão também vive no docker-compose.yml e no ia_llm.py).
IA_MODELO="${IA_MODELO:-qwen3:8b}"
IA_RAM_MINIMA="${IA_RAM_MINIMA:-8}"

SO="$(uname -s)"
EH_WSL=""
if [ "$SO" = "Linux" ] && { [ -n "${WSL_DISTRO_NAME:-}" ] \
     || grep -qi microsoft /proc/version 2>/dev/null; }; then
  EH_WSL=1
fi
SUDO=""; [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1 && SUDO="sudo"

# ── Pré-requisitos: instala o Docker quando ausente ──────────────────
# Vem ANTES das perguntas de propósito: não faz sentido pedir domínio e
# e-mail do certificado para só depois descobrir que o Docker não roda.
#
# Linux: automatizável de ponta a ponta (script oficial da Docker).
# macOS: precisa do Docker Desktop; instalamos via Homebrew quando houver,
#        senão orientamos o download (a 1ª abertura é manual, por design da Apple).
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker não encontrado — instalando…"
  if [ "$SO" = "Linux" ]; then
    if [ "$(id -u)" -ne 0 ] && [ -z "$SUDO" ]; then
      echo "✖ Preciso de root (ou sudo) para instalar o Docker."; exit 1
    fi
    curl -fsSL https://get.docker.com | $SUDO sh || {
      echo "✖ Falha ao instalar o Docker. Veja https://docs.docker.com/engine/install/"; exit 1; }
    echo "✓ Docker Engine instalado."
  elif [ "$SO" = "Darwin" ]; then
    if command -v brew >/dev/null 2>&1; then
      echo "  instalando o Docker Desktop via Homebrew…"
      brew install --cask docker || { echo "✖ Falha no brew. Baixe em https://www.docker.com/products/docker-desktop/"; exit 1; }
      open -a Docker 2>/dev/null || true
      echo "  aguardando o Docker Desktop iniciar…"
    else
      echo "✖ Docker não encontrado e o Homebrew não está disponível."
      echo "  Baixe o Docker Desktop: https://www.docker.com/products/docker-desktop/"
      echo "  Abra-o uma vez e rode este instalador novamente."; exit 1
    fi
  else
    echo "✖ Sistema não suportado automaticamente: $SO"; exit 1
  fi
fi

# ── O Docker responde? ───────────────────────────────────────────────
# `docker info` falhar NÃO quer dizer que o daemon está fora do ar. No Linux
# o motivo mais comum é PERMISSÃO: o socket pertence ao grupo `docker`, e um
# usuário fora do grupo recebe "permission denied" com o daemon perfeitamente
# de pé. Tratar os dois casos como um só manda a pessoa consertar o que não
# está quebrado — foi exatamente o que aconteceu num WSL recém-instalado.
docker_pronto(){ docker info >/dev/null 2>&1; }
docker_erro(){ docker info 2>&1 >/dev/null || true; }

if ! docker_pronto && [ "$SO" = "Linux" ]; then
  $SUDO systemctl enable --now docker >/dev/null 2>&1 \
    || $SUDO service docker start >/dev/null 2>&1 || true
fi
# Permissão: entra no grupo e REABRE o instalador já dentro dele.
case "$(docker_erro)" in
  *"permission denied"*|*"permissão negada"*|*"connect: permission"*)
    echo "  O daemon está de pé, mas este usuário não alcança o socket."
    if ! id -nG "$USER" 2>/dev/null | tr ' ' '\n' | grep -qx docker; then
      echo "  Adicionando $USER ao grupo docker…"
      # O erro NÃO é mais engolido. Com `2>/dev/null || true`, um usermod que
      # falhasse — sem sudo, usuário vindo de LDAP/AD, /etc/group somente
      # leitura — deixava o instalador seguir anunciando "já te coloquei no
      # grupo docker" e mandar rodar `newgrp docker`, que falharia pelo mesmo
      # motivo, sem nunca dizer qual era. Checagem que falha para o lado do
      # "pode seguir" é pior que não ter checagem.
      if ! $SUDO usermod -aG docker "$USER"; then
        echo "  ! Falhei ao adicionar $USER ao grupo docker (erro acima)."
        echo "    Sem isso, nem este instalador nem o 'newgrp docker' vão passar."
      fi
    fi
    # Credencial de grupo é fixada no LOGIN: entrar no grupo não muda a sessão
    # em curso. Sem reabrir, o instalador morreria aqui mesmo depois de ter
    # consertado o problema, e a pessoa teria de sair e entrar no terminal.
    # `sg` lê /etc/group direto, então não pede senha para quem já é membro.
    if [ -z "${HORMOS_GRUPO:-}" ] && command -v sg >/dev/null 2>&1 \
       && id -nG "$USER" 2>/dev/null | tr ' ' '\n' | grep -qx docker; then
      # Aspas simples no padrão POSIX, e NÃO printf '%q': o %q do bash emite
      # $'...' para acento, e `sg -c` executa pelo /bin/sh — dash no Ubuntu —,
      # que não entende essa sintaxe. Um caminho como /mnt/c/Users/João, comum
      # justamente no WSL, viraria erro de sintaxe aqui.
      _citar(){ printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"; }
      CMD="$(_citar "$PWD/$(basename "$0")")"
      for _a in "$@"; do CMD="$CMD $(_citar "$_a")"; done
      echo "  Reabrindo o instalador já dentro do grupo docker…"
      exec sg docker -c "HORMOS_GRUPO=1 $CMD"
    elif [ -z "${HORMOS_GRUPO:-}" ]; then
      # Quando a reabertura automática NÃO acontece, dizer por quê. Sem isto o
      # instalador apenas seguia até a mensagem final, que fala em "já te
      # coloquei no grupo" — e a pessoa fica sem saber se o problema foi o
      # grupo, o `sg` ou outra coisa. Aconteceu num WSL em 23/10/2026.
      if ! command -v sg >/dev/null 2>&1; then
        echo "  (não reabri sozinho: o comando 'sg' não existe nesta máquina."
        echo "   Ele vem do pacote 'passwd' — instale com: $SUDO apt install passwd)"
      elif ! id -nG "$USER" 2>/dev/null | tr ' ' '\n' | grep -qx docker; then
        echo "  (não reabri sozinho: '$USER' ainda não aparece no grupo docker)"
      fi
    fi
    ;;
esac

if ! docker_pronto; then
  echo "  aguardando o daemon do Docker…"
  for _i in $(seq 1 30); do docker_pronto && break; sleep 2; done
fi

docker_pronto || {
  ERRO="$(docker_erro)"
  echo "✖ Não consegui falar com o Docker."
  [ -n "$ERRO" ] && echo "  Motivo: $(printf '%s' "$ERRO" | head -1)"
  case "$ERRO" in
    *"permission denied"*|*"permissão negada"*)
      echo "  É PERMISSÃO, não daemon — o daemon está no ar."
      echo "  Já te coloquei no grupo docker. Falta a credencial valer nesta"
      echo "  sessão, e ela é fixada no login. Rode:"
      echo
      # O CAMINHO COMPLETO, e não `./install.sh`. `newgrp` abre um shell NOVO,
      # que começa no $HOME — então o `./install.sh` da instrução anterior não
      # existia ali e a pessoa recebia "No such file or directory" logo depois
      # de seguir a orientação à risca. Aconteceu numa instalação real no WSL.
      echo "    newgrp docker"
      echo "    cd $PWD && ./$(basename "$0")"
      echo
      echo "  (o 'cd' é necessário: o newgrp abre um shell novo, que começa"
      echo "   na sua pasta pessoal, não aqui)"
      ;;
    *)
      if [ -n "$EH_WSL" ]; then
        echo "  No WSL o serviço do Docker só sobe sozinho com o systemd ligado,"
        echo "  e ele NÃO vem ligado por padrão. Habilite uma vez:"
        echo "    sudo sh -c 'printf \"[boot]\\nsystemd=true\\n\" >> /etc/wsl.conf'"
        echo "  depois, no PowerShell do Windows:  wsl --shutdown"
        echo "  reabra o Ubuntu e rode de novo:"
        echo "    cd $PWD && ./$(basename "$0")"
        echo "  (Sem systemd, dá para subir à mão:  sudo service docker start)"
        echo
        echo "  Alternativa: Docker Desktop no Windows com integração WSL ligada"
        echo "  (Settings → Resources → WSL integration) — aí o docker daqui já"
        echo "  fala com o daemon do Windows e nada precisa ser instalado aqui."
      elif [ "$SO" = "Darwin" ]; then
        echo "  macOS: abra o Docker Desktop, espere o ícone ficar estável e repita."
      else
        echo "  Linux: sudo systemctl start docker"
      fi
      ;;
  esac
  exit 1; }

# ── Modo interativo: sem parâmetros e num terminal, o instalador pergunta ──
if [ $# -eq 0 ] && [ -t 0 ]; then
  echo "═══════════════════════════════════════════"
  echo "   Hormos — Instalação guiada"
  echo "═══════════════════════════════════════════"
  echo "Onde o Hormos vai rodar?"
  echo "  [1] Local / testes  (https://localhost)"
  echo "  [2] Produção com o domínio do cliente (HTTPS automático)"
  printf "Escolha [1]: "; read -r R || true
  if [ "${R:-1}" = "2" ]; then
    printf "Domínio do portal (ex.: grc.cliente.com.br): "; read -r PROD_DOMAIN || true
    [ -n "$PROD_DOMAIN" ] || { echo "✖ O domínio é obrigatório no modo produção."; exit 1; }
    printf "Domínio do login/Keycloak [auth.%s]: " "$PROD_DOMAIN"; read -r PROD_AUTH || true
    PROD_AUTH="${PROD_AUTH:-auth.$PROD_DOMAIN}"
    printf "E-mail para o certificado Let's Encrypt [admin@%s]: " "$PROD_DOMAIN"; read -r PROD_EMAIL || true
    PROD_EMAIL="${PROD_EMAIL:-admin@$PROD_DOMAIN}"
    echo "→ Lembrete: DNS de ${PROD_DOMAIN} e ${PROD_AUTH} apontando para este servidor + portas 80/443 abertas."
  fi
  printf "Ativar o Analista IA com LLM local? Baixa ~1GB na 1ª vez [s/N]: "; read -r R || true
  case "${R:-}" in [sSyY]*) IA="1" ;; esac
  printf "Reinstalar do zero (APAGA o banco de dados)? [s/N]: "; read -r R || true
  case "${R:-}" in [sSyY]*) RESET="--reset" ;; esac
  echo
fi

# docker compose (plugin v2) com fallback para docker-compose (legado)
if docker compose version >/dev/null 2>&1; then DC="docker compose";
elif command -v docker-compose >/dev/null 2>&1; then DC="docker-compose";
else
  echo "✖ Docker Compose não encontrado. Instale o plugin: https://docs.docker.com/compose/install/"; exit 1;
fi

command -v python3 >/dev/null 2>&1 || {
  echo "✖ python3 não encontrado (necessário para preparar a configuração)."
  echo "  Ubuntu/Debian: sudo apt-get install -y python3"; exit 1; }
command -v openssl >/dev/null 2>&1 || {
  echo "✖ openssl não encontrado (necessário para gerar as senhas)."
  echo "  Ubuntu/Debian: sudo apt-get install -y openssl"; exit 1; }

# ── Configuração ─────────────────────────────────────────────────────
[ -f .env ] || cp .env.example .env
# O .env guarda a senha do banco, a do console do Keycloak, a chave de sessão
# do Flask e o segredo do gateway — tudo em texto claro. Nascia 644 (legível
# por QUALQUER usuário da máquina), porque nada o restringia: o `cp` herda a
# máscara do sistema. Num servidor com mais de uma conta, isso é leitura livre
# dos segredos do appliance. Achado pela suíte F da bateria.
chmod 600 .env 2>/dev/null || true
chmod +x scripts/*.sh *.sh 2>/dev/null || true

# ── Reconciliar o .env com o .env.example ───────────────────────────────────
# `[ -f .env ] || cp` protege os SEGREDOS, e isso está certo: regerar a senha
# do banco numa instalação em uso destruiria o acesso. Mas ele congela TODO o
# resto para sempre — e aí mora um defeito que custou caro.
#
# O Keycloak passou a atender em /auth na mesma origem do portal, e o
# `.env.example` foi corrigido. Só que quem JÁ tinha instalado continuou com
# `KEYCLOAK_PUBLIC_URL=https://localhost:8443` — uma porta que o compose não
# publica e onde ninguém escuta. O login ficava morto, reinstalar não
# adiantava, e nada na tela dizia por quê. Corrigir o exemplo conserta a
# máquina virgem; não conserta ninguém que já instalou, que é quem reclama.
#
# Agora:
#   · chave que existe no exemplo e falta no .env  → ACRESCENTADA
#   · chave de SEGREDO                             → nunca tocada
#   · chave existente com valor diferente          → AVISADA, não trocada,
#     porque ali pode haver configuração legítima do cliente (domínio próprio)
#   · valor sabidamente MORTO                      → corrigido, dizendo o quê
#
# O último caso é estreito de propósito: só entra aqui o que o produto não
# serve mais em endereço nenhum. Trocar configuração do cliente por conta
# própria seria pior que o defeito.
if [ -f .env.example ]; then
  python3 - <<'PY' || true
import os, re, shutil

# Comparacao por PALAVRA, nao por substring. Com `'KEY' in chave` a variavel
# KEYCLOAK_PUBLIC_URL era classificada como segredo — KEYCLOAK comeca com KEY —
# e ficava de fora da correcao. O teste pegou: o whitelist era corrigido e o
# endereco do Keycloak continuava apontando para a porta morta.
SEGREDO = {'SECRET', 'PASSWORD', 'PASS', 'KEY', 'TOKEN', 'COOKIE'}
def segredo(chave):
    return any(t in SEGREDO for t in chave.upper().split('_'))

# (regex no valor, valor novo, por que mudou)
MORTOS = [
    (r'^https?://localhost:8443/?$', 'https://localhost/auth',
     'o Keycloak atende em /auth na mesma origem; a 8443 nao e publicada'),
    (r'^localhost:8443$', 'localhost',
     'mesma origem do portal'),
    # A escada de modelos por RAM foi REMOVIDA: o produto roda um modelo so.
    # Um .env antigo mantinha o qwen2.5, e o instalador baixava 4,7 GB do
    # modelo que o produto nao usa mais — sem dizer nada.
    (r'^qwen2\.5[:.].*$', 'qwen3:8b',
     'o produto passou a usar um unico modelo, o qwen3:8b'),
    (r'^qwen3:(1\.5|3)b$', 'qwen3:8b',
     'os modelos menores foram removidos do produto'),
]

def ler(p):
    fora = {}
    try:
        with open(p, encoding='utf-8') as fh:
            for l in fh:
                s = l.strip()
                if s and not s.startswith('#') and '=' in s:
                    k, v = s.split('=', 1)
                    fora[k.strip()] = v.strip()
    except OSError:
        pass
    return fora

atual, exemplo = ler('.env'), ler('.env.example')
if not atual:
    raise SystemExit(0)

corrigir, acrescentar, avisar = {}, {}, []

for k, v in atual.items():
    if segredo(k):
        continue
    for padrao, novo, motivo in MORTOS:
        if re.match(padrao, v):
            corrigir[k] = (v, novo, motivo)
            break

for k, v in exemplo.items():
    if k not in atual and not segredo(k) and v and not v.startswith('CHANGE_ME'):
        acrescentar[k] = v
    elif k in atual and not segredo(k) and k not in corrigir and atual[k] != v:
        avisar.append((k, atual[k], v))

if not (corrigir or acrescentar):
    raise SystemExit(0)

shutil.copy2('.env', '.env.bak')
with open('.env', encoding='utf-8') as fh:
    linhas = fh.readlines()
saida = []
for l in linhas:
    s = l.strip()
    if s and not s.startswith('#') and '=' in s:
        k = s.split('=', 1)[0].strip()
        if k in corrigir:
            _, novo, _m = corrigir[k]
            saida.append('%s=%s\n' % (k, novo))
            continue
    saida.append(l)
if acrescentar:
    saida.append('\n# Acrescentadas pelo instalador (faltavam neste .env)\n')
    for k, v in acrescentar.items():
        saida.append('%s=%s\n' % (k, v))
with open('.env', 'w', encoding='utf-8') as fh:
    fh.writelines(saida)
os.chmod('.env', 0o600)

print('Configuracao: .env reconciliado (copia anterior em .env.bak)')
for k, (velho, novo, motivo) in corrigir.items():
    print('  corrigido  %s' % k)
    print('             de  %s' % velho)
    print('             para %s   (%s)' % (novo, motivo))
for k, v in acrescentar.items():
    print('  acrescentado %s=%s' % (k, v))
for k, a, b in avisar[:5]:
    print('  (diferente do padrao, MANTIDO: %s=%s / exemplo: %s)' % (k, a, b))
PY
fi

if grep -q CHANGE_ME .env; then ./generate-secrets.sh; fi
./scripts/render-keycloak-realm.sh
# preserva o Caddyfile de produção (domínio próprio via ./configurar-dominio.sh)
# aceita o marcador antigo (TRACADO-): instalação anterior ao renome da marca
if [ -f caddy/Caddyfile ] && grep -qE "(HORMOS|TRACADO)-PRODUCAO" caddy/Caddyfile; then
  echo "Caddyfile de produção detectado — mantido (para voltar ao localhost, apague caddy/Caddyfile)."
else
  cp caddy/Caddyfile.local caddy/Caddyfile
fi

# Profile da IA (opcional)
if [ "$IA" = "1" ]; then export COMPOSE_PROFILES=ia; fi

# ── RAM do Analista IA: ANTES do pull ───────────────────────────────────────
# Esta checagem vivia depois da subida, junto do download do modelo. O efeito
# era cruel em conexão lenta: o `$DC pull` já tinha baixado a imagem do Ollama
# (3,4 GB, quase toda de bibliotecas de GPU) quando o instalador descobria que
# a máquina não tem os 8 GB e abortava. A pessoa pagava o download inteiro para
# receber um "✖". Medir memória não depende de nada estar no ar — então mede-se
# primeiro, e só se couber é que se gasta a banda.
if [ "$IA" = "1" ]; then
  MEM_BYTES="$(docker info --format '{{.MemTotal}}' 2>/dev/null || echo 0)"
  MEM_GB=$(( MEM_BYTES / 1073741824 ))
  if [ "$MEM_GB" -lt "$IA_RAM_MINIMA" ]; then
    echo "✖ O Analista IA precisa de ${IA_RAM_MINIMA} GB de RAM disponíveis ao Docker."
    echo "  Este Docker tem ${MEM_GB} GB."
    echo
    echo "  Não há modelo menor: o Hormos usa UM modelo para tudo, e um modelo"
    echo "  pequeno devolveria parecer de qualidade inferior com a sua marca."
    echo
    if [ -n "$EH_WSL" ]; then
      # No WSL quem impõe o teto é a VM da distribuição, não o Docker: o
      # "Settings → Resources" que a mensagem genérica mandava procurar é do
      # Docker Desktop e NÃO EXISTE quando o Engine roda dentro do Ubuntu.
      # Mandar procurar uma tela inexistente é pior que não orientar.
      echo "  No WSL quem limita a memória é a VM do WSL, não o Docker — não há"
      echo "  'Settings → Resources' aqui. No Windows, crie ou edite o arquivo"
      echo "      C:\\Users\\<seu-usuario>\\.wslconfig"
      echo "  com o conteúdo:"
      echo
      echo "      [wsl2]"
      echo "      memory=12GB"
      echo
      echo "  depois, no PowerShell:  wsl --shutdown"
      echo "  reabra o Ubuntu e rode ./install.sh de novo,"
    else
      echo "  Aumente a memória do Docker (Settings → Resources) e rode de novo,"
    fi
    echo "  ou instale sem o Analista IA — o motor semântico embarcado continua"
    echo "  funcionando e não depende de LLM."
    exit 1
  fi
fi

# ── Subida ───────────────────────────────────────────────────────────
if [ "$RESET" = "--reset" ]; then $DC down -v || true; fi
$DC pull
docker run --rm -v "$PWD/caddy/Caddyfile:/etc/caddy/Caddyfile:ro" caddy:2-alpine caddy validate --config /etc/caddy/Caddyfile
# Sem --build: o cliente recebe a IMAGEM publicada e assinada, não o código.
# Para desenvolver a partir do fonte, use docker-compose.dev.yml.
$DC up -d
sleep 15

# O --import-realm só vale para realm novo: num appliance já instalado, a marca
# da tela de login vive no banco do Keycloak e não acompanha o arquivo.
./scripts/sincronizar-marca-keycloak.sh || true

# ── Analista IA: UM modelo, uma régua ───────────────────────────────────────
# Havia três tiers por RAM (7b / 3b / 1.5b). A escada foi REMOVIDA, e não por
# simplificação estética: o produto inteiro roda num único OLLAMA_MODEL — não
# existe tarefa leve despachada para modelo menor. Então o tier pequeno não era
# "menos IA", era o MESMO parecer, pior. E pior de forma composta: contexto_max()
# mandava 320 caracteres ao 1.5b contra 900 ao 7b/8b, ou seja, modelo mais fraco
# recebendo menos informação.
#
# O Hormos analisa grafo de SGSI e assina um parecer que vai a auditor. Entregar
# isso num 1.5b não é "funcionar com pouca memória": é entregar texto ruim com
# a nossa marca. Melhor dizer que exige 8 GB e não rodar onde não cabe.
if [ "$IA" = "1" ]; then
  # A checagem de RAM já rodou antes do `$DC pull` — ver o bloco "RAM do
  # Analista IA: ANTES do pull". Aqui só se baixa modelo.
  # Modelo de VISÃO desativado por padrão: em appliance vendido, o vl:3b/7b soma
  # ~3–5GB de RAM ao lado do LLM e entrega descrição genérica de pouco valor.
  # Fotos sem texto (catraca, sala-cofre) são correlacionadas pela DESCRIÇÃO que
  # o usuário informa — determinístico, instantâneo, 0 GB extra.
  if ! grep -q '^OLLAMA_MODEL=' .env; then
    echo "Analista IA: ${MEM_GB} GB de RAM no Docker → modelo ${IA_MODELO}"
    ./scripts/set-env.sh OLLAMA_MODEL "$IA_MODELO"
    $DC up -d sgsi-portal >/dev/null 2>&1 || true
  fi
  MODEL="$(grep '^OLLAMA_MODEL=' .env 2>/dev/null | cut -d= -f2- || true)"; MODEL="${MODEL:-$IA_MODELO}"
  EMBED="$(grep '^EMBED_MODEL=' .env 2>/dev/null | cut -d= -f2- || true)";  EMBED="${EMBED:-nomic-embed-text}"
  # Não há VISION_MODEL: o modelo de visão foi testado e REMOVIDO do produto
  # (somava 3–5 GB e entregava descrição genérica). A variável continuava sendo
  # lida aqui e repassada pelo compose, mas nenhum código do portal a consome —
  # baixaria gigabytes para nada, e com MAX_LOADED_MODELS=1 brigaria com o LLM.
  # Evidência em imagem é correlacionada pela descrição que o usuário informa.
  for M in "$MODEL" "$EMBED"; do
    [ -n "$M" ] || continue
    echo "Analista IA: verificando modelo ${M}..."
    if $DC exec -T ollama ollama list 2>/dev/null | grep -q "${M%%:*}"; then
      echo "Analista IA: modelo ${M} já disponível. ✓"
    else
      echo "Analista IA: baixando ${M} (só na primeira vez)..."
      $DC exec -T ollama ollama pull "$M"
    fi
  done
fi

# Produção: aplica o domínio do cliente (Caddyfile HTTPS, .env, kcadm)
if [ -n "$PROD_DOMAIN" ]; then
  GRC_INSTALL=1 ./configurar-dominio.sh "$PROD_DOMAIN" "$PROD_AUTH" "$PROD_EMAIL"
fi

$DC ps
if [ -n "$PROD_DOMAIN" ]; then
  echo "Portal:   https://${PROD_DOMAIN}"
  echo "Keycloak: https://${PROD_AUTH}"
else
  echo "Portal:   https://localhost   (http://localhost e :8080 redirecionam pra cá)"
  echo "Login:    https://localhost/auth  (mesma origem — um só certificado)"
  # ── Confiança na CA interna: sem isto o navegador exibe aviso e, com HSTS,
  #    o aviso vira intransponível em Chrome/Safari/Edge. É o passo que torna
  #    o HTTPS local utilizável em QUALQUER navegador, sem o usuário digitar nada.
  echo
  if [ "$(id -u)" -eq 0 ]; then
    ./scripts/confiar-ca.sh || true
  elif command -v sudo >/dev/null 2>&1; then
    echo "Para o HTTPS abrir SEM aviso em todos os navegadores, preciso confiar"
    echo "na CA interna do appliance (pede a sua senha de administrador):"
    sudo ./scripts/confiar-ca.sh || {
      echo "  ! CA não instalada — o navegador vai exibir aviso de certificado."
      echo "    Você pode rodar depois: sudo ./scripts/confiar-ca.sh"; }
  else
    echo "→ Rode depois, para tirar o aviso de certificado: sudo ./scripts/confiar-ca.sh"
  fi
  echo
  echo "  Domínio próprio do cliente (certificado público): área admin →"
  echo "  Domínio & Certificado, ou ./configurar-dominio.sh grc.cliente.com.br"
fi
# A senha aparece aqui porque é GERADA nesta instalação e ninguém mais a
# conhece — não mostrá-la deixaria o appliance inacessível. O que a protege não
# é escondê-la: é ela ser de USO ÚNICO (o realm a marca como "temporary"), e
# por isso o aviso abaixo não é enfeite. Sem ele, a tela de troca de senha no
# primeiro acesso parece erro, e a pessoa liga para o suporte.
echo "Usuário: $(grep '^MASTER_EMAIL=' .env|cut -d= -f2-)"
echo "Senha:   $(grep '^MASTER_PASSWORD=' .env|cut -d= -f2-)   (de uso único)"
echo
echo "  ↑ Esta senha vale para UM acesso: o sistema vai pedir que você defina"
echo "    a sua no primeiro login. Até lá, ela está visível neste terminal —"
echo "    feche-o depois, e não cole esta saída em e-mail nem em chamado."
if [ "$IA" = "1" ]; then
  echo "Analista IA: ATIVO (LLM local ${MODEL:-$IA_MODELO})"
else
  echo "Analista IA: motor semântico embarcado ativo. Para o LLM local: rode ./install.sh de novo e responda 's'."
fi

# ── Como operar depois ────────────────────────────────────────────────────
# Quem homologa num desktop ou notebook pode nunca ter usado Docker, e a
# primeira pergunta que faz ao suporte é "como eu paro isso?". A resposta tem
# de estar AQUI, na tela em que a pessoa já está olhando, e não só no README.
#
# O `-p` dispensa o `cd`: o Compose descobre o projeto pelos rótulos dos
# contêineres. É de propósito — instrução que depende de estar na pasta certa
# foi exatamente o defeito que o instalador já teve com o `newgrp`.
echo
echo "─────────────────────────────────────────────────────────────────"
echo " COMO PARAR E LIGAR O HORMOS   (funciona de qualquer pasta)"
echo
echo "   docker compose -p sgsi-appliance-core ps      # está no ar?"
echo "   docker compose -p sgsi-appliance-core stop    # parar tudo"
echo "   docker compose -p sgsi-appliance-core start   # ligar de volta"
echo
echo " Parar NÃO apaga nada — os dados ficam em volumes do Docker, e o"
echo " sistema volta como estava. Uma vez parado, fica parado até você"
echo " mandar ligar, mesmo depois de reiniciar a máquina."
echo
echo " Guia completo: https://hormosgrc.github.io/instalacao.html"
echo "─────────────────────────────────────────────────────────────────"
