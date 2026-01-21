#!/usr/bin/env sh
set -e

echo "[INFO] Starting Django application..."

if [ -n "$DB_HOST" ] && [ -n "$DB_PORT" ]; then
  echo "[INFO] Waiting for PostgreSQL at ${DB_HOST}:${DB_PORT}..."
  until nc -z "$DB_HOST" "$DB_PORT"; do
    sleep 1
  done
  echo "[INFO] PostgreSQL is available."
fi

python manage.py migrate --noinput
python manage.py collectstatic --noinput || true

exec python manage.py runserver 0.0.0.0:8000
