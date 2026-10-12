"""Загружает CSV с транзакциями в топик Kafka (одна строка CSV = одно JSON-сообщение)."""
import argparse
import csv
import json
import os
import sys

from confluent_kafka import Producer

FLOAT_COLS = {"amount", "lat", "lon", "merchant_lat", "merchant_lon"}
INT_COLS = {"population_city", "target"}


def convert(row: dict) -> dict:
    out = {}
    for k, v in row.items():
        if v is None or v == "":
            continue  # пропуск -> значение по умолчанию в ClickHouse
        if k in FLOAT_COLS:
            v = float(v)
        elif k in INT_COLS:
            v = int(float(v))
        if k == "transaction_time" and len(v) == 16:
            v += ":00"  # в данных нет секунд
        out[k] = v
    return out


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--csv", default=os.getenv("CSV_PATH", "data/train.csv"))
    p.add_argument("--bootstrap", default=os.getenv("KAFKA_BOOTSTRAP", "localhost:9094"))
    p.add_argument("--topic", default=os.getenv("KAFKA_TOPIC", "transactions"))
    args = p.parse_args()

    if not os.path.exists(args.csv):
        print(f"CSV не найден: {args.csv}", file=sys.stderr)
        return 1

    producer = Producer({"bootstrap.servers": args.bootstrap, "linger.ms": 50,
                         "compression.type": "lz4"})
    errors = []

    def on_delivery(err, _msg):
        if err:
            errors.append(err)

    sent = 0
    with open(args.csv, newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            while True:
                try:
                    producer.produce(args.topic, json.dumps(convert(row)).encode(),
                                     callback=on_delivery)
                    break
                except BufferError:
                    producer.poll(0.5)
            sent += 1
            producer.poll(0)
            if sent % 100_000 == 0:
                print(f"отправлено {sent}", flush=True)
    producer.flush()
    print(f"Готово: отправлено {sent} сообщений в топик '{args.topic}', ошибок: {len(errors)}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
