import sqlite3
import csv

DB = "edge.db"
CSV_FILE = "readings.csv"

sql = """
INSERT INTO reading(sensor_id, ts, value, interval_s)
VALUES (?, ?, ?, ?)

ON CONFLICT(sensor_id, ts)
DO UPDATE SET value = excluded.value;
"""

with sqlite3.connect(DB) as conn:

    conn.execute("PRAGMA foreign_keys = ON")

    with open(CSV_FILE, newline="") as file:

        reader = csv.DictReader(file)

        rows = [
            (
                int(row["sensor_id"]),
                row["ts"],
                float(row["value"]),
                int(row["interval_s"])
            )
            for row in reader
        ]

    conn.executemany(sql, rows)

print(f"Processed {len(rows)} readings.")
