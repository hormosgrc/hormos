#!/usr/bin/env bash
# Realinha a senha do PostgreSQL com a do .env — e explica por que isso existe.
#
# O SINTOMA: o Keycloak reinicia em laço com
#     FATAL: password authentication failed for user "sgsi"
# enquanto as senhas nos contêineres CONFEREM entre si. Aconteceu numa
# instalação real no Windows/WSL em 28/10/2026, e exigiu que a pessoa
# soubesse Docker, PostgreSQL e Keycloak para destravar um instalador
# anunciado como automático.
#
# A CAUSA: `POSTGRES_PASSWORD` só tem efeito quando o diretório de dados é
# INICIALIZADO. Num diretório que já existe, a imagem do Postgres ignora a
# variável e o papel mantém a senha antiga. E o volume sobrevive a tudo:
# o nome do projeto Compose é fixo (`name: sgsi-appliance-core`), então
# apagar /opt/hormos, reextrair o zip e reinstalar NÃO apaga o banco —
# cria um .env novo, com senha nova, contra um banco que guarda a velha.
# (Esse nome fixo é proposital e já salvou os dados uma vez; o preço é este.)
#
# POR QUE DÁ PARA CONSERTAR SEM SABER A SENHA ANTIGA: o pg_hba do appliance
# confia nas conexões locais e exige scram-sha-256 só pela rede —
#     local, 127.0.0.1, ::1  -> trust
#     host  all              -> scram-sha-256
# Então de DENTRO do contêiner do banco entra-se sem senha, e dali se faz o
# ALTER ROLE. É exatamente o que a pessoa fez à mão; aqui o instalador faz.
set -uo pipefail
cd "$(dirname "$0")/.."

[ -f .env ] || { echo "✖ .env não encontrado."; exit 1; }
USUARIO="$(grep '^POSTGRES_USER=' .env | cut -d= -f2-)"
SENHA="$(grep '^POSTGRES_PASSWORD=' .env | cut -d= -f2-)"
BANCO="$(grep '^POSTGRES_DB=' .env | cut -d= -f2-)"
[ -n "$USUARIO" ] && [ -n "$SENHA" ] || { echo "✖ POSTGRES_USER/PASSWORD vazios no .env."; exit 1; }

docker ps --format '{{.Names}}' | grep -qx sgsi_postgres || {
  echo "✖ sgsi_postgres não está de pé."; exit 1; }

# A PROVA é pela REDE, que é por onde o Keycloak e o portal falam. Testar pelo
# socket local não prova nada: ali é `trust` e qualquer senha passa — foi o que
# fez o diagnóstico à mão parecer contraditório ("as senhas conferem!").
testar_rede() {
  docker exec -e PGPASSWORD="$SENHA" sgsi_postgres \
    psql -h postgres -U "$USUARIO" -d "${BANCO:-postgres}" -tAc 'SELECT 1' >/dev/null 2>&1
}

if testar_rede; then
  echo "✓ A senha do banco confere com a do .env (testado pela rede)."
  exit 0
fi

echo "⚠ O banco NÃO aceita a senha do .env pela rede."
echo "  Causa típica: o volume do Postgres é de uma instalação anterior, e a"
echo "  senha gravada nele é a de então. Realinhando…"

# `psql` sem -h usa o socket local, que é `trust`: entra sem a senha antiga.
if ! docker exec sgsi_postgres psql -U "$USUARIO" -d postgres \
      -c "ALTER ROLE \"$USUARIO\" WITH PASSWORD '$(printf '%s' "$SENHA" | sed "s/'/''/g")'" >/dev/null 2>&1; then
  echo "✖ Não consegui alterar a senha do papel $USUARIO."
  echo "  Rode à mão:  docker exec -it sgsi_postgres psql -U $USUARIO -d postgres"
  echo "  e depois:    ALTER ROLE \"$USUARIO\" WITH PASSWORD '<a senha do .env>';"
  exit 1
fi

if testar_rede; then
  echo "✓ Senha realinhada — a autenticação pela rede voltou a funcionar."
  exit 0
fi
echo "✖ Alterei a senha, mas a autenticação pela rede continua falhando."
echo "  Pode haver outra causa. Mostre esta saída ao suporte."
exit 1
