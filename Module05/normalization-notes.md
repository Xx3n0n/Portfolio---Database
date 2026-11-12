# Round 1 

## Functional Dependencies:


#### job_id → technician 
| Guaranteed (Assuming one technicial per job)
#### machine_id → site 
| Guaranteed (Assuming machines are not to be moved)
#### part_no → part_price 
| Guaranteed (Assuming prices are updated and always known)

### LLM Check: 

ChatGPT (Free Model | 12.11.2026) agreed with my FDs and shared an identical list. 

---

### Current table: 

![ErDia1](pictures/ER_Dia1.png)

### Redesigned: 

![ErDia2](pictures/ER_Dia2.png)


# Round 2

| Anomaly | SQL Statement | What happens in the flat table? |
|---|---|---|
| UPDATE | UPDATE flat5 <br>SET site = 'Bielefeld'<br>WHERE machine_id = 'cnc-01'; | Updating a machine's location requires changing multiple rows. Forgetting one creates inconsistent data. |
| INSERT | INSERT INTO flat5 (part_no, part_price)<br>VALUES ('P-0004', 10.00); | Adding a new part requires creating a row with unrelated or NULL information. |
| DELETE | DELETE FROM flat5<br>WHERE job_id = 1 AND part_no = 'P-0002'; | Deleting the last job using a part also deletes the only record of that part. |

___

# Round 3 

## Normalization:

200000 rows setup can be found in `setup.sql` resulting in the flat_jobpart table. SQL for normalization and data transfer from flat_jobpart into individual tables can be found in `normalize.db`. 

## Row-count Individual: 

```
sqlite> SELECT COUNT(*) FROM machine;
╭──────────╮
│ COUNT(*) │
╞══════════╡
│       50 │
╰──────────╯
sqlite> SELECT COUNT(*) FROM part;
╭──────────╮
│ COUNT(*) │
╞══════════╡
│       10 │
╰──────────╯
sqlite> SELECT COUNT(*) FROM job;
╭──────────╮
│ COUNT(*) │
╞══════════╡
│    20000 │
╰──────────╯
sqlite> SELECT COUNT(*) FROM job_part;
╭──────────╮
│ COUNT(*) │
╞══════════╡
│   200000 │
╰──────────╯
```

### Row integrity check: 

``` 
sqlite> SELECT
   ...>     (SELECT COUNT(*) FROM flat_jobpart) AS flat_rows,
   ...>     (SELECT COUNT(*) FROM job_part) AS normalized_rows;
╭───────────┬─────────────────╮
│ flat_rows │ normalized_rows │
╞═══════════╪═════════════════╡
│    200000 │          200000 │
╰───────────┴─────────────────╯
```
## Normalization explained: 

### First Normal Form (1NF)

The original table already satisfies 1NF because each cell contains a single atomic value. There are no lists or multiple values stored in individual cells.

### Second Normal Form (2NF)

The candidate key is (job_id, part_no).

The original table contains partial dependencies:
- job_id → machine_id, technician, done_on
- part_no → part_price

These attributes depend on only part of the composite key. I separated them into JOB and PART tables.

### Third Normal Form (3NF)

I separated machine information into its own MACHINE table.

The resulting dependencies are:
- machine_id → site
- job_id → machine_id, technician, done_on
- part_no → part_price

This removes unnecessary duplication and ensures that non-key attributes depend on the key, the whole key, and nothing but the key! 

# Round 4

### SQL for De-normalization: 

``` 
DROP TABLE IF EXISTS report_jobpart;

CREATE TABLE report_jobpart AS
SELECT
    j.job_id,
    m.machine_id,
    m.site,
    j.technician,
    jp.part_no,
    p.part_price,
    j.done_on
FROM job j
JOIN machine m
    ON m.machine_id = j.machine_id
JOIN job_part jp
    ON jp.job_id = j.job_id
JOIN part p
    ON p.part_no = jp.part_no;

CREATE INDEX ix_report_machine
ON report_jobpart(machine_id);
``` 

#### Verification: 

``` 
sqlite> SELECT COUNT(*) FROM report_jobpart;
╭──────────╮
│ COUNT(*) │
╞══════════╡
│   200000 │
╰──────────╯
```

### Testing the Normalized Version: 

#### SQL Query: 

``` 
SELECT
    m.machine_id,
    m.site,
    j.technician,
    SUM(p.part_price) AS cost
FROM job j
JOIN machine m
    ON m.machine_id = j.machine_id
JOIN job_part jp
    ON jp.job_id = j.job_id
JOIN part p
    ON p.part_no = jp.part_no
WHERE j.done_on >= date('2026-03-01')
GROUP BY m.machine_id, j.technician;

``` 
#### Query Plan: 
``` 
QUERY PLAN
|--SCAN jp
|--SEARCH j USING INTEGER PRIMARY KEY (rowid=?)
|--SEARCH m USING INDEX sqlite_autoindex_machine_1 (machine_id=?)
|--SEARCH p USING INDEX sqlite_autoindex_part_1 (part_no=?)
`--USE TEMP B-TREE FOR GROUP BY
```


#### Procedure and Result: 
- Ran first with timming off. 
- Calculating the time 3 times and taking the median value: Run Time: `0.805135`

### Testing the Denormalized Version: 

#### SQL Query:

```
SELECT
    machine_id,
    site,
    technician,
    SUM(part_price) AS cost
FROM report_jobpart
WHERE done_on >= date('2026-03-01')
GROUP BY machine_id, technician;
``` 

#### Query Plan: 
``` 
QUERY PLAN
|--SCAN report_jobpart USING INDEX ix_report_machine
`--USE TEMP B-TREE FOR GROUP BY
```

#### Query Plan (Index Dropped):
```
QUERY PLAN
|--SCAN report_jobpart
`--USE TEMP B-TREE FOR GROUP BY
```

#### Procedure and Result: 

- Ran first with timming off. 
- Calculating the time 3 times and taking the median value: Run Time: `0.701149`
- Calculating the time 3 times without index `ix_report_machine`: `0.062500`

#### Note: 

Both queries ran one after another in alternation to take warm cache into accound. Denormalized query was slightly faster and specifically, dropping the index made the query run even faster! My theory for the difference being insignifant is probably the data set is not big enough. ChatGPT says its becasue Sqlite3 handles JOIN statements quit well apparently.


# Round 5
