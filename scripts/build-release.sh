#!/usr/bin/env bash
# Build e assinatura da imagem do Hormos.
#
# Roda na infraestrutura do FORNECEDOR. Produz uma imagem com procedência
# gravada (versão, commit, data, id de build) e, se o cosign estiver
# disponível, a assinatura que permite ao cliente verificar que a imagem veio
# de você e não foi adulterada no caminho.
set -euo pipefail
cd "$(dirname "$0")/.."

PORTAL_SRC="${PORTAL_SRC:-../hormos-portal}"
if [ ! -f "${PORTAL_SRC}/Dockerfile" ]; then
  echo "✗ Código do portal não encontrado em ${PORTAL_SRC}."
  echo "  Clone o repositório privado ao lado deste, ou defina PORTAL_SRC."
  exit 1
fi
# a versão e o commit descrevem o PORTAL, não o appliance — é o portal que vira imagem
VERSION="${VERSION:-$(git -C "${PORTAL_SRC}" describe --tags --always 2>/dev/null || echo 2.1.0)}"
GIT_SHA="$(git -C "${PORTAL_SRC}" rev-parse HEAD 2>/dev/null || echo desconhecido)"
BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
BUILD_ID="$(date -u +%Y%m%d%H%M%S)-${GIT_SHA:0:7}"
REGISTRY="${REGISTRY:-ghcr.io/hormosgrc}"
IMAGEM="${REGISTRY}/hormos-portal"

sujo=""
if git -C "${PORTAL_SRC}" status --porcelain 2>/dev/null | grep -q .; then
  sujo=" (árvore de trabalho SUJA)"
  echo "⚠  Há alterações não commitadas. Uma imagem gerada de árvore suja não"
  echo "   tem procedência verificável — o commit gravado não descreve o que foi."
  read -rp "   Continuar mesmo assim? [s/N] " r; [ "$r" = "s" ] || exit 1
fi

echo "▸ Versão   : ${VERSION}${sujo}"
echo "▸ Commit   : ${GIT_SHA}"
echo "▸ Build id : ${BUILD_ID}"

# ── Plataformas ─────────────────────────────────────────────────────────────
# `docker build` constrói só para a arquitetura de QUEM constrói. Como este
# projeto é desenvolvido num Mac Apple Silicon, a imagem publicada saía
# linux/arm64 — e um cliente em x86, que é a maioria dos servidores, não
# conseguia rodar. O erro não aparece para quem publica: aparece na máquina do
# cliente, no `docker pull`, e parece defeito do cliente.
#
# Com buildx e manifesto multiplataforma, o `docker pull` escolhe sozinho. A
# travessia amd64 num host arm64 usa emulação e é LENTA — é o preço, e é menor
# que o de distribuir uma imagem que metade dos clientes não roda.
PLATAFORMAS="${PLATAFORMAS:-linux/amd64,linux/arm64}"
echo "▸ Plataformas: ${PLATAFORMAS}"

# Manifesto multiplataforma NÃO cabe no daemon local: ou se publica direto, ou
# se constrói uma arquitetura só. Por isso o fluxo diverge aqui.
if [ "${PUBLICAR:-nao}" = "sim" ]; then
  docker buildx build \
    --platform "${PLATAFORMAS}" \
    --build-arg "VERSION=${VERSION}" \
    --build-arg "GIT_SHA=${GIT_SHA}" \
    --build-arg "BUILD_DATE=${BUILD_DATE}" \
    --build-arg "BUILD_ID=${BUILD_ID}" \
    -t "${IMAGEM}:${VERSION}" -t "${IMAGEM}:latest" \
    --push \
    "${PORTAL_SRC:-../hormos-portal}"
  echo "▸ Publicada em ${IMAGEM}:${VERSION} (e :latest)"
  docker buildx imagetools inspect "${IMAGEM}:${VERSION}" \
    --format '{{range .Manifest.Manifests}}   {{.Platform.OS}}/{{.Platform.Architecture}}{{println}}{{end}}' \
    2>/dev/null | grep -v unknown || true
  DIGEST="${IMAGEM}@$(docker buildx imagetools inspect "${IMAGEM}:${VERSION}" \
    --format '{{.Manifest.Digest}}')"
  echo "▸ Publicada: ${DIGEST}"

  if command -v cosign >/dev/null 2>&1; then
    cosign sign --yes "${DIGEST}"
    echo "▸ Assinada com cosign."
    echo "  O cliente verifica SEM instalar nada — ele já tem Docker:"
    echo "    docker run --rm ghcr.io/sigstore/cosign/cosign:latest verify \\"
    echo "      ${DIGEST} \\"
    # A identidade PRECISA ser fixada: com --certificate-identity-regexp '.*'
    # o cliente só prova que a imagem foi assinada por ALGUÉM, não por nós —
    # quem publicasse a própria imagem, assinada com a própria conta, passaria
    # no teste. Assinatura que não prende identidade é decoração.
    echo "      --certificate-identity '${ASSINANTE:-sgduarte7@gmail.com}' \\"
    echo "      --certificate-oidc-issuer '${EMISSOR:-https://accounts.google.com}'"
  else
    echo "⚠  cosign não encontrado — imagem publicada SEM assinatura."
    echo "   Assine com o próprio Docker, sem instalar nada:"
    echo "     docker run --rm -it ghcr.io/sigstore/cosign/cosign:latest sign ${DIGEST}"
    echo "   Sem assinatura, o cliente não tem como provar que a imagem é sua."
  fi
else
  # Ensaio: UMA arquitetura, a do host, carregada no daemon local para poder
  # inspecionar. Multiplataforma sem publicar não existe — o manifesto não cabe
  # no daemon — e construir as duas para jogar fora seria desperdiçar a
  # emulação.
  docker buildx build \
    --build-arg "VERSION=${VERSION}" \
    --build-arg "GIT_SHA=${GIT_SHA}" \
    --build-arg "BUILD_DATE=${BUILD_DATE}" \
    --build-arg "BUILD_ID=${BUILD_ID}" \
    -t "${IMAGEM}:${VERSION}" -t "${IMAGEM}:latest" \
    --load \
    "${PORTAL_SRC:-../hormos-portal}"
  echo "▸ Imagem construída (só ${PLATAFORMAS%%,*} — ensaio local):"
  docker image inspect "${IMAGEM}:${VERSION}" \
    --format '   {{index .Config.Labels "org.opencontainers.image.version"}} · commit {{index .Config.Labels "org.opencontainers.image.revision"}} · build {{index .Config.Labels "br.com.hormosgrc.build_id"}}'
  echo "▸ Não publicada (defina PUBLICAR=sim para enviar as duas arquiteturas e assinar)."
fi
