#!/usr/bin/env bash
# Сравнение базовой и оптимизированной таблиц: размер на диске, время запроса, выгрузка CSV.
set -euo pipefail
CH="docker exec -i hw2-clickhouse clickhouse-client"

echo "== Строк в таблицах =="
$CH -q "SELECT 'transactions' t, count() FROM transactions UNION ALL SELECT 'transactions_opt', count() FROM transactions_opt FORMAT PrettyCompact"

echo "== Размер на диске =="
$CH -q "SELECT table, sum(rows) rows, formatReadableSize(sum(data_compressed_bytes)) compressed,
        formatReadableSize(sum(data_uncompressed_bytes)) uncompressed
        FROM system.parts WHERE active AND database='default' AND table IN ('transactions','transactions_opt')
        GROUP BY table FORMAT PrettyCompact"

for pair in "transactions:sql/02_query_top_category_by_state.sql" "transactions_opt:sql/04_query_optimized.sql"; do
  t=${pair%%:*}; f=${pair#*:}
  best=999999
  for i in 1 2 3 4 5; do
    ms=$($CH --time --format Null --query "$(cat "$f")" 2>&1 | tail -1 | awk '{printf "%d", $1*1000}')
    [ "$ms" -lt "$best" ] && best=$ms
  done
  echo "Запрос по $t: лучшее из 5 = ${best} ms"
done

echo "== Выгрузка результатов =="
$CH --query "$(cat sql/02_query_top_category_by_state.sql)" --format CSVWithNames > results/top_category_by_state.csv
$CH --query "$(cat sql/04_query_optimized.sql)" --format CSVWithNames > results/top_category_by_state_optimized.csv
diff -q results/top_category_by_state.csv results/top_category_by_state_optimized.csv && echo "Результаты совпадают"
