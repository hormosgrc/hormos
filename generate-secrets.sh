#!/usr/bin/env bash
set -euo pipefail
[ -f .env ] || cp .env.example .env
for key in POSTGRES_PASSWORD KEYCLOAK_ADMIN_PASSWORD KEYCLOAK_CLIENT_SECRET FLASK_SECRET_KEY PORTAL_SHARED_SECRET; do ./scripts/set-env.sh "$key" "$(openssl rand -hex 32)"; done
# A senha do super admin é de USO ÚNICO: o realm a marca como "temporary",
# então o Keycloak exige a troca no primeiro acesso. Isso é o que neutraliza o
# caminho real de vazamento — ela é IMPRESSA no fim da instalação (precisa ser,
# porque é gerada aqui e ninguém mais a conhece) e fica no scrollback do
# terminal, em qualquer `./install.sh | tee install.log`, e em transcrição de
# instalação colada num suporte. Sendo de uso único, nada disso serve depois.
#
# 24 caracteres hexadecimais = 96 bits. Eram 12 (48 bits); custa o mesmo e a
# senha vive por um login só, então não há razão para economizar entropia.
if grep -q '^MASTER_PASSWORD=CHANGE_ME' .env; then ./scripts/set-env.sh MASTER_PASSWORD "Sgsi@$(openssl rand -hex 12)!"; fi
if grep -q '^OAUTH2_PROXY_COOKIE_SECRET=CHANGE_ME' .env; then ./scripts/set-env.sh OAUTH2_PROXY_COOKIE_SECRET "$(openssl rand -base64 32 | tr -- '+/' '-_' | tr -d '=')"; fi

# Quem acabou de ESCREVER segredos no arquivo é quem tem de trancá-lo.
# Aqui e no install.sh: este script também roda sozinho, fora dele.
chmod 600 .env 2>/dev/null || true
