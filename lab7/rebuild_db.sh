#!/usr/bin/env bash
# Пересоздание БД lab7 (bd_lab7):
#   schema_baseline.sql → lab4/seed.sql → generated test_data.sql
#
#   cd lab7 && ./rebuild_db.sh
#   PGDATABASE=bd_lab7 ./rebuild_db.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB4_DIR="$(cd "${SCRIPT_DIR}/../lab4" && pwd)"
DB_NAME="${PGDATABASE:-bd_lab7}"
ADMIN_DB="${PGADMINDB:-template1}"
TEST_DATA="${SCRIPT_DIR}/test_data.sql"

USERS="${LAB7_USERS:-800}"
DOCUMENTS="${LAB7_DOCUMENTS:-400}"
VERSIONS_MAX="${LAB7_VERSIONS_MAX:-8}"
SEED="${LAB7_SEED:-7}"

echo "=== База: ${DB_NAME} ==="

export PGDATABASE="$ADMIN_DB"
psql -v ON_ERROR_STOP=1 -c \
  "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${DB_NAME}' AND pid <> pg_backend_pid();" \
  2>/dev/null || true

dropdb --if-exists "$DB_NAME"
createdb "$DB_NAME"

export PGDATABASE="$DB_NAME"

echo "=== schema_baseline.sql ==="
psql -v ON_ERROR_STOP=1 -f "${SCRIPT_DIR}/schema_baseline.sql"

echo "=== lab4/seed.sql ==="
psql -v ON_ERROR_STOP=1 -f "${LAB4_DIR}/seed.sql"

echo "=== Генерация test_data.sql (users=${USERS}, documents=${DOCUMENTS}, versions-max=${VERSIONS_MAX}, seed=${SEED}) ==="
python3 "${LAB4_DIR}/ws_tools.py" test-data \
  --out "${TEST_DATA}" \
  --users "$USERS" \
  --documents "$DOCUMENTS" \
  --versions-max "$VERSIONS_MAX" \
  --seed "$SEED"

echo "=== test_data.sql ==="
psql -v ON_ERROR_STOP=1 -f "${TEST_DATA}"

echo "=== scale_volume.sql ==="
psql -v ON_ERROR_STOP=1 -f "${SCRIPT_DIR}/scale_volume.sql"

echo "=== VACUUM ANALYZE ==="
psql -v ON_ERROR_STOP=1 <<'SQL'
VACUUM ANALYZE ws_login_history;
VACUUM ANALYZE ws_safe_ip;
VACUUM ANALYZE ws_view_history;
VACUUM ANALYZE ws_document_version;
VACUUM ANALYZE ws_version_theme;
SQL

echo ""
echo "=== Объём данных ==="
psql -v ON_ERROR_STOP=1 <<'SQL'
SELECT relname AS table_name, n_live_tup AS approx_rows
FROM pg_stat_user_tables
WHERE relname IN (
    'ws_login_history', 'ws_safe_ip', 'ws_view_history',
    'ws_document_version', 'ws_version_theme', 'ws_user', 'ws_document'
)
ORDER BY relname;
SQL

echo ""
echo "=== Sanity-check: строк в отчётах Q4/Q3 >= 7 ==="
Q04_ROWS=$(psql -v ON_ERROR_STOP=1 -A -t -f "${SCRIPT_DIR}/queries/query04_activity_core.sql" | wc -l)
Q03_ROWS=$(psql -v ON_ERROR_STOP=1 -A -t -f "${SCRIPT_DIR}/queries/query03_stale_safe_ip.sql" | wc -l)
echo "Q4 rows: ${Q04_ROWS}"
echo "Q3 rows: ${Q03_ROWS}"
if [[ "${Q04_ROWS}" -lt 7 || "${Q03_ROWS}" -lt 7 ]]; then
  echo "ОШИБКА: ожидалось >= 7 строк в каждом отчёте" >&2
  exit 1
fi

echo ""
echo "Готово: ${DB_NAME}"
