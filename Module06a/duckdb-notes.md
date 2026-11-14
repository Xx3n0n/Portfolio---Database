**Note:** This module was completed by all 4 pod members together simultaneously in class. Each member was not assigned a specific task or part of the module, we more so handeled all the tasks step by step as a whole group.


# Round 1 

### Findings: 

Running `prepare.py` generated `history.db` , `report_jobpart.csv` (File Size: 10.3 MB).`verification.py` verifies the table by giving us the expected number of rows i.e. 2,000,000.

- Original row count: 200,000.
- Number of copies: 10.
- Final row count: 2,000,000.
- Date shift: 91 days.
Understanding question: Why exactly 2 million?

Because:

200,000 × 10 = 2,000,000!

# Round 2

| Measurement | SQLite | Parquet |
|---|---:|---:|
| Rows | 2,000,000 | 2,000,000 |
| File size | 110 mb | 2.3 mb |
| SUM(part_price) | 21000000.0 | 21000000.0 |

As can be seen on the above table, the data in both files are the same containing the same amount of rows and just to verify data is identical the sum of part prices can also be seen as a proof. As we expected the parquet file generated is roughly 50 times smaller in volume. 

# Round 3

| Query | Engine | Median (ms) | Range (ms) | Speedup |
|---|---|---:|---:|---:|
| Dashboard | SQLite | 3,943.75 | 3,297.7–4,912.6 | — |
| Dashboard | DuckDB | 34.10 | 31.2–43.4 | **115.6×** |
| Monthly | SQLite | 2,774.05 | 2,583.8–3,487.0 | — |
| Monthly | DuckDB | 86.30 | 84.1–115.4 | **32.1×** |

### Short analysis
- Dashboard: DuckDB was approximately 115.6 times faster than SQLite.
- Monthly: DuckDB was approximately 32.1 times faster than SQLite.
- DuckDB consistently outperformed SQLite in both analytical workloads.
- The dashboard query showed the greatest performance improvement.

### Conclusion: 

DuckDB demonstrated a substantial performance advantage for analytical queries involving millions of rows, supporting its use as an analytical engine alongside SQLite.

# Round 4 

### Query Plan Comparison

The two query plans show how SQLite and DuckDB approach the same analytical query differently.

**SQLite**

SQLite's query plan shows:

