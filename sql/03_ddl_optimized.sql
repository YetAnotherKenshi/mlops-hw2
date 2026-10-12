-- П.4: оптимизированное хранение (DDL из п.2 изменён).
-- Тот же топик читается отдельной consumer-группой, поэтому обе таблицы наполняются
-- независимо и их можно сравнить (см. scripts/benchmark.sh).
CREATE TABLE IF NOT EXISTS default.transactions_opt_queue
(
    transaction_time DateTime, merch String, cat_id String, amount Float64,
    name_1 String, name_2 String, gender String, street String, one_city String,
    us_state String, post_code String, lat Float64, lon Float64,
    population_city UInt64, jobs String, merchant_lat Float64, merchant_lon Float64, target UInt8
)
ENGINE = Kafka
SETTINGS kafka_broker_list = 'kafka:9092',
         kafka_topic_list = 'transactions',
         kafka_group_name = 'clickhouse_optimized',
         kafka_format = 'JSONEachRow',
         kafka_num_consumers = 1,
         kafka_max_block_size = 65536;

CREATE TABLE IF NOT EXISTS default.transactions_opt
(
    transaction_time DateTime CODEC(Delta, ZSTD),
    merch            LowCardinality(String),
    cat_id           LowCardinality(String),
    amount           Float32 CODEC(Gorilla, ZSTD),
    name_1           LowCardinality(String),
    name_2           LowCardinality(String),
    gender           LowCardinality(String),
    street           String CODEC(ZSTD),
    one_city         LowCardinality(String),
    us_state         LowCardinality(String),
    post_code        String CODEC(ZSTD),
    lat              Float32 CODEC(Gorilla, ZSTD),
    lon              Float32 CODEC(Gorilla, ZSTD),
    population_city  UInt32 CODEC(T64, ZSTD),
    jobs             LowCardinality(String),
    merchant_lat     Float32 CODEC(Gorilla, ZSTD),
    merchant_lon     Float32 CODEC(Gorilla, ZSTD),
    target           UInt8 CODEC(T64, ZSTD)
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(transaction_time)
ORDER BY (us_state, cat_id, transaction_time);   -- ключ под GROUP BY us_state

CREATE MATERIALIZED VIEW IF NOT EXISTS default.transactions_opt_mv TO default.transactions_opt AS
SELECT * FROM default.transactions_opt_queue;
