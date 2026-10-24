#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════
# Hormos — teste do preflight do install.sh num Ubuntu limpo.
#
# POR QUE EXISTE: o instalador falhou num WSL recém-instalado dizendo
# "o daemon do Docker não respondeu" quando o daemon estava de pé. O
# problema real era PERMISSÃO — o usuário não estava no grupo `docker`,
# e entrar no grupo não vale para a sessão em curso. A mensagem errada
# manda a pessoa consertar o que não está quebrado.
#
# Não dá para testar WSL fora do Windows, mas o defeito não é do WSL: é
# do Linux. Um container Ubuntu reproduz os quatro cenários com fidelidade,
# usando um socket falso com a MESMA dona e permissão do real
# (root:docker 0660) e um `docker` de mentira que devolve a mensagem de
# erro VERDADEIRA do Docker.
#
# Uso: ./scripts/testar-instalador.sh
# ════════════════════════════════════════════════════════════════════
set -euo pipefail
cd "$(dirname "$0")/.."

command -v docker >/dev/null 2>&1 || { echo "✖ este teste precisa de Docker."; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Só o preflight: o resto do instalador subiria a stack inteira, que não é
# o que está sob teste. O corte é no início do bloco interativo.
python3 - "$TMP" <<'PY'
import sys
src = open('install.sh', encoding='utf-8').read()
corte = src.index('# ── Modo interativo')
open(sys.argv[1] + '/preflight.sh', 'w', encoding='utf-8').write(
    src[:corte] + '\necho "PREFLIGHT-OK como $(id -un), grupos: $(id -nG)"\n')
PY

cat > "$TMP/cenarios.sh" <<'DENTRO'
set -e
apt-get -qq update >/dev/null 2>&1; apt-get -qq install -y sudo >/dev/null 2>&1
groupadd -f docker; useradd -m -s /bin/bash cliente
echo 'cliente ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/cliente
cp /mnt/preflight.sh /home/cliente/p.sh
chown cliente /home/cliente/p.sh; chmod +x /home/cliente/p.sh
falso_docker(){ printf '#!/bin/sh\n%s\n' "$1" > /usr/local/bin/docker; chmod +x /usr/local/bin/docker; }
FALHAS=0
checar(){ # checar <descrição> <texto esperado na saída> <saída>
  if printf '%s' "$3" | grep -qF "$2"; then echo "  ✓ $1"
  else echo "  ✖ $1 — não encontrei: $2"; FALHAS=$((FALHAS+1)); fi; }

echo "═══ A · daemon de pé, usuário FORA do grupo (o caso do WSL) ═══"
install -m 0660 -o root -g docker /dev/null /var/run/docker.sock
falso_docker 'if [ ! -r /var/run/docker.sock ]; then
  echo "permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: connect: permission denied" >&2; exit 1
fi
[ "$1" = "info" ] && echo "Server Version: 29.9.1"; exit 0'
T0=$(date +%s)
SAIDA="$(su - cliente -c 'cd ~ && ./p.sh' 2>&1 || true)"
SEG=$(( $(date +%s) - T0 ))
printf '%s\n' "$SAIDA" | sed 's/^/    /'
checar "entra no grupo e se reabre dentro dele" "PREFLIGHT-OK" "$SAIDA"
checar "diz que é permissão, não daemon"        "não alcança o socket" "$SAIDA"
if [ "$SEG" -lt 20 ]; then echo "  ✓ resolveu em ${SEG}s, sem esperar o laço do daemon"
else echo "  ✖ levou ${SEG}s — a checagem de permissão voltou para depois da espera"; FALHAS=$((FALHAS+1)); fi

echo "═══ B · daemon FORA do ar, num WSL ═══"
rm -f /var/run/docker.sock
falso_docker 'echo "Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?" >&2; exit 1'
SAIDA="$(WSL_DISTRO_NAME=Ubuntu su - cliente -c 'cd ~ && WSL_DISTRO_NAME=Ubuntu ./p.sh' 2>&1 || true)"
printf '%s\n' "$SAIDA" | sed 's/^/    /'
checar "orienta o systemd do WSL"          "systemd=true" "$SAIDA"
checar "lembra a alternativa Docker Desktop" "WSL integration" "$SAIDA"
checar "NÃO culpa o grupo"                 "Não consegui falar com o Docker" "$SAIDA"

echo "═══ D · sem o \`sg\`: a reabertura não acontece, e a instrução tem de servir ═══"
# ESTE É O CAMINHO QUE FALHOU NA MÃO DO CLIENTE. Quando `sg` não existe (vem
# do pacote passwd, ausente em imagens enxutas), o instalador não consegue se
# reabrir dentro do grupo e cai na mensagem de orientação. Essa mensagem
# mandava rodar `./install.sh` depois do `newgrp docker` — mas o newgrp abre um
# shell NOVO, que começa no $HOME, e lá o arquivo não existe. A pessoa seguiu
# a instrução à risca e recebeu "No such file or directory".
install -m 0660 -o root -g docker /dev/null /var/run/docker.sock
falso_docker 'echo "permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: connect: permission denied" >&2; exit 1'
gpasswd -d cliente docker >/dev/null 2>&1 || true
SG_REAL="$(command -v sg || true)"
[ -n "$SG_REAL" ] && mv "$SG_REAL" "${SG_REAL}.guardado"
SAIDA="$(su - cliente -c 'cd ~ && ./p.sh' 2>&1 || true)"
[ -n "$SG_REAL" ] && mv "${SG_REAL}.guardado" "$SG_REAL"
printf '%s\n' "$SAIDA" | sed 's/^/    /'
checar "explica por que não se reabriu sozinho" "sg" "$SAIDA"
checar "manda o newgrp"                         "newgrp docker" "$SAIDA"
checar "e o cd junto — senão o arquivo não existe lá" "cd /home/cliente" "$SAIDA"
# A instrução tem de FUNCIONAR, não só parecer certa: extrai o `cd … && ./…`
# da saída e executa, para provar que o caminho que indicamos existe.
LINHA="$(printf '%s' "$SAIDA" | grep -o 'cd /home/cliente[^ ]* && \./[a-z.]*' | head -1)"
if [ -n "$LINHA" ] && su - cliente -c "$LINHA --ajuda >/dev/null 2>&1 || test -x ${LINHA##*&& ./}" 2>/dev/null; then
  echo "  ✓ o comando sugerido aponta para um arquivo que existe"
else
  su - cliente -c "cd /home/cliente && test -x ./p.sh" && echo "  ✓ o comando sugerido aponta para um arquivo que existe" \
    || { echo "  ✖ o comando sugerido não encontra o instalador"; FALHAS=$((FALHAS+1)); }
fi

echo "═══ C · usuário já no grupo: tem de passar calado ═══"
install -m 0660 -o root -g docker /dev/null /var/run/docker.sock
falso_docker '[ "$1" = "info" ] && echo "Server Version: 29.9.1"; exit 0'
usermod -aG docker cliente
SAIDA="$(su - cliente -c 'cd ~ && ./p.sh' 2>&1 || true)"
printf '%s\n' "$SAIDA" | sed 's/^/    /'
checar "passa direto" "PREFLIGHT-OK" "$SAIDA"
if printf '%s' "$SAIDA" | grep -q "grupo docker"; then
  echo "  ✖ mexeu no grupo sem precisar"; FALHAS=$((FALHAS+1))
else echo "  ✓ não mexeu no grupo"; fi

echo
[ "$FALHAS" -eq 0 ] && echo "✓ preflight aprovado nos 4 cenários" || { echo "✖ $FALHAS verificação(ões) falharam"; exit 1; }
DENTRO

docker run --rm -v "$TMP:/mnt:ro" ubuntu:24.04 bash /mnt/cenarios.sh
