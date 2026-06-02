-- ============================================
-- EXERCISE 1: Explore your schema
-- ============================================

SELECT object_type, COUNT(*) AS total
FROM user_objects
GROUP BY object_type
ORDER BY object_type;

SELECT object_name, object_type, created, last_ddl_time
FROM user_objects
ORDER BY object_type, object_name;

-- Object types found:
-- FUNCTION
-- INDEX
-- LOB
-- PROCEDURE
-- SEQUENCE
-- TABLE
-- TRIGGER

-- ============================================
-- EXERCISE 2: Basic GET_DDL
-- ============================================

BEGIN
DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'PRETTY', TRUE);
DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR', TRUE);
DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SEGMENT_ATTRIBUTES', FALSE);
DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE', FALSE);
DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE', FALSE);
END;
/

SET LONG 100000
SET PAGESIZE 0

SELECT DBMS_METADATA.GET_DDL('TABLE', 'CUSTOMER')
FROM DUAL;

SELECT DBMS_METADATA.GET_DDL('TABLE', table_name)
FROM user_tables
ORDER BY table_name;

-- Column definitions:
-- CUSTOMER_ID NUMBER NOT NULL
-- CUSTOMER_NAME VARCHAR2(100) NOT NULL

-- Constraints:
-- PRIMARY KEY on CUSTOMER_ID
-- FOREIGN KEY references SALES table

-- Storage parameters:
-- PCTFREE and INITRANS still appeared in some tables

-- ============================================
-- EXERCISE 3: Clean DDL for portability
-- ============================================

BEGIN
DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'EMIT_SCHEMA', FALSE);
DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'PRETTY', TRUE);
DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR', TRUE);
DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SEGMENT_ATTRIBUTES', FALSE);
DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE', FALSE);
DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE', FALSE);
END;
/

SELECT DBMS_METADATA.GET_DDL('TABLE', table_name)
FROM user_tables
WHERE ROWNUM = 1;

-- With EMIT_SCHEMA:
-- CREATE TABLE "SCHEMA"."CUSTOMER"

-- Without EMIT_SCHEMA:
-- CREATE TABLE "CUSTOMER"

-- ============================================
-- EXERCISE 4: Plan a migration
-- ============================================

SELECT DBMS_METADATA.GET_DDL('TABLE', table_name)
FROM user_tables
WHERE table_name = 'CUSTOMER_SALE';

SELECT constraint_name, table_name, r_constraint_name
FROM user_constraints
WHERE constraint_type = 'R';

-- Migration checklist:
-- Export DDL with EMIT_SCHEMA = FALSE
-- Check foreign key references
-- Remove old schema references
-- Create tables first
-- Restore constraints and indexes later
-- Restore procedures and triggers last

-- Restore order:
-- 1. Base tables
-- 2. Tables with dependencies
-- 3. Constraints
-- 4. Indexes and sequences
-- 5. Views
-- 6. Procedures/functions
-- 7. Triggers

-- ============================================
-- EXERCISE 5: Dependency order
-- ============================================

SELECT referenced_name, referencing_name, referencing_type
FROM user_dependencies
ORDER BY referenced_name;

SELECT referencing_name, referencing_type
FROM user_dependencies
WHERE referenced_name IN (
SELECT table_name FROM user_tables
)
ORDER BY referencing_type, referencing_name;

SELECT referenced_name, referenced_type
FROM user_dependencies
WHERE referencing_name = 'TEST_PROC';

SELECT referencing_name,
referencing_type,
LISTAGG(referenced_name, ', ')
WITHIN GROUP (ORDER BY referenced_name) AS dependencies
FROM user_dependencies
WHERE referencing_type IN ('PACKAGE', 'PROCEDURE', 'FUNCTION')
GROUP BY referencing_name, referencing_type
ORDER BY referencing_type, referencing_name;

-- ============================================
-- EXERCISE 6: Design your own backup strategy
-- ============================================

-- STEP 1: Document current schema

SELECT object_type, COUNT(*)
FROM user_objects
GROUP BY object_type;

SELECT table_name, num_rows
FROM user_tables
ORDER BY num_rows DESC;

-- STEP 2: Extract DDL

BEGIN
DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'PRETTY', TRUE);
DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR', TRUE);
DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'EMIT_SCHEMA', FALSE);
DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SEGMENT_ATTRIBUTES', FALSE);
DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE', FALSE);
DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE', FALSE);
END;
/

SELECT DBMS_METADATA.GET_DDL('TABLE', table_name)
FROM user_tables;

SELECT DBMS_METADATA.GET_DDL('INDEX', index_name)
FROM user_indexes
WHERE index_name NOT LIKE 'SYS_%';

SELECT DBMS_METADATA.GET_DDL('SEQUENCE', sequence_name)
FROM user_sequences;

SELECT DBMS_METADATA.GET_DDL('PROCEDURE', object_name)
FROM user_objects
WHERE object_type = 'PROCEDURE';

SELECT DBMS_METADATA.GET_DDL('FUNCTION', object_name)
FROM user_objects
WHERE object_type = 'FUNCTION';

-- STEP 3: Clean DDL

-- Remove old schema names
-- Review FK constraints
-- Remove unnecessary storage clauses

-- STEP 4: Restore objects

-- 1. Tables
-- 2. Sequences
-- 3. Indexes
-- 4. Constraints
-- 5. Views
-- 6. Procedures and functions
-- 7. Triggers

-- STEP 5: Verify migration

SELECT object_type, COUNT(*)
FROM user_objects
GROUP BY object_type;

SELECT table_name, num_rows
FROM user_tables
ORDER BY table_name;

SELECT object_name, object_type, status
FROM user_objects
WHERE status = 'INVALID';

-- ============================================
-- DISCUSSION QUESTIONS
-- ============================================

-- Q1
-- DBMS_METADATA exports only DDL and needs manual cleanup.
-- expdp exports both data and schema but requires more privileges.

-- Q2
-- Create objects first and enable constraints later.
-- For packages, create specification before package body.

-- Q3
-- 1. Analyze schema objects
-- 2. Extract clean DDL
-- 3. Remove schema references
-- 4. Check dependencies
-- 5. Restore objects in dependency order
-- 6. Verify object counts and status

-- ============================================
-- FURTHER INVESTIGATION
-- ============================================

-- 1. expdp / impdp
-- 2. SQL Developer export tools
-- 3. SQLcl scripting
-- 4. Transportable tablespaces
-- 5. Oracle Cloud migration services
