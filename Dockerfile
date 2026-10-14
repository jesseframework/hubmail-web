# Build the HubMail webmail (grommunio-web fork) bundle FROM SOURCE.
#
# `make build` produces the deployable PHP+JS tree in ./deploy. The artifact
# stage ships it at /webmail; hubmail-container COPYs it over the RPM-installed
# grommunio-web:
#   COPY --from=ghcr.io/jesseframework/hubmail-web:<tag> /webmail /usr/share/grommunio-web
# so webmail is built from this repo, not only the distro package. PHP plugin
# deps are vendored in-repo, so no PHP/composer is needed at build time.

# ---- build stage --------------------------------------------------------------
# bookworm (Debian 12): current PHP 8.2 in-repo (bullseye's PHP 7.4 is EOL and
# its security pool 404s on point-release churn).
FROM node:20-bookworm AS build
# php-cli: a make step runs `php` to generate deploy/defaults.php. PHP plugin
# deps are vendored in-repo, so no composer is needed.
RUN apt-get update \
 && apt-get install -y --no-install-recommends make gettext brotli gzip php-cli \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /src
COPY . .
# `make build` = `node_modules` (npm install) + `deploy` (server client plugins
# css precompress) → ./deploy.
RUN make build
# Sanity guard: fail the build if the deploy tree didn't come out whole.
RUN set -eux; \
    test -f deploy/index.php; \
    test -d deploy/client; \
    test -f deploy/client/grommunio.js; \
    echo "OK: webmail deploy tree built"

# ---- artifact stage -----------------------------------------------------------
FROM alpine:3.20
COPY --from=build /src/deploy /webmail
CMD ["true"]
