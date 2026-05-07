-- Exercise 1 — Find the slow query

SELECT * FROM patient_visits WHERE site_id = 3;

-- a) What scan type do you see? Why?
--    A full table scan. Because site_id has few 
--    different values so the query returns many rows.

-- b) site_id has values 1–5. Is this high or low cardinality?
--    It has low cardinality because it only has values 1–5.

-- c) Would adding an index on site_id help? Why or why not?
--    Since many rows share the same value, the index doesn’t 
--    filter much and the whole table is scanned.

-- Exercise 2 — Create an index and see if it helps

-- Step 1: Create it
CREATE INDEX idx_patient_visits_visit_date
ON patient_visits (visit_date);

-- Step 2: Gather stats
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PATIENT_VISITS', cascade => TRUE);
END;
/

-- Step 3: Run the range query and check the plan
SELECT * FROM patient_visits
WHERE visit_date BETWEEN SYSDATE - 30 AND SYSDATE;
--
-- Create an index on visit_date.
-- Then run the range query below and check the plan.

-- a) Does Oracle use the index for this range?
--    For the last 30 days visit_date index will be prbably used
-- because it only needs a smaller part of the table.


-- b) Change the range to the last 7 days. Does the plan change?
--    It may still use the index because fewer rows match.

-- c) Change to the last 700 days. What happens?
--    As 700 days includes almost all the table 
--    a ful table scan would be better.

-- d) Why does the range size affect whether Oracle uses the index?
--    Because an index helps when the query returns only a small number of rows.
--    If the query returns many rows, it is faster for Oracle to just read the whole table.


-- Exercise 3:

CREATE INDEX idx_pv_patient_date ON patient_visits(patient_id, visit_date);

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PATIENT_VISITS', cascade => TRUE);
END;
/

SELECT * FROM patient_visits
WHERE patient_id = 1234
  AND visit_date > SYSDATE - 90;

-- a) Does the plan use the composite index?
--    yes because the index starts with patient_id, 
--    then uses visit_date.

-- b) Now try querying ONLY on visit_date (no patient_id).
--    Does the composite index get used? Why not?
--    No because the index is sorted first by patient_id, not by visit_date.

-- c) What's the rule about column order in composite indexes?
--    You can’t skip the first column in a composite index.

-- Exercise 4 — Function that breaks an index

•⁠  ⁠This query CAN use the index:
SELECT * FROM patient_visits WHERE patient_id = 5432;
-- This one cannot — why?
SELECT * FROM patient_visits WHERE TO_CHAR(patient_id) = '5432';

-- Questions:
-- a) What scan type did the second query use?
--    Full table scan.

-- b) Why does wrapping a column in a function break index use?
--    Because the index is created on the original column value, patient_id.
--    When I write TO_CHAR(patient_id), the value is converted for each
--    row before comparing it. Since the indexed value is not stored as 
--    TO_CHAR(patient_id), the normal index directly can't be used.

-- c) How would you rewrite the second query to allow index use?
SELECT *
FROM patient_visits
WHERE patient_id = 5432;

--    because patient_id is a number, so it should be compared to a number,
--    not converted to text.

-- Exercise 5 — Discussion: real-world scenarios
--
-- For each scenario below, decide:
--   a) Would you add an index?
--   b) On which column(s)?
--   c) Any concerns?

-- Scenario A:
--   a) Yes.
--   b) On the date column.
--   c) If the date range is very large, Oracle may still choose a full table scan.

-- Scenario B:
--   a) Yes. 
--   b) Add an index on customer_id.
--   c) the table has many inserts and too many indexes can slow inserts down.

-- Scenario C:
--   a) Yes.
--   b) Add a unique index on email.
--   c) emails should be stored consistently, like all lowercase, so searches work correctly.