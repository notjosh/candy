ARG CADDY_VERSION=2.8.0
FROM caddy:${CADDY_VERSION}-builder AS builder

RUN xcaddy build \
  --with github.com/caddy-dns/digitalocean \
  --with github.com/greenpau/caddy-security \
  --with github.com/lucaslorentz/caddy-docker-proxy/v2 \
  --with github.com/mholt/caddy-l4

FROM caddy:${CADDY_VERSION}-alpine

COPY --link --from=builder /usr/bin/caddy /usr/bin/caddy

CMD ["caddy", "docker-proxy"]