```text
QUERY PLAN
|--SCAN report_history
`--USE TEMP B-TREE FOR GROUP BY
```

- `SCAN report_history` means SQLite scans the table to find rows matching the date condition.
- `USE TEMP B-TREE FOR GROUP BY` means SQLite creates a temporary B-tree structure to organize rows for the grouping operation.
- The plan describes the access strategy, but does not show detailed runtime information or the number of rows processed at each stage.

**DuckDB**

DuckDB's execution plan shows a more detailed analytical execution process:

- **Table Scan (`READ_PARQUET`):** DuckDB reads the Parquet file and processes 2,000,000 rows. It identifies the required columns for the query rather than loading every column from the dataset.
- **Projection:** The query requires `machine_id`, `site`, `technician`, and `part_price` for its output and aggregation. The date column is also used by the filter condition.
- **Hash Group By:** DuckDB uses a hash-based grouping operation to aggregate `part_price` for each combination of `machine_id`, `site`, and `technician`.
- **Reduced output:** The aggregation reduces the 2,000,000 input rows to just 350 grouped result rows.

The DuckDB execution summary reports a total execution time of **0.0611 seconds** and **184.4 kB of data read**.

### Important Distinction

SQLite's `EXPLAIN QUERY PLAN` describes the query's access strategy. It tells us that SQLite scans the table and uses a temporary B-tree for grouping.

DuckDB's `EXPLAIN ANALYZE` provides more detailed execution information, including operators, row counts, and timing. This makes it easier to understand how the query is actually processed.

Overall, DuckDB's column-oriented Parquet scanning and hash-based aggregation are well suited to analytical workloads involving large datasets and grouped calculations.

# Round 5 

## Objective

This round compares SQLite and DuckDB when performing small, individual database operations rather than large analytical queries.

The benchmark measures two operations:

- **Inserts:** How long it takes to insert records into the database.
- **Lookups:** How long it takes to retrieve individual records.

The benchmark was run before and after introducing batching to compare its effect on performance.

## Benchmark Results

### Before batching

```text
inserts sqlite      2.1 ms | duckdb    942.8 ms
lookups sqlite      2.1 ms | duckdb    577.2 ms
```

### With batching

```text
inserts sqlite      1.0 ms | duckdb    861.9 ms
lookups sqlite      2.0 ms | duckdb    607.7 ms
```

## Comparison

| Operation | Database | Before batching | With batching | Change |
|---|---|---:|---:|---:|
| Inserts | SQLite | 2.1 ms | 1.0 ms | 52.4% faster |
| Inserts | DuckDB | 942.8 ms | 861.9 ms | 8.6% faster |
| Lookups | SQLite | 2.1 ms | 2.0 ms | 4.8% faster |
| Lookups | DuckDB | 577.2 ms | 607.7 ms | 5.3% slower |

*Percentage changes are approximate and calculated from the reported timings.*

## Observations

### 1. SQLite performs better for point operations

SQLite completed both insert and lookup operations in approximately 1–2 ms.

DuckDB took considerably longer, requiring approximately 862–943 ms for inserts and 577–608 ms for lookups.

This demonstrates that SQLite is better suited to workloads involving frequent, small transactional operations in this benchmark.

### 2. Batching slightly improved DuckDB's insert performance

DuckDB's insert time decreased from 942.8 ms to 861.9 ms, an improvement of approximately 8.6%.

Batching groups multiple insert operations together, reducing the overhead associated with executing them individually.

However, even after batching, DuckDB remained much slower than SQLite for these inserts.

### 3. Batching did not improve DuckDB's lookup performance

DuckDB's lookup time increased slightly from 577.2 ms to 607.7 ms.

This is expected in principle because batching primarily targets write operations. It does not automatically make individual lookup operations faster.

SQLite's lookup time remained almost unchanged at approximately 2 ms.

## Conclusion

The benchmark demonstrates that SQLite is better suited to small transactional workloads involving individual inserts and lookups.

DuckDB is designed primarily for analytical workloads involving large datasets, aggregations, and reporting queries. Batching can reduce some of its write overhead, but it does not make DuckDB a better choice for frequent point operations in this test.

**Recommendation:** Use SQLite for transactional workloads with frequent individual reads and writes. Use DuckDB for analytical workloads involving large scans, aggregations, and reporting.

## Benchmark Limitations

These results come from individual before-and-after benchmark runs. Execution times can vary due to database initialization, caching, system activity, and other overhead.

Repeated runs under identical conditions would provide more reliable results. The small differences in lookup times should therefore not be treated as conclusive evidence of a performance change.

# Round 6


Dear Lea and Yasmin,

I recommend keeping SQLite as the operational database while moving historical reporting data into Parquet for analytical processing with DuckDB.

Our benchmarks demonstrated that DuckDB was significantly faster for large analytical queries, achieving approximately 100x better performance for the dashboard query and 45x for the monthly report on our test dataset.

The Parquet file also requires considerably less storage than the SQLite database because of its columnar storage and compression.

However, individual INSERT and SELECT operations performed better in SQLite, making it more suitable for everyday operational workloads.

I recommend refreshing the Parquet file automatically every night using a scheduled Python script that exports the latest data from SQLite.

If the refresh fails, the analytical reports could become outdated, potentially showing incorrect information to management.

Therefore, the refresh process should include row-count and financial-total checks to detect inconsistencies between the two systems.

This hybrid approach provides efficient operational database management while allowing fast historical reporting.

# Round 6 

**To:** Lea Winter and Yasmin Kaya  
**Subject:** Moving historical reporting to DuckDB and Parquet

Dear Lea and Yasmin,

I recommend keeping SQLite as the operational database while moving a historical copy of `report_history` into Parquet for analytical queries using DuckDB. In my benchmarks, the dashboard query took an average of 3,943.75 ms in SQLite compared with 34.10 ms in DuckDB, making DuckDB approximately 115.6 times faster; the monthly query took 2,774.05 ms compared with 86.30 ms, making DuckDB approximately 32.1 times faster. These figures are averages of the medians from two separate benchmark runs. The resulting `report_history.parquet` file occupies **2.3 MB** on disk. Individual inserts and lookups should remain in SQLite because, even with batching, SQLite took only 1.0 ms for inserts and 2.0 ms for lookups, compared with 861.9 ms and 607.7 ms respectively in DuckDB. I recommend refreshing the Parquet file automatically every night after the shift using a script that exports the latest data and verifies its row count and total `part_price` against SQLite before publishing the new file. If the refresh fails or the copy becomes outdated, newly recorded jobs will be missing from the reports, potentially causing incorrect cost and revenue figures, so the refresh process should include error detection and a visible last-updated timestamp.

**Recommendation:** Use SQLite for operational transactions and DuckDB with Parquet for historical reporting.

# Homework - Zstrand Compression

| Format | File size |
|---|---:|
| Original Parquet (Snappy) | 2.3 MB |
| Zstandard Parquet | 1.3 MB |
