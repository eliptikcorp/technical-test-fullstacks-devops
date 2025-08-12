#!/usr/bin/env bash
set -e

# Générer la clé si absente
if [ -f /var/www/html/.env ]; then
  php artisan key:generate || true
fi

# Attente DB simple (retry)
RETRIES=15
until php artisan migrate --force || [ $RETRIES -le 0 ]; do
  echo "Migration failed or DB not ready. Retries left: $RETRIES"
  RETRIES=$((RETRIES-1))
  sleep 2
done

exec "$@"
