import sqlite3
import time
import statistics
from pathlib import Path

# Database path
BASE_DIR = Path(__file__).resolve().parent
DB = BASE_DIR / "edge.db"

# Generate 10,000 readings
ROWS = [
    (
        2,
        f"bench-{i:05d}",
        2.7 if i % 2 == 0 else 1.5,
        1
    )
    for i in range(10000)
]

# SQL insertion
INSERT_SQL = """
INSERT INTO reading(sensor_id, ts, value, interval_s)
VALUES (?, ?, ?, ?)
"""

# Alarm trigger
TRIGGER_SQL = """
CREATE TRIGGER trg_vib_alarm
AFTER INSERT ON reading
FOR EACH ROW
WHEN NEW.value > 2.0
AND (
    SELECT metric
    FROM sensor
    WHERE sensor_id = NEW.sensor_id
) = 'vib_rms'

BEGIN
    INSERT INTO alarm(sensor_id, ts, value, reason)
    VALUES (
        NEW.sensor_id,
        NEW.ts,
        NEW.value,
        'vibration over 2.0 mm/s'
    );
END;
"""


def set_trigger(conn, enabled):

    conn.execute("DROP TRIGGER IF EXISTS trg_vib_alarm")

    if enabled:
        conn.execute(TRIGGER_SQL)


def benchmark(conn):

    times = []

    for run in range(3):

        # Clean previous benchmark data
        conn.execute(
            "DELETE FROM alarm WHERE ts LIKE 'bench-%'"
        )

        conn.execute(
            "DELETE FROM reading WHERE ts LIKE 'bench-%'"
        )

        conn.commit()

        # Start measuring
        start = time.perf_counter()

        with conn:
            conn.executemany(INSERT_SQL, ROWS)

        # Stop measuring
        elapsed = time.perf_counter() - start

        times.append(elapsed)

        print(f"Run {run + 1}: {elapsed:.4f} seconds")

    return statistics.median(times)


with sqlite3.connect(DB) as conn:

    conn.execute("PRAGMA foreign_keys = ON")

    # Check that sensor 2 exists
    sensor = conn.execute(
        "SELECT metric FROM sensor WHERE sensor_id = 2"
    ).fetchone()

    if sensor is None or sensor[0] != "vib_rms":
        raise ValueError("Sensor 2 must be a vib_rms sensor.")

    # Experiment A: Without trigger
    print("\n=== WITHOUT TRIGGER ===")

    set_trigger(conn, False)

    median_without = benchmark(conn)

    # Experiment B: With trigger
    print("\n=== WITH TRIGGER ===")

    set_trigger(conn, True)

    median_with = benchmark(conn)

    # Results
    print("\n=== FINAL RESULTS ===")

    print(f"Without trigger: {median_without:.4f} seconds")
    print(f"With trigger:    {median_with:.4f} seconds")

    difference = median_with - median_without

    percentage = (difference / median_without) * 100

    print(f"Difference:      {difference:.4f} seconds")
    print(f"Overhead:        {percentage:.2f}%")

    # Count generated alarms
    alarm_count = conn.execute(
        "SELECT COUNT(*) FROM alarm WHERE ts LIKE 'bench-%'"
    ).fetchone()[0]

    print(f"Generated alarms: {alarm_count}")
