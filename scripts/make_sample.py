"""Генерирует небольшой синтетический CSV той же структуры (для проверки без Kaggle)."""
import csv
import random
import sys
from datetime import datetime, timedelta

N = int(sys.argv[1]) if len(sys.argv) > 1 else 200_000
OUT = sys.argv[2] if len(sys.argv) > 2 else "data/train.csv"
STATES = ["CA", "TX", "NY", "FL", "WA", "OH", "IL", "PA", "GA", "NC", "MI", "NJ"]
CATS = ["food_dining", "gas_transport", "grocery_pos", "shopping_net", "travel", "misc_pos", "health_fitness", "home"]
random.seed(42)
t0 = datetime(2023, 1, 1)
cols = ["transaction_time", "merch", "cat_id", "amount", "name_1", "name_2", "gender", "street", "one_city",
        "us_state", "post_code", "lat", "lon", "population_city", "jobs", "merchant_lat", "merchant_lon", "target"]
with open(OUT, "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(cols)
    for i in range(N):
        w.writerow([(t0 + timedelta(seconds=i * 150)).strftime("%Y-%m-%d %H:%M:%S"),
                    f"merch_{random.randint(1, 800)}", random.choice(CATS),
                    round(random.lognormvariate(3.5, 1.2), 2), "Ann", "Lee",
                    random.choice("MF"), f"{i} Main St", "Town", random.choice(STATES),
                    random.randint(10000, 99999), round(random.uniform(25, 48), 4),
                    round(random.uniform(-120, -75), 4), random.randint(100, 100000), "Engineer",
                    round(random.uniform(25, 48), 4), round(random.uniform(-120, -75), 4),
                    int(random.random() < 0.01)])
print(f"{N} строк -> {OUT}")
