#!/usr/bin/env bash
# SUÍTE H — a instalação INTEIRA, do zero até o portal no ar.
#
# POR QUE EXISTE. Os 4 cenários de scripts/testar-instalador.sh cobrem só o
# PREFLIGHT — Docker presente, grupo, permissão de socket. Nada exercitava a
# instalação completa, e foi exatamente ali que uma instalação real no Windows
# falhou (28/10/2026): o instalador terminou dizendo que tinha terminado, com
# o Keycloak reiniciando em laço e o portal inacessível.
#
# O QUE ELA FAZ DE DIFERENTE: roda o ./install.sh DE VERDADE, com as imagens de
# verdade e as portas de verdade. Testar em porta trocada testaria uma
# configuração que não é a do cliente — as redirect URIs do OAuth deixariam de
# bater e o login falharia por motivo falso, que é pior que não testar.
#
# PREÇO: ela PARA o stack de desenvolvimento enquanto roda, porque as portas
# são as mesmas, e o devolve no fim. A desmontagem está num `trap`, então
# interromper com Ctrl-C também restaura.
#
#   ./scripts/testar-instalacao-completa.sh
set -uo pipefail
cd "$(dirname "$0")/.."
ORIGEM="$PWD"
PROJETO_TESTE="hormos-suite-h"
TMP=""
DEV_ESTAVA_DE_PE=0
FALHAS=0

ok()   { printf '  ✓ %s\n' "$1"; }
falha(){ printf '  ✖ %s\n' "$1"; FALHAS=$((FALHAS+1)); }

restaurar() {
  echo
  echo "── Desmontando o ambiente de teste ────────────────────────────"
  if [ -n "$TMP" ] && [ -d "$TMP" ]; then
    (cd "$TMP" && docker compose -p "$PROJETO_TESTE" down -v --remove-orphans >/dev/null 2>&1)
    rm -rf "$TMP"
  fi
  # sobra de execução anterior interrompida
  docker ps -aq --filter "label=com.docker.compose.project=$PROJETO_TESTE" \
    | xargs -r docker rm -f >/dev/null 2>&1
  docker volume ls -q --filter "label=com.docker.compose.project=$PROJETO_TESTE" \
    | xargs -r docker volume rm -f >/dev/null 2>&1
  echo "  ✓ projeto de teste removido (contêineres e volumes)"
  if [ "$DEV_ESTAVA_DE_PE" = "1" ]; then
    (cd "$ORIGEM" && docker compose -f docker-compose.yml -f docker-compose.dev.yml \
       up -d >/dev/null 2>&1) && echo "  ✓ stack de desenvolvimento de volta"
  fi
}
trap restaurar EXIT INT TERM

echo "════════════════════════════════════════════════════════════════"
echo "  SUÍTE H — instalação completa, do zero ao portal no ar"
echo "════════════════════════════════════════════════════════════════"

docker info >/dev/null 2>&1 || { echo "✖ Docker não responde."; exit 1; }

if docker ps --format '{{.Names}}' | grep -q '^sgsi_'; then
  DEV_ESTAVA_DE_PE=1
  # `down` e NÃO `stop`. O compose fixa `container_name:` (sgsi_postgres,
  # sgsi_configurator…), e nome fixo independe do nome do projeto: com `stop`
  # os contêineres continuam existindo e o projeto de teste colide em
  # "container name is already in use". Foi o que reprovou a 2ª execução desta
  # suíte — e sem `-v`, então os VOLUMES do desenvolvimento ficam intactos.
  #
  # E é mais fiel: assim o teste usa os nomes reais, e os scripts de conserto
  # (conferir-saude.sh, realinhar-senha-banco.sh), que procuram sgsi_postgres
  # pelo nome, rodam exatamente como rodariam no cliente.
  echo "▸ Removendo os contêineres de desenvolvimento (os volumes ficam)…"
  docker compose -f docker-compose.yml -f docker-compose.dev.yml down --remove-orphans >/dev/null 2>&1
fi

# ── Cópia descartável do repositório ────────────────────────────────────
TMP="$(mktemp -d)"
tar cf - --exclude .git --exclude caddy/Caddyfile --exclude .env . 2>/dev/null | (cd "$TMP" && tar xf -)
# O nome do projeto é FIXO no compose, e só a flag -p o vence. Na CÓPIA dá
# para trocar a linha, que é mais simples que carregar -p por todo o install.sh.
sed -i.bak "s/^name: .*/name: $PROJETO_TESTE/" "$TMP/docker-compose.yml" && rm -f "$TMP/docker-compose.yml.bak"
grep -q "^name: $PROJETO_TESTE" "$TMP/docker-compose.yml" || { echo "✖ não troquei o nome do projeto"; exit 1; }
echo "▸ Cópia em $TMP (projeto $PROJETO_TESTE)"

