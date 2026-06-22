ARG CADDY_VERSION=2.11.4
FROM caddy:${CADDY_VERSION}-builder AS builder

# --- DigitalOcean DNS-01 cleanup fix (temporary dependency override) ----------
# The last `--with` line below is NOT another plugin. It's a Go module `replace`
# for a bug in the *low-level* DNS library (libdns/digitalocean) that the
# caddy-dns/digitalocean plugin depends on.
#
# Bug: while cleaning up the temporary ACME `_acme-challenge` TXT record,
# libdns/digitalocean crashes with:
#     strconv.Atoi: parsing "": invalid syntax
# The record handed to the delete path has no ID populated, so converting the
# (empty) ID to an int fails. Cleanup never completes, the stale record lingers,
# DNS propagation times out, and cert renewal fails (then falls back to ZeroSSL).
#
# Fix: libdns/digitalocean PR #15 adds an idFromRecord() helper that looks the
# record ID up via the DigitalOcean API when it isn't already known locally.
#   PR:     https://github.com/libdns/digitalocean/pull/15
#   Issues: https://github.com/libdns/digitalocean/issues/10
#           https://github.com/libdns/digitalocean/issues/14
#
# The PR is still open and is a multi-file refactor (not a one/two-line change),
# so instead of carrying and applying a .patch (awkward: xcaddy compiles from the
# read-only Go module cache, with no checkout to `git apply` against) we redirect
# the transitive libdns dependency to the PR author's fork. The fork keeps the
# same module path (github.com/libdns/digitalocean), so xcaddy's
# `--with <module>=<replacement>@<version>` form works as a clean `replace`.
# Pinned to the PR head commit (ce93eff, PR #15) for reproducible builds.
#
# TO POINT BACK AT UPSTREAM once PR #15 is merged: delete the override line.
# (If caddy-dns/digitalocean is slow to pull in the new libdns release, you can
# instead temporarily bump the override to
# `github.com/libdns/digitalocean@<merged-version>` until it does.)
# NOTE: scripts/check-updates.sh does NOT track this pin, so update/remove it by hand.
# -----------------------------------------------------------------------------
RUN xcaddy build \
  --with github.com/caddy-dns/digitalocean \
  --with github.com/libdns/digitalocean=github.com/lennart6443/digitalocean-libdns@ce93eff57cbc915abb4da609bd8a277f300a12af \
  --with github.com/greenpau/caddy-security \
  --with github.com/lucaslorentz/caddy-docker-proxy/v2 \
  --with github.com/mholt/caddy-l4

FROM caddy:${CADDY_VERSION}-alpine

COPY --link --from=builder /usr/bin/caddy /usr/bin/caddy

CMD ["caddy", "docker-proxy"]
