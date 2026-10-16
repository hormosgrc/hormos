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
      $SUDO usermod -aG docker "$USER" 2>/dev/null || true
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
      echo "  Já te coloquei no grupo docker. Agora é só valer na sessão:"
      echo "    saia e entre de novo no terminal, ou rode:  newgrp docker"
      echo "  e repita:  ./install.sh"
      ;;
    *)
      if [ -n "$EH_WSL" ]; then
        echo "  No WSL o serviço do Docker só sobe sozinho com o systemd ligado,"
        echo "  e ele NÃO vem ligado por padrão. Habilite uma vez:"
        echo "    sudo sh -c 'printf \"[boot]\\nsystemd=true\\n\" >> /etc/wsl.conf'"
        echo "  depois, no PowerShell do Windows:  wsl --shutdown"
        echo "  reabra o Ubuntu e rode ./install.sh de novo."
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
chmod +x scripts/*.sh *.sh 2>/dev/null || true
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
  MEM_BYTES="$(docker info --format '{{.MemTotal}}' 2>/dev/null || echo 0)"
  MEM_GB=$(( MEM_BYTES / 1073741824 ))
  if [ "$MEM_GB" -lt "$IA_RAM_MINIMA" ]; then
    echo "✖ O Analista IA precisa de ${IA_RAM_MINIMA} GB de RAM disponíveis ao Docker."
    echo "  Este Docker tem ${MEM_GB} GB."
    echo
    echo "  Não há modelo menor: o Hormos usa UM modelo para tudo, e um modelo"
    echo "  pequeno devolveria parecer de qualidade inferior com a sua marca."
    echo "  Aumente a memória do Docker (Settings → Resources) e rode de novo,"
    echo "  ou instale sem o Analista IA — o motor semântico embarcado continua"
    echo "  funcionando e não depende de LLM."
    exit 1
  fi
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
  VISM="$(grep '^VISION_MODEL=' .env 2>/dev/null | cut -d= -f2- || true)"
  for M in "$MODEL" "$EMBED" $VISM; do
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
echo "Usuário: $(grep '^MASTER_EMAIL=' .env|cut -d= -f2-)"
echo "Senha:   $(grep '^MASTER_PASSWORD=' .env|cut -d= -f2-)"
if [ "$IA" = "1" ]; then
  echo "Analista IA: ATIVO (LLM local ${MODEL:-$IA_MODELO})"
else
  echo "Analista IA: motor semântico embarcado ativo. Para o LLM local: rode ./install.sh de novo e responda 's'."
fi
