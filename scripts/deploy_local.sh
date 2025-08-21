#!/usr/bin/env bash
set -euo pipefail

# Determine repo root (scripts/..)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Metadata
TIMESTAMP="$(date -u +%Y%m%d%H%M%S)"
RELEASE_DIR="$ROOT_DIR/deploy/releases/$TIMESTAMP"
GIT_SHA="$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
RUNNER="${GITHUB_RUN_ID:-local}"

echo "[deploy_local] Building API image (starter-api:local)"
docker build -f "$ROOT_DIR/devops/starter/api/Dockerfile" -t starter-api:local "$ROOT_DIR"

echo "[deploy_local] Starting stack with docker compose (deploy/docker-compose.yml)"
docker compose -f "$ROOT_DIR/deploy/docker-compose.yml" up -d

echo "[deploy_local] Waiting for Nginx /health at http://localhost:8080/health"
for i in {1..30}; do
  code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health || true)
  if [ "$code" = "200" ]; then
    echo "[deploy_local] Healthcheck OK"
    break
  fi
  sleep 2
  echo "[deploy_local] retry $i..."
  if [ "$i" = "30" ]; then
    echo "[deploy_local] Healthcheck failed after retries" >&2
    exit 1
  fi
done

# Prepare release artifacts
echo "[deploy_local] Preparing release directory $RELEASE_DIR"
mkdir -p "$RELEASE_DIR/nginx"
cp "$ROOT_DIR/deploy/docker-compose.yml" "$RELEASE_DIR/" || true
cp "$ROOT_DIR/devops/starter/nginx/default.conf" "$RELEASE_DIR/nginx/default.conf" || true

# Write manifest
cat > "$RELEASE_DIR/manifest.json" <<EOF
{
  "tag": "starter-api:local",
  "git_sha": "$GIT_SHA",
  "timestamp": "$TIMESTAMP",
  "runner": "$RUNNER",
  "compose_file": "deploy/docker-compose.yml"
}
EOF

# Atomic switch current -> new release
ln -sfn "$RELEASE_DIR" "$ROOT_DIR/deploy/current"
echo "[deploy_local] Deployed release $TIMESTAMP (current -> releases/$TIMESTAMP)"