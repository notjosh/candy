# Candy

Caddy, but with a touch of sweetness.

(mostly because I keep forgetting how to set up Caddy with the bits I need.)

## How it works

A GitHub Action runs every 24 hours and checks for new releases of caddy and all the bundled plugins. If anything's changed, it updates the versions, commits, and rebuilds the image. If nothing's changed, it does nothing.

The image gets pushed to ghcr as `ghcr.io/notjosh/caddy` with semver tags.

If you want to manually trigger a rebuild, head to the Actions tab and hit "Run workflow" on the Caddy workflow. Or just push a change to the Dockerfile.
