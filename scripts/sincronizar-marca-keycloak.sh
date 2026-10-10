#!/usr/bin/env bash
# Reconcilia a marca exibida na tela de login com o que está no realm-sgsi.json.
#
# POR QUE ISTO EXISTE: o Keycloak sobe com `--import-realm`, que importa o JSON
# APENAS quando o realm ainda não existe. Num appliance já instalado, editar o
# arquivo não muda nada — o displayName vive no banco do Keycloak. Sem este
# passo, todo cliente que instalou antes do renome continuaria vendo a marca
# antiga na tela de login, para sempre e sem nenhum erro visível.
#
# É idempotente: só escreve quando o valor difere. E nunca derruba o instalador
# — se o Keycloak não responder, avisa e sai com 0.
set -uo pipefail
cd "$(dirname "$0")/.."

[ -f .env ] || { echo "  ! .env não encontrado — marca do login não sincronizada."; exit 0; }
set -a; . ./.env; set +a
REALM="${KEYCLOAK_REALM:-sgsi}"
KC="${KC_CONTAINER:-sgsi_keycloak}"
# O servidor fica sob KC_HTTP_RELATIVE_PATH (/auth no compose); sem o prefixo o
# kcadm devolve 404 e a falha parece de credencial.
URL="http://localhost:8080${KC_HTTP_RELATIVE_PATH:-/auth}"

docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$KC" || {
  echo "  ! container $KC não está no ar — marca do login não sincronizada."; exit 0; }

# O que o arquivo diz que deve estar lá.
leia() { python3 -c "import json,sys;print(json.load(open('keycloak/realm-sgsi.json')).get('$1',''))" 2>/dev/null; }
NOME="$(leia displayName)"; HTML="$(leia displayNameHtml)"
[ -n "$NOME" ] || { echo "  ! realm-sgsi.json sem displayName — nada a sincronizar."; exit 0; }

for _i in $(seq 1 30); do
  docker exec "$KC" /opt/keycloak/bin/kcadm.sh config credentials --server "$URL" \
    --realm master --user "$KEYCLOAK_ADMIN" --password "$KEYCLOAK_ADMIN_PASSWORD" \
    >/dev/null 2>&1 && break
  sleep 2
done || true

ATUAL="$(docker exec "$KC" /opt/keycloak/bin/kcadm.sh get "realms/$REALM" --fields displayName 2>/dev/null \
         | python3 -c "import json,sys;print(json.load(sys.stdin).get('displayName',''))" 2>/dev/null)"
[ -n "$ATUAL" ] || { echo "  ! Keycloak não respondeu — marca do login não sincronizada."; exit 0; }

if [ "$ATUAL" = "$NOME" ]; then
  exit 0
fi

docker exec "$KC" /opt/keycloak/bin/kcadm.sh update "realms/$REALM" \
  -s "displayName=$NOME" -s "displayNameHtml=$HTML" >/dev/null 2>&1 \
  && echo "  ✓ Marca da tela de login atualizada: \"$ATUAL\" → \"$NOME\"" \
  || echo "  ! Não consegui atualizar a marca da tela de login (segue \"$ATUAL\")."
exit 0
