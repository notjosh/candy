#!/usr/bin/env bash
set -euo pipefail

VERSIONS_FILE="caddy/versions.json"
CHANGED=false
CHANGES=""

check_version() {
  local repo=$1

  # Try releases/latest, then latest tag, then latest commit SHA
  local latest
  latest=$(gh api "repos/$repo/releases/latest" --jq '.tag_name' 2>/dev/null) || \
  latest=$(gh api "repos/$repo/tags?per_page=1" --jq '.[0].name // empty' 2>/dev/null) || \
  latest=""

  if [ -z "$latest" ]; then
    # No releases or tags — fall back to latest commit short SHA
    latest=$(gh api "repos/$repo/commits?per_page=1" --jq '.[0].sha[:7]' 2>/dev/null) || latest=""
  fi

  if [ -z "$latest" ]; then
    echo "WARNING: Could not fetch version for $repo"
    return
  fi

  local current
  current=$(jq -r --arg r "$repo" '.[$r] // ""' "$VERSIONS_FILE")

  if [ "$latest" != "$current" ]; then
    echo "$repo: $current -> $latest"
    CHANGES="${CHANGES}${repo} (${current} -> ${latest}), "
    jq --arg r "$repo" --arg v "$latest" '.[$r] = $v' "$VERSIONS_FILE" > tmp.json && mv tmp.json "$VERSIONS_FILE"
    CHANGED=true

    # If caddy itself changed, update the Dockerfile ARG
    if [ "$repo" = "caddyserver/caddy" ]; then
      local version_number="${latest#v}"
      sed "s/^ARG CADDY_VERSION=.*/ARG CADDY_VERSION=${version_number}/" caddy/Dockerfile > tmp.Dockerfile && mv tmp.Dockerfile caddy/Dockerfile
    fi
  else
    echo "$repo: up to date ($current)"
  fi
}

check_version "caddyserver/caddy"
check_version "caddy-dns/digitalocean"
check_version "greenpau/caddy-security"
check_version "lucaslorentz/caddy-docker-proxy"
check_version "mholt/caddy-l4"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "has_changes=$CHANGED" >> "$GITHUB_OUTPUT"
fi

if [ "$CHANGED" = "true" ]; then
  CHANGES="${CHANGES%, }"
  if [ -n "${GITHUB_ENV:-}" ]; then
    echo "COMMIT_MSG=Bump versions: ${CHANGES}" >> "$GITHUB_ENV"
  fi
  echo "Changes detected: ${CHANGES}"
fi
