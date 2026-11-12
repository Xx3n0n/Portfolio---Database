# Reflection 05 

## Take-away

I learned that normalization and denormalization are not simply good and bad database designs. They serve different purposes.

Normalization reduces data duplication and makes updates more consistent. Denormalization can simplify reporting queries and potentially improve read performance.

## What was good?

The practical experiment was useful because it allowed me to compare two different database designs using the same dataset.

I particularly found the update experiment interesting because the difference between updating one row and thousands of rows demonstrated the cost of duplicated information.

## What was difficult?

Understanding SQLite query execution plans was challenging. I initially found it difficult to distinguish between SCAN and SEARCH and understand how indexes influence query performance.

Interpreting benchmark results was also challenging because query execution times can vary depending on caching and the query planner.

## Exploration and show stoppers

I found it interesting that an index does not always improve query performance. I would like to explore how DuckDB handles analytical queries compared with SQLite.

## Interaction with peers and instructors

Discussing the results with classmates helped me understand why a database might use a normalized structure for transactions and a denormalized structure for reporting.

## How did you verify AI suggestions?

I used AI to understand SQL queries, functional dependencies and execution plans. I verified the suggestions by executing SQL statements in SQLite and checking the resulting query plans and row counts.

## Help and extra work

I completed the normalization and benchmarking exercises and documented the results. I also explored the possibility of using DuckDB for analytical workloads.
