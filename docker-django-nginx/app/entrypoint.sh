#!/usr/bin/env sh
set -e

echo "[INFO] Waiting for PostgreSQL at ${DB_HOST}:${DB_PORT}..."
until nc -z "$DB_HOST" "$DB_PORT"; do
  sleep 1
done
echo "[INFO] PostgreSQL is available."

python manage.py migrate --noinput
python manage.py collectstatic --noinput || true

exec python manage.py runserver 0.0.0.0:8000
