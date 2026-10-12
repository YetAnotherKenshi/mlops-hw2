# HW2: Kafka → ClickHouse

CSV с транзакциями → топик Kafka → ClickHouse. Запрос: категория наибольшей транзакции по каждому штату.

## Запуск

Нужен Docker. Положите `train.csv` с Kaggle в папку `data/` и выполните:

```bash
# 1. поднять Kafka и ClickHouse
docker compose up -d --build

# 2. создать таблицы
docker exec -i hw2-clickhouse clickhouse-client --multiquery < sql/01_ddl_baseline.sql
docker exec -i hw2-clickhouse clickhouse-client --multiquery < sql/03_ddl_optimized.sql

# 3. загрузить CSV в Kafka (данные попадут в обе таблицы)
docker compose run --rm producer

# 4. проверить, что данные доехали (должно быть 786431)
docker exec hw2-clickhouse clickhouse-client -q "SELECT count() FROM transactions"

# 5. запросы, сравнение таблиц, CSV с результатами в results/
./scripts/benchmark.sh
```

Остановить: `docker compose down -v`.

## Файлы

- `scripts/csv_to_kafka.py` — загрузка CSV в Kafka (п.1)
- `sql/01_ddl_baseline.sql` — таблицы: Kafka → Materialized View → MergeTree (п.2)
- `sql/02_query_top_category_by_state.sql` — запрос (п.3), результат: `results/top_category_by_state.csv`
- `sql/03_ddl_optimized.sql` — оптимизированная таблица (п.4)
- `sql/04_query_optimized.sql` — тот же запрос по оптимизированной таблице

## Оптимизация (п.4)

Базовая и оптимизированная таблицы наполняются из одного топика, чтобы их можно было сравнить. Что изменено: ключ сортировки `(us_state, cat_id, transaction_time)`, партиции по месяцам, `DateTime` вместо `String`, `LowCardinality`, компактные типы и кодеки сжатия.

На 786 431 строке: размер 58.7 → 25.1 MiB, запрос 11 → 7 мс. Результаты обоих запросов совпадают.
