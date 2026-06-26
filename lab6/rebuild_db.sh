#!/usr/bin/env bash
# Пересоздание БД для lab6:
#   lab4/schema.sql → lab4/seed.sql → lab4/test_data.sql (если есть) → lab6/test_data.sql
#
#   cd lab6 && ./rebuild_db.sh
#   PGDATABASE=mydb ./rebuild_db.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB4_DIR="$(cd "${SCRIPT_DIR}/../lab4" && pwd)"
LAB6_DATA="${SCRIPT_DIR}/test_data.sql"
DB_NAME="${PGDATABASE:-wikisneaks}"
ADMIN_DB="${PGADMINDB:-template1}"

if [[ ! -f "${LAB6_DATA}" ]]; then
  echo "ОШИБКА: нет ${LAB6_DATA}" >&2
  exit 1
fi

echo "=== База: ${DB_NAME} ==="

export PGDATABASE="$ADMIN_DB"
psql -v ON_ERROR_STOP=1 -c \
  "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${DB_NAME}' AND pid <> pg_backend_pid();" \
  2>/dev/null || true

dropdb --if-exists "$DB_NAME"
createdb "$DB_NAME"

export PGDATABASE="$DB_NAME"

echo "=== lab4/schema.sql ==="
psql -v ON_ERROR_STOP=1 -f "${LAB4_DIR}/schema.sql"

echo "=== lab4/seed.sql ==="
psql -v ON_ERROR_STOP=1 -f "${LAB4_DIR}/seed.sql"

if [[ -f "${LAB4_DIR}/test_data.sql" ]]; then
  echo "=== lab4/test_data.sql ==="
  psql -v ON_ERROR_STOP=1 -f "${LAB4_DIR}/test_data.sql"
fi

echo "=== lab6/test_data.sql (обязательно) ==="
psql -v ON_ERROR_STOP=1 -f "${LAB6_DATA}"

echo ""
echo "=== Проверка lab6 ==="
psql -v ON_ERROR_STOP=1 <<'SQL'
SELECT CASE WHEN COUNT(*) >= 20 THEN 'ok' ELSE 'FAIL' END AS lab6_users
FROM ws_user WHERE login LIKE 'lab6_%' OR login = 'safe3_user';

SELECT CASE WHEN COUNT(*) = 4 THEN 'ok' ELSE 'FAIL: ' || COUNT(*)::text END AS economy_themes
FROM ws_theme WHERE name IN ('Финансы', 'Банки', 'Торговля', 'Экспорт');

SELECT CASE WHEN COUNT(*) = 4 THEN 'ok' ELSE 'FAIL: ' || COUNT(*)::text END AS politics_branch
FROM ws_theme WHERE name IN ('Политика', 'Выборы', 'Регионы', 'Местные');
SQL

echo ""
echo "Готово: ${DB_NAME}"
echo "DBeaver: 99_drop_all → 01_check_data → тесты (00_readme.sql)"
