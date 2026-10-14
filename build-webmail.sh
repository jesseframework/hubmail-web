#!/usr/bin/env bash
# Build + push the HubMail webmail (grommunio-web) image — same .80 pattern as
# every other HubMail/k3s component: `docker build` on the build host, push GHCR.
# No CI service. Deploy is GitOps: hubmail-container bakes this image in and Argo
# syncs. The Dockerfile sanity-guards the deploy tree so a broken build won't push.
#
# Run on .80 (boca-k3-build-node1), logged in to GHCR as jesseframework.
#   ./build-webmail.sh [channel]     channel = prod (default) | staging
set -euo pipefail
cd "$(dirname "$0")"

CHANNEL="${1:-prod}"
IMG="ghcr.io/jesseframework/hubmail-web"
SHA="$(git rev-parse --short=12 HEAD 2>/dev/null || date +%Y%m%d%H%M)"

echo "=== building ${IMG}:${CHANNEL}-${SHA} (grommunio-web from source) ==="
docker build --provenance=false --sbom=false \
  -t "${IMG}:${CHANNEL}" \
  -t "${IMG}:${CHANNEL}-${SHA}" \
  .

echo "=== pushing ==="
docker push "${IMG}:${CHANNEL}"
docker push "${IMG}:${CHANNEL}-${SHA}"

echo "=== immutable digest (pin in hubmail-container: --build-arg WEBMAIL=…@sha256) ==="
docker inspect --format '{{index .RepoDigests 0}}' "${IMG}:${CHANNEL}"
