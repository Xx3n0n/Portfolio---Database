# Reflection 06a

## Take-away

This module helped me understand how DuckDB and Parquet can be used for analytical workloads alongside SQLite. I learned how to convert CSV data into Parquet, run analytical queries with DuckDB, and compare query performance between different database systems. One important takeaway was that data formats and encoding matter when moving data between tools.

## What was good?

The module was well structured, and following the tasks step by step helped us understand the purpose of each stage. Working together as a pod also made it easier to discuss the results and understand the differences between SQLite and DuckDB. The performance comparisons were particularly interesting because they showed how much faster DuckDB can be for analytical queries.

## What was difficult?

The main difficulties came from technical errors during the CSV-to-Parquet conversion and while setting up DuckDB. We encountered a CSV encoding problem, a missing SQL table alias, and an unresolved DuckDB import warning in Zed. These issues interrupted the workflow and required some additional troubleshooting before we could continue.

## Exploration and show stoppers

We did not do much exploration outside the module instructions. Most of the work involved following the provided tasks.

However, we had to investigate three issues:

- **CSV encoding:** DuckDB could not read the original CSV because it contained Windows-1252 characters, including the byte `0xFC`. We converted the existing file from CP1252 to UTF-8 and tested the encoding options in DuckDB.
- **Missing SQL alias:** Our query referenced columns using the alias `r`, but the CSV source had not been assigned that alias. Adding `AS r` fixed the binder error.
- **Zed import warning:** Zed could not resolve the DuckDB import. We installed DuckDB in the project environment using `uv add duckdb` and checked the installation by importing it and printing its version. The editor also needed to use the correct project Python interpreter.

These issues were the main obstacles, but we resolved them and continued with the module.

## Interaction with peers and instructors

The entire module was completed together with my pod, working on my machine. We followed the instructions as a group, discussed the errors we encountered, and worked together to resolve them. Most of the interaction was within our pod, and we did not need additional help from the instructors.

## How did you verify AI suggestions?

We treated AI suggestions as possible solutions rather than automatically accepting them. We tested the suggested commands and code changes on my machine, checked whether the errors were resolved, and continued only after the changes worked. For example, we verified the DuckDB installation by importing the package and printing its version. We also reran the relevant scripts after correcting the CSV encoding and SQL alias to confirm that the fixes worked.

## Help and extra work

We mainly followed the module instructions. The additional work involved troubleshooting the CSV encoding, correcting the missing SQL alias, and resolving the DuckDB import warning in Zed. We also spent time understanding why these errors occurred so that we could avoid similar problems in future tasks.
