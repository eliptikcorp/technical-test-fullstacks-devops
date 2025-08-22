#!/usr/bin/env bash
set -euo pipefail

# Determine repo root (scripts/..)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Metadata
TIMESTAMP="$(date -u +%Y%m%d%H%M%S)"
IMAGE_TAG="starter-api:${TIMESTAMP}"
RELEASE_DIR="$ROOT_DIR/deploy/releases/$TIMESTAMP"
GIT_SHA="$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
RUNNER="${GITHUB_RUN_ID:-local}"

echo "[deploy_local] Building API image (${IMAGE_TAG})"
# Build with API folder as context to ensure package.json is present
docker build -f "$ROOT_DIR/devops/starter/api/Dockerfile" -t "$IMAGE_TAG" "$ROOT_DIR/devops/starter/api"

# Prepare release artifacts
echo "[deploy_local] Preparing release directory $RELEASE_DIR"
mkdir -p "$RELEASE_DIR/nginx"
# Copy Nginx config into the release so the compose is self-contained
cp "$ROOT_DIR/devops/starter/nginx/default.conf" "$RELEASE_DIR/nginx/default.conf"

# Generate release-specific docker-compose.yml pinned to this image tag
cat > "$RELEASE_DIR/docker-compose.yml" <<'YAML'
# Release-specific compose (auto-generated)

services:
  api:
    image: IMAGE_PLACEHOLDER
    container_name: devops-api
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    depends_on:
      db:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "node -e \"require('http').get('http://localhost:3000/health', res => { process.exit(res.statusCode === 200 ? 0 : 1) }).on('error', () => process.exit(1));\""]
      interval: 10s
      timeout: 3s
      retries: 5
      start_period: 5s
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp

  db:
    image: postgres:15
    environment:
      POSTGRES_DB: devopsdb
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    ports:
      - "5433:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d devopsdb"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 5s
    security_opt:
      - no-new-privileges:true

  nginx:
    image: nginx:latest
    ports:
      - "8080:80"
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      api:
        condition: service_healthy
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /var/cache/nginx
      - /var/run

volumes:
  pgdata:
YAML

# Replace placeholder with the built image tag (GNU/BSD sed compatible)
if sed --version >/dev/null 2>&1; then
  sed -i "s|IMAGE_PLACEHOLDER|$IMAGE_TAG|g" "$RELEASE_DIR/docker-compose.yml"
else
  sed -i "" "s|IMAGE_PLACEHOLDER|$IMAGE_TAG|g" "$RELEASE_DIR/docker-compose.yml"
fi

# Write manifest
cat > "$RELEASE_DIR/manifest.json" <<EOF
{
  "tag": "$IMAGE_TAG",
  "git_sha": "$GIT_SHA",
  "timestamp": "$TIMESTAMP",
  "runner": "$RUNNER",
  "compose_file": "deploy/releases/$TIMESTAMP/docker-compose.yml"
}
EOF

# Atomic switch current -> new release
ln -sfn "$RELEASE_DIR" "$ROOT_DIR/deploy/current"

# Start/Update stack from the current release compose
echo "[deploy_local] Starting stack with docker compose (deploy/current/docker-compose.yml)"
docker compose -f "$ROOT_DIR/deploy/current/docker-compose.yml" up -d

# Health check via Nginx (proxying to API)
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
    echo "[deploy_local] Dumping diagnostics (docker compose ps/logs)" >&2
    docker compose -f "$ROOT_DIR/deploy/current/docker-compose.yml" ps || true
    docker compose -f "$ROOT_DIR/deploy/current/docker-compose.yml" logs --no-color --tail=200 || true
    exit 1
  fi
done

echo "[deploy_local] Deployed release $TIMESTAMP (current -> releases/$TIMESTAMP)"