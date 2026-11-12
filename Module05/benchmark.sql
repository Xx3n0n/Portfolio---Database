
-- ============================================================
-- MODULE 05: NORMALIZATION VS DENORMALIZATION
-- Benchmark: Normalized vs Denormalized Reporting Queries
-- ============================================================

.headers on
.mode column
.timer on

-- ------------------------------------------------------------
-- STEP 1: Create the denormalized reporting table
-- ------------------------------------------------------------

.print ''
.print 'STEP 1: Creating denormalized reporting table'

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
JOIN machine m ON m.machine_id = j.machine_id
JOIN job_part jp ON jp.job_id = j.job_id
JOIN part p ON p.part_no = jp.part_no;


-- ------------------------------------------------------------
-- STEP 2: Create index
-- ------------------------------------------------------------

.print ''
.print 'STEP 2: Creating index on machine_id'

CREATE INDEX ix_report_machine
ON report_jobpart(machine_id);


-- ------------------------------------------------------------
-- STEP 3: Verify row counts
-- ------------------------------------------------------------

.print ''
.print 'STEP 3: Checking row counts'

SELECT
    (SELECT COUNT(*) FROM job_part) AS normalized_rows,
    (SELECT COUNT(*) FROM report_jobpart) AS denormalized_rows;


-- ------------------------------------------------------------
-- STEP 4: Display query plans
-- ------------------------------------------------------------

.print ''
.print 'STEP 4A: Normalized query plan'

EXPLAIN QUERY PLAN
SELECT
    m.machine_id,
    m.site,
    j.technician,
    SUM(p.part_price) AS cost
FROM job j
JOIN machine m ON m.machine_id = j.machine_id
JOIN job_part jp ON jp.job_id = j.job_id
JOIN part p ON p.part_no = jp.part_no
WHERE j.done_on >= date('2026-03-01')
GROUP BY m.machine_id, j.technician;


.print ''
.print 'STEP 4B: Denormalized query plan WITH index'

EXPLAIN QUERY PLAN
SELECT
    machine_id,
    site,
    technician,
    SUM(part_price) AS cost
FROM report_jobpart
WHERE done_on >= date('2026-03-01')
GROUP BY machine_id, technician;


-- ------------------------------------------------------------
-- STEP 5: Benchmark normalized query (3 runs)
-- ------------------------------------------------------------

.print ''
.print 'STEP 5: Normalized query - 3 runs'

.print 'Normalized run 1'

SELECT
    m.machine_id,
    m.site,
    j.technician,
    SUM(p.part_price) AS cost
FROM job j
JOIN machine m ON m.machine_id = j.machine_id
JOIN job_part jp ON jp.job_id = j.job_id
JOIN part p ON p.part_no = jp.part_no
WHERE j.done_on >= date('2026-03-01')
GROUP BY m.machine_id, j.technician;


.print 'Normalized run 2'

SELECT
    m.machine_id,
    m.site,
    j.technician,
    SUM(p.part_price) AS cost
FROM job j
JOIN machine m ON m.machine_id = j.machine_id
JOIN job_part jp ON jp.job_id = j.job_id
JOIN part p ON p.part_no = jp.part_no
WHERE j.done_on >= date('2026-03-01')
GROUP BY m.machine_id, j.technician;


.print 'Normalized run 3'

SELECT
    m.machine_id,
    m.site,
    j.technician,
    SUM(p.part_price) AS cost
FROM job j
JOIN machine m ON m.machine_id = j.machine_id
JOIN job_part jp ON jp.job_id = j.job_id
JOIN part p ON p.part_no = jp.part_no
WHERE j.done_on >= date('2026-03-01')
GROUP BY m.machine_id, j.technician;


-- ------------------------------------------------------------
-- STEP 6: Benchmark denormalized query WITH index (3 runs)
-- ------------------------------------------------------------

.print ''
.print 'STEP 6: Denormalized query WITH index - 3 runs'

.print 'Denormalized with index - run 1'

SELECT
    machine_id,
    site,
    technician,
    SUM(part_price) AS cost
FROM report_jobpart
WHERE done_on >= date('2026-03-01')
GROUP BY machine_id, technician;


.print 'Denormalized with index - run 2'

SELECT
    machine_id,
    site,
    technician,
    SUM(part_price) AS cost
FROM report_jobpart
WHERE done_on >= date('2026-03-01')
GROUP BY machine_id, technician;


.print 'Denormalized with index - run 3'

SELECT
    machine_id,
    site,
    technician,
    SUM(part_price) AS cost
FROM report_jobpart
WHERE done_on >= date('2026-03-01')
GROUP BY machine_id, technician;


-- ------------------------------------------------------------
-- STEP 7: Drop index and inspect query plan
-- ------------------------------------------------------------

.print ''
.print 'STEP 7: Dropping index'

DROP INDEX ix_report_machine;


.print ''
.print 'Denormalized query plan WITHOUT index'

EXPLAIN QUERY PLAN
SELECT
    machine_id,
    site,
    technician,
    SUM(part_price) AS cost
FROM report_jobpart
WHERE done_on >= date('2026-03-01')
GROUP BY machine_id, technician;


-- ------------------------------------------------------------
-- STEP 8: Benchmark denormalized query WITHOUT index (3 runs)
-- ------------------------------------------------------------

.print ''
.print 'STEP 8: Denormalized query WITHOUT index - 3 runs'

.print 'Denormalized without index - run 1'

SELECT
    machine_id,
    site,
    technician,
    SUM(part_price) AS cost
FROM report_jobpart
WHERE done_on >= date('2026-03-01')
GROUP BY machine_id, technician;


.print 'Denormalized without index - run 2'

SELECT
    machine_id,
    site,
    technician,
    SUM(part_price) AS cost
FROM report_jobpart
WHERE done_on >= date('2026-03-01')
GROUP BY machine_id, technician;


.print 'Denormalized without index - run 3'

SELECT
    machine_id,
    site,
    technician,
    SUM(part_price) AS cost
FROM report_jobpart
WHERE done_on >= date('2026-03-01')
GROUP BY machine_id, technician;


-- ------------------------------------------------------------
-- STEP 9: Restore index
-- ------------------------------------------------------------

.print ''
.print 'STEP 9: Recreating index'

CREATE INDEX ix_report_machine
ON report_jobpart(machine_id);


.print ''
.print 'BENCHMARK COMPLETE'
