#!/usr/bin/env bash
# Confere, no fim da instalação, se o Hormos está REALMENTE no ar.
#
# POR QUE EXISTE. Numa instalação real no Windows o instalador terminou com
# "pressione qualquer tecla", a janela fechou — e https://localhost não abria.
# O Keycloak estava reiniciando em laço, e a pessoa só descobriu investigando
# `docker ps -a` por conta própria. Declarar sucesso sem conferir transfere ao
# usuário o trabalho de descobrir que falhou.
#
# "Container Up" NÃO é saúde: o gunicorn sobe mesmo sem banco, e um contêiner
# em `Restarting` aparece na lista como se estivesse vivo até alguém ler o
# STATUS com atenção. Aqui cada peça é cobrada pelo que ela deve ENTREGAR.
set -uo pipefail
cd "$(dirname "$0")/.."

ALVO="${1:-https://localhost}"
falhas=0
aviso=0

ok()    { printf '  ✓ %s\n' "$1"; }
erro()  { printf '  ✖ %s\n' "$1"; falhas=$((falhas+1)); }
nota()  { printf '  ! %s\n' "$1"; aviso=$((aviso+1)); }

echo
echo "── Conferindo se o Hormos está no ar ──────────────────────────────"

# 1. nenhum contêiner reiniciando em laço — o sintoma do Keycloak
reiniciando="$(docker ps --filter 'name=sgsi_' --format '{{.Names}} {{.Status}}' \
               | grep -i restarting || true)"
if [ -n "$reiniciando" ]; then
  erro "contêiner reiniciando em laço:"
  printf '%s\n' "$reiniciando" | sed 's/^/      /'
  printf '      veja o motivo com:  docker logs --tail 40 %s\n' \
         "$(printf '%s' "$reiniciando" | head -1 | cut -d' ' -f1)"
else
  ok "nenhum contêiner reiniciando em laço"
fi

# 2. o banco aceita a senha do .env PELA REDE (não pelo socket, que é trust)
U="$(grep '^POSTGRES_USER=' .env 2>/dev/null | cut -d= -f2-)"
S="$(grep '^POSTGRES_PASSWORD=' .env 2>/dev/null | cut -d= -f2-)"
if [ -n "$U" ] && docker ps --format '{{.Names}}' | grep -qx sgsi_postgres; then
  if docker exec -e PGPASSWORD="$S" sgsi_postgres \
       psql -h postgres -U "$U" -d postgres -tAc 'SELECT 1' >/dev/null 2>&1; then
    ok "o banco aceita a senha do .env (pela rede, que é como o Keycloak fala)"
  else
    erro "o banco RECUSA a senha do .env pela rede"
    echo  "      conserte com:  ./scripts/realinhar-senha-banco.sh"
  fi
fi

# 3. o portal responde pela borda. 302 é sucesso: é o desvio para o login.
cod="$(curl -sk -o /dev/null -w '%{http_code}' --max-time 20 "$ALVO/" 2>/dev/null || echo 000)"
case "$cod" in
  200|302|303) ok "o portal responde em $ALVO (HTTP $cod)" ;;
  000) erro "não consegui falar com $ALVO — o Caddy está de pé?" ;;
  *)   erro "$ALVO respondeu HTTP $cod" ;;
esac

# 4. a tela de login sobe. É ela que faltava na instalação do Windows.
#
# INSISTE antes de desistir, e DESISTE DE VERDADE. O Keycloak leva de 30 a 90
# segundos para abrir, então um 502 logo após o `up` é normal — mas um 502
# PERMANENTE é a falha do relato, e tratá-lo como "aviso" foi o erro que a
# primeira versão deste script cometeu: ela imprimia "✓ está no ar" com o
# login quebrado, que é precisamente o que o instalador fazia antes.
# Checagem que falha para o lado do "pode seguir" é pior que não ter checagem.
printf '  … aguardando a tela de login (até 2 min)'
cod=000
for _i in $(seq 1 24); do
  cod="$(curl -sk -o /dev/null -w '%{http_code}' --max-time 10 "$ALVO/auth/" 2>/dev/null || echo 000)"
  case "$cod" in 200|302|303) break ;; esac
  printf '.'
  sleep 5
done
printf '\r                                                      \r'
case "$cod" in
  200|302|303) ok "a tela de login responde em $ALVO/auth (HTTP $cod)" ;;
  502|503|504)
    erro "a tela de login segue fora do ar depois de 2 min (HTTP $cod)"
    echo  "      o Keycloak não subiu. Veja o motivo:"
    echo  "        docker logs --tail 40 sgsi_keycloak"
    echo  "      se falar em 'password authentication failed', rode:"
    echo  "        ./scripts/realinhar-senha-banco.sh && docker restart sgsi_keycloak"
    ;;
  000) erro "a tela de login não respondeu — o Caddy ou o Keycloak estão fora" ;;
  *)   erro "a tela de login respondeu HTTP $cod" ;;
esac

echo "───────────────────────────────────────────────────────────────────"
if [ "$falhas" -gt 0 ]; then
  echo "✖ O Hormos NÃO está utilizável ainda ($falhas problema(s) acima)."
  echo "  NÃO feche esta janela: as linhas acima dizem o que fazer."
  exit 1
fi
[ "$aviso" -gt 0 ] && echo "✓ No ar, com $aviso ponto(s) de atenção acima." \
                   || echo "✓ O Hormos está no ar e pronto para o primeiro acesso."
exit 0
