#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELEASES_DIR="$ROOT_DIR/deploy/releases"
CURRENT_LINK="$ROOT_DIR/deploy/current"

if [ ! -d "$RELEASES_DIR" ]; then
  echo "[rollback] No releases directory found" >&2
  exit 1
fi

mapfile -t releases < <(ls -1 "$RELEASES_DIR" | sort)
count=${#releases[@]}
if (( count < 2 )); then
  echo "[rollback] Not enough releases to rollback" >&2
  exit 1
fi

current_target=""
if [ -L "$CURRENT_LINK" ]; then
  current_target="$(readlink -f "$CURRENT_LINK" || true)"
fi

idx=-1
for i in "${!releases[@]}"; do
  if [ "$RELEASES_DIR/${releases[$i]}" = "$current_target" ]; then
    idx=$i
    break
  fi
done

if (( idx <= 0 )); then
  prev_index=$((count - 2))
else
  prev_index=$((idx - 1))
fi

target="$RELEASES_DIR/${releases[$prev_index]}"
echo "[rollback] Switching current -> $target"
ln -sfn "$target" "$CURRENT_LINK"

echo "[rollback] Restarting stack"
docker compose -f "$ROOT_DIR/deploy/docker-compose.yml" up -d

echo "[rollback] Done"