#!/usr/bin/env sh
set -e


# Attente DB simple (retry)
RETRIES=15
until php artisan migrate --force || [ $RETRIES -le 0 ]; do
  echo "Migration failed or DB not ready. Retries left: $RETRIES"
  RETRIES=$((RETRIES-1))
  sleep 2
done

php artisan serve --host=0.0.0.0 --port=80 &

exec "$@"
