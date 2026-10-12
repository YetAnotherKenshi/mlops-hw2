-- П.2: базовые таблицы. Kafka -> Materialized View -> MergeTree (без оптимизаций).
CREATE TABLE IF NOT EXISTS default.transactions_queue
(
    transaction_time String, merch String, cat_id String, amount Float64,
    name_1 String, name_2 String, gender String, street String, one_city String,
    us_state String, post_code String, lat Float64, lon Float64,
    population_city UInt64, jobs String, merchant_lat Float64, merchant_lon Float64, target UInt8
)
ENGINE = Kafka
SETTINGS kafka_broker_list = 'kafka:9092',
         kafka_topic_list = 'transactions',
         kafka_group_name = 'clickhouse_baseline',
         kafka_format = 'JSONEachRow',
         kafka_num_consumers = 1,
         kafka_max_block_size = 65536;

CREATE TABLE IF NOT EXISTS default.transactions
(
    transaction_time String, merch String, cat_id String, amount Float64,
    name_1 String, name_2 String, gender String, street String, one_city String,
    us_state String, post_code String, lat Float64, lon Float64,
    population_city UInt64, jobs String, merchant_lat Float64, merchant_lon Float64, target UInt8
)
ENGINE = MergeTree
ORDER BY tuple();

CREATE MATERIALIZED VIEW IF NOT EXISTS default.transactions_mv TO default.transactions AS
SELECT * FROM default.transactions_queue;
