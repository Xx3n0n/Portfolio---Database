import duckdb

con = duckdb.connect()

result = con.execute("""
    SELECT
        COUNT(*),
        ROUND(SUM(part_price), 2)
    FROM read_parquet('report_history.parquet');
""").fetchone()

print("DuckDB results:")
print("Row count:", result[0])
print("Total price:", result[1])

con.close()