# Separa "o produto falhou" de "a rede falhou". Na primeira execução desta
# suíte o pull do Docker Hub caiu no meio e ela acusou o instalador — alarme
# falso, e do tipo que ensina a ignorar o aviso. Quando a causa é rede, o
# resultado é INCONCLUSIVO, não reprovação: o produto não chegou a ser testado.
REDE_FALHOU=0
instalar() {  # instalar <rótulo>
  echo
  echo "▸ $1"
  # `</dev/null`: o instalador chama `sudo ./scripts/confiar-ca.sh`, e sem
  # stdin o sudo falha na hora em vez de ficar esperando senha para sempre.
  # O passo da CA já tolera falha — ele é sobre o aviso do navegador, não
  # sobre o appliance subir, e não é o que esta suíte mede.
  ( cd "$TMP" && ./install.sh local >"$TMP/saida.log" 2>&1 </dev/null )
  local st=$?
  tail -24 "$TMP/saida.log" | sed 's/^/      /'
  # Só as ÚLTIMAS linhas: uma falha de rede no meio do download, da qual o
  # pull se recuperou, deixa a assinatura no log e faria a suíte desculpar um
  # defeito real logo adiante. Foi o que aconteceu — um "failed to copy" do
  # cenário 1 mascarou um conflito de nome de contêiner no cenário 2, e a
  # suíte disse "inconclusiva" para algo que ela tinha achado de verdade.
  REDE_FALHOU=0
  if tail -8 "$TMP/saida.log" | grep -qiE 'failed to copy|httpReadSeeker|TLS handshake timeout|no such host|i/o timeout|connection reset'; then
    REDE_FALHOU=1
  fi
  return $st
}

# ── CENÁRIO 1 · instalação limpa ────────────────────────────────────────
echo
echo "═══ 1 · instalação limpa, do zero ═══"
if instalar "rodando ./install.sh local (primeira vez, pode demorar)"; then
  ok "o instalador terminou com sucesso"
else
  falha "o instalador saiu com erro — veja a saída acima"
fi
# A prova independente: o instalador pode mentir, a porta não.
# Separador `|`, não `:`. Com dois-pontos, `${alvo%%:*}` cortava no PRIMEIRO
# deles e o url virava "https" — o curl recebia isso, devolvia 000, e a suíte
# reprovava uma instalação que tinha funcionado. Erro meu, acusando o produto.
for alvo in "https://localhost/|portal" "https://localhost/auth/|tela de login"; do
  url="${alvo%%|*}"; nome="${alvo#*|}"
  # Sem `|| echo 000`: o curl JÁ imprime 000 quando não conecta, e o fallback
  # concatenava um segundo, produzindo "000000" — número que não existe e que
  # faz quem lê duvidar da medição inteira.
  cod="$(curl -sk -o /dev/null -w '%{http_code}' --max-time 20 "$url" 2>/dev/null)"; cod="${cod:-000}"
  case "$cod" in 200|302|303) ok "$nome responde (HTTP $cod)" ;;
                 *) falha "$nome respondeu HTTP $cod" ;; esac
done

# ── CENÁRIO 2 · reinstalação sobre volume antigo ────────────────────────
# O DEFEITO DO RELATO, reproduzido de ponta a ponta: apagar o .env é o que
# acontece quando a pessoa reextrai o zip numa pasta nova e reinstala. O
# install.sh gera senhas novas, e o volume — que sobrevive de propósito —
# continua com as antigas. Antes do conserto, o Keycloak reiniciava em laço.
echo
echo "═══ 2 · reinstalação sobre o banco de uma instalação anterior ═══"
SENHA_ANTIGA="$(grep '^POSTGRES_PASSWORD=' "$TMP/.env" | cut -d= -f2-)"
rm -f "$TMP/.env"
echo "      (.env apagado — como ao reextrair o zip numa pasta nova)"
if instalar "rodando ./install.sh local de novo"; then
  ok "o instalador terminou com sucesso MESMO com o banco antigo"
else
  falha "o instalador saiu com erro na reinstalação"
fi
SENHA_NOVA="$(grep '^POSTGRES_PASSWORD=' "$TMP/.env" 2>/dev/null | cut -d= -f2-)"
if [ -n "$SENHA_NOVA" ] && [ "$SENHA_NOVA" != "$SENHA_ANTIGA" ]; then
  ok "a senha do .env é NOVA (o cenário foi mesmo reproduzido)"
else
  falha "a senha não mudou — o cenário não foi reproduzido, o teste não vale"
fi
cod="$(curl -sk -o /dev/null -w '%{http_code}' --max-time 25 https://localhost/auth/ 2>/dev/null)"; cod="${cod:-000}"
case "$cod" in 200|302|303) ok "a tela de login responde DEPOIS da reinstalação (HTTP $cod)" ;;
               *) falha "a tela de login respondeu HTTP $cod — era o sintoma do relato" ;; esac

echo
echo "════════════════════════════════════════════════════════════════"
if [ "$FALHAS" -eq 0 ]; then
  echo "✓ SUÍTE H PASSOU — instalação limpa e reinstalação terminam utilizáveis"
  exit 0
fi
if [ "$REDE_FALHOU" = "1" ]; then
  echo "⚠ SUÍTE H INCONCLUSIVA — o download das imagens falhou no meio."
  echo "  O produto não chegou a ser testado; isto NÃO é reprovação dele."
  echo "  Rode de novo com a rede estável."
  exit 2
fi
echo "✖ SUÍTE H: $FALHAS verificação(ões) falharam"
exit 1
