#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DB_NAME="${PGDATABASE:-wikisneaks}"
ADMIN_DB="${PGADMINDB:-postgres}"

export PGDATABASE="$ADMIN_DB"

echo "Завершение сессий к базе ${DB_NAME} (если есть)..."
psql -v ON_ERROR_STOP=1 -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${DB_NAME}' AND pid <> pg_backend_pid();" 2>/dev/null || true

echo "Удаление базы ${DB_NAME} (если существует)..."
dropdb --if-exists "$DB_NAME" || true

echo "Создание базы ${DB_NAME}..."
createdb "$DB_NAME"

export PGDATABASE="$DB_NAME"

echo "Генерация db/seed.sql..."
python3 "${ROOT_DIR}/Scripts/ws_tools.py" seed-sql --out "${ROOT_DIR}/db/seed.sql"

echo "Применение schema.sql..."
psql -v ON_ERROR_STOP=1 -f "${ROOT_DIR}/db/schema.sql"

echo "Применение seed.sql..."
psql -v ON_ERROR_STOP=1 -f "${ROOT_DIR}/db/seed.sql"

echo "Готово: база ${DB_NAME} пересоздана и заполнена начальными данными."
