#!/usr/bin/env bash
# Redefine a senha de um usuário do Hormos — a saída de quem ficou trancado.
#
# POR QUE EXISTE. Numa instalação real a senha do primeiro acesso se perdeu
# (a janela do instalador fechou antes do login) e a pessoa achou que
# precisaria reinstalar o appliance. Antes do primeiro login, a senha está no
# .env; DEPOIS dele, não está em lugar nenhum — ela passou a ser a do usuário.
#
# E o caminho óbvio NÃO existe aqui: "Esqueci minha senha" exige servidor de
# e-mail, e o appliance não fala com a internet depois de instalado, por
# desenho. Conferido no realm: sem `resetPasswordAllowed`, sem `smtpServer`.
# Prometer esse botão seria mandar a pessoa procurar o que não há.
#
# O que existe é o console do Keycloak. Navegá-lo pede saber o que é realm,
# usuário e credencial — degrau alto para quem só quer entrar no sistema.
# Este script faz pelo console, com uma pergunta.
#
#   ./scripts/redefinir-senha-admin.sh                  (pergunta quem e qual)
#   ./scripts/redefinir-senha-admin.sh fulano@empresa.com
set -uo pipefail
cd "$(dirname "$0")/.."

[ -f .env ] || { echo "✖ .env não encontrado — rode de dentro da pasta do Hormos."; exit 1; }
if docker compose version >/dev/null 2>&1; then DC="docker compose"; else DC="docker-compose"; fi

KC_ADMIN="$(grep '^KEYCLOAK_ADMIN=' .env | cut -d= -f2-)"
KC_PASS="$(grep '^KEYCLOAK_ADMIN_PASSWORD=' .env | cut -d= -f2-)"
REALM="$(grep '^KEYCLOAK_REALM=' .env | cut -d= -f2-)"; REALM="${REALM:-sgsi}"
ALVO="${1:-}"

docker ps --format '{{.Names}}' | grep -qx sgsi_keycloak || {
  echo "✖ O Keycloak não está de pé. Ligue o Hormos primeiro:"
  echo "    $DC start"
  exit 1; }

# O Keycloak serve sob /auth (KC_HTTP_RELATIVE_PATH no compose). Sem o
# prefixo o kcadm recebe 404 e a mensagem sugere "ainda subindo", que manda
# esperar por um problema que não é de tempo. Lido do compose, não fixado:
# se o prefixo mudar, isto acompanha.
KC_URL="http://localhost:8080$(grep -E '^\s*KC_HTTP_RELATIVE_PATH:' docker-compose.yml \
        | head -1 | cut -d: -f2- | tr -d ' \r')"

# `</dev/null` nas chamadas ao kcadm: `docker compose exec -T` herda e CONSOME
# o stdin, então uma consulta no meio do script engolia a senha digitada logo
# depois. Interativamente passa despercebido; por pipe, a senha chegava vazia e
# o script reclamava do tamanho — acusando quem digitou certo.
kc() { $DC exec -T keycloak /opt/keycloak/bin/kcadm.sh "$@" </dev/null; }

if ! kc config credentials --server "$KC_URL" --realm master \
     --user "$KC_ADMIN" --password "$KC_PASS" >/dev/null 2>&1; then
  echo "✖ Não consegui entrar no Keycloak com as credenciais do .env."
  echo "  Ele pode ainda estar subindo — espere um minuto e tente de novo."
  exit 1
fi

if [ -z "$ALVO" ]; then
  echo "Usuários cadastrados:"
  kc get users -r "$REALM" --fields username --format csv --noquotes 2>/dev/null \
    | tr -d '\r' | sed '/^$/d;s/^/   /'
  echo
  printf "Qual deles? "; read -r ALVO
fi
[ -n "$ALVO" ] || { echo "✖ Nenhum usuário informado."; exit 1; }

UID_="$(kc get users -r "$REALM" -q "username=$ALVO" --fields id --format csv --noquotes 2>/dev/null \
        | tr -d '\r' | sed '/^$/d' | head -1)"
[ -n "$UID_" ] || { echo "✖ Usuário '$ALVO' não encontrado no realm $REALM."; exit 1; }

# A senha é LIDA SEM ECO e nunca aparece na tela nem no histórico do shell —
# ao contrário de passá-la como argumento, que ficaria no `history` e em
# `ps` enquanto o comando roda.
printf "Nova senha para %s: " "$ALVO"; stty -echo 2>/dev/null; read -r NOVA; stty echo 2>/dev/null; echo
printf "Repita: "; stty -echo 2>/dev/null; read -r CONF; stty echo 2>/dev/null; echo
[ "$NOVA" = "$CONF" ] || { echo "✖ As senhas não coincidem."; exit 1; }
[ ${#NOVA} -ge 8 ] || { echo "✖ Use ao menos 8 caracteres."; exit 1; }

# --temporary=false: senha definitiva. A de USO ÚNICO é a do instalador; aqui
# a pessoa está justamente recuperando o acesso e não deve ser obrigada a
# trocar de novo na tela seguinte.
if kc set-password -r "$REALM" --userid "$UID_" --new-password "$NOVA" --temporary=false >/dev/null 2>&1; then
  echo "✓ Senha de $ALVO redefinida. Entre em https://localhost"
else
  echo "✖ Não consegui redefinir a senha."
  echo "  A política de senha do realm pode ter recusado — tente uma mais longa."
  exit 1
fi
