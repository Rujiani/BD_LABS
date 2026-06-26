#!/usr/bin/env bash
# Матрица замеров: каждый тип индекса отдельно × Q4 + Q3.
#
#   ./run_benchmark_matrix.sh          # на текущей bd_lab7 без индексов
#   ./run_benchmark_matrix.sh --rebuild
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_NAME="${PGDATABASE:-bd_lab7}"
OUT_DIR="${SCRIPT_DIR}/results/matrix"
METRICS="${OUT_DIR}/metrics.tsv"
REBUILD=false

if [[ "${1:-}" == "--rebuild" ]]; then
  REBUILD=true
fi

export PGDATABASE="$DB_NAME"

run_query_metrics() {
  local query_file="$1"
  local explain_file="$2"

  {
    echo "SET work_mem = '64MB';"
    echo "EXPLAIN (ANALYZE, BUFFERS, SETTINGS)"
    cat "$query_file"
  } | psql -v ON_ERROR_STOP=1 -X -q > "$explain_file"

  local planning_ms execution_ms shared_hit
  planning_ms=$(grep -m1 'Planning Time:' "$explain_file" | sed -E 's/.*Planning Time: ([0-9.]+) ms.*/\1/')
  execution_ms=$(grep -m1 'Execution Time:' "$explain_file" | sed -E 's/.*Execution Time: ([0-9.]+) ms.*/\1/')
  shared_hit=$(grep 'Buffers: shared hit=' "$explain_file" | sed -E 's/.*shared hit=([0-9]+).*/\1/' | awk '{s+=$1} END {print s+0}')

  echo -e "${planning_ms}\t${execution_ms}\t${shared_hit}"
}

run_scenario() {
  local scenario="$1"
  local scenario_dir="${OUT_DIR}/${scenario}"
  mkdir -p "$scenario_dir"

  psql -v ON_ERROR_STOP=1 -q -f "${SCRIPT_DIR}/indexes/drop_all.sql"

  case "$scenario" in
    none) ;;
    composite) psql -v ON_ERROR_STOP=1 -q -f "${SCRIPT_DIR}/indexes/composite.sql" ;;
    partial)   psql -v ON_ERROR_STOP=1 -q -f "${SCRIPT_DIR}/indexes/partial.sql" ;;
    covering)  psql -v ON_ERROR_STOP=1 -q -f "${SCRIPT_DIR}/indexes/covering.sql" ;;
    all)       psql -v ON_ERROR_STOP=1 -q -f "${SCRIPT_DIR}/indexes.sql" ;;
    *) echo "Неизвестный сценарий: $scenario" >&2; exit 1 ;;
  esac

  echo "=== ${scenario} ==="
  local q4 q3
  q4=$(run_query_metrics \
    "${SCRIPT_DIR}/queries/query04_activity_core.sql" \
    "${scenario_dir}/q04_explain.txt")
  q3=$(run_query_metrics \
    "${SCRIPT_DIR}/queries/query03_stale_safe_ip.sql" \
    "${scenario_dir}/q03_explain.txt")

  IFS=$'\t' read -r q4_plan q4_exec q4_buf <<< "$q4"
  IFS=$'\t' read -r q3_plan q3_exec q3_buf <<< "$q3"

  echo -e "${scenario}\t${q4_plan}\t${q4_exec}\t${q4_buf}\t${q3_plan}\t${q3_exec}\t${q3_buf}" >> "$METRICS"
  printf '  Q4: plan=%s ms  exec=%s ms  buffers=%s\n' "$q4_plan" "$q4_exec" "$q4_buf"
  printf '  Q3: plan=%s ms  exec=%s ms  buffers=%s\n' "$q3_plan" "$q3_exec" "$q3_buf"
}

if $REBUILD; then
  "${SCRIPT_DIR}/rebuild_db.sh"
fi

mkdir -p "$OUT_DIR"
: > "$METRICS"
echo -e "scenario\tq4_planning_ms\tq4_execution_ms\tq4_buffers_shared\tq3_planning_ms\tq3_execution_ms\tq3_buffers_shared" >> "$METRICS"

for scenario in none covering partial composite all; do
  run_scenario "$scenario"
done

echo ""
echo "Метрики: ${METRICS}"
echo "Готово."
