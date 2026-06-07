-- Lesson 08: Exercise — Assignment History

-- A support ticketing system. Tickets get reassigned between agents.
-- We need to track who was assigned when the ticket was created
-- and who was assigned when it was resolved.


-- Step 1 — Source Tables (OLTP)

-- Clean up
BEGIN EXECUTE IMMEDIATE 'DROP TABLE ticket_assignments'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE tickets'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- tickets
CREATE TABLE tickets (
    ticket_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title         VARCHAR2(200) NOT NULL,
    status        VARCHAR2(20) NOT NULL,
    priority      VARCHAR2(10) NOT NULL,
    created_at    TIMESTAMP DEFAULT SYSTIMESTAMP,
    resolved_at   TIMESTAMP,
    assigned_to   NUMBER
);

-- ticket_assignments
CREATE TABLE ticket_assignments (
    assignment_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_id     NUMBER NOT NULL,
    assigned_to   NUMBER NOT NULL,
    assigned_by   NUMBER,
    valid_from    TIMESTAMP NOT NULL,
    valid_to      TIMESTAMP
);


-- Step 2 — Sample Data

-- Insert tickets
INSERT INTO tickets
(title, status, priority, created_at, resolved_at, assigned_to)
VALUES
('Customer cannot login', 'completed', 'high',
 TIMESTAMP '2026-05-01 09:00:00',
 TIMESTAMP '2026-05-02 15:00:00',
 1);

INSERT INTO tickets
(title, status, priority, created_at, resolved_at, assigned_to)
VALUES
('Invoice payment error', 'completed', 'medium',
 TIMESTAMP '2026-05-03 10:00:00',
 TIMESTAMP '2026-05-04 14:00:00',
 2);

INSERT INTO tickets
(title, status, priority, created_at, resolved_at, assigned_to)
VALUES
('Analytics page is slow', 'in_progress', 'high',
 TIMESTAMP '2026-05-05 11:00:00',
 NULL,
 3);

INSERT INTO tickets
(title, status, priority, created_at, resolved_at, assigned_to)
VALUES
('Password reset failure', 'completed', 'critical',
 TIMESTAMP '2026-05-06 09:00:00',
 TIMESTAMP '2026-05-07 13:00:00',
 1);

INSERT INTO tickets
(title, status, priority, created_at, resolved_at, assigned_to)
VALUES
('Mobile menu alignment', 'open', 'low',
 TIMESTAMP '2026-05-07 10:00:00',
 NULL,
 2);

COMMIT;


-- Step 3 — Trigger

CREATE OR REPLACE TRIGGER trg_ticket_assignment
AFTER INSERT OR UPDATE OF assigned_to ON tickets
FOR EACH ROW
BEGIN

    -- INSERT
    IF INSERTING THEN

        INSERT INTO ticket_assignments
        (ticket_id, assigned_to, assigned_by, valid_from)
        VALUES
        (:NEW.ticket_id,
         :NEW.assigned_to,
         NULL,
         :NEW.created_at);

    -- UPDATE
    ELSIF UPDATING THEN

        -- close old assignment
        UPDATE ticket_assignments
        SET valid_to = SYSTIMESTAMP
        WHERE ticket_id = :OLD.ticket_id
          AND valid_to IS NULL;

        -- insert new assignment
        INSERT INTO ticket_assignments
        (ticket_id, assigned_to, assigned_by, valid_from)
        VALUES
        (:NEW.ticket_id,
         :NEW.assigned_to,
         NULL,
         SYSTIMESTAMP);

    END IF;

END;
/

-- Test it: reassign ticket 2 from agent 2 to agent 3
UPDATE tickets
SET assigned_to = 3
WHERE ticket_id = 2;

COMMIT;

-- Check the assignment history
SELECT *
FROM ticket_assignments
WHERE ticket_id = 2
ORDER BY valid_from;


-- Step 4 — Data Warehouse Tables (Star Schema)

-- Clean up
BEGIN EXECUTE IMMEDIATE 'DROP TABLE fact_ticket_daily'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dim_agent'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- dim_agent
CREATE TABLE dim_agent (
    agent_key    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    agent_name   VARCHAR2(100),
    team         VARCHAR2(50)
);

-- fact_ticket_daily
CREATE TABLE fact_ticket_daily (
    fact_key            NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date_key            NUMBER,
    agent_key           NUMBER,
    status              VARCHAR2(20),
    priority            VARCHAR2(10),
    tickets_created     NUMBER,
    tickets_resolved    NUMBER
);


-- Step 5 — Populate dim_agent

INSERT INTO dim_agent (agent_name, team)
VALUES ('Baltazar', 'Technical');

INSERT INTO dim_agent (agent_name, team)
VALUES ('Jozef', 'Technical');

INSERT INTO dim_agent (agent_name, team)
VALUES ('Nachito', 'Support');

INSERT INTO dim_agent (agent_name, team)
VALUES ('Pau', 'Support');

COMMIT;


-- Step 6 — ETL Logic (Colab)

-- In Colab, this logic extracts tickets and ticket assignment history,
-- finds the correct assigned agent at created_at and resolved_at,
-- groups the results, and inserts them into fact_ticket_daily.

-- import pandas as pd
-- import oracledb
--
-- conn = oracledb.connect(
--     user="",
--     password="",
--     dsn=""
-- )
--
-- tickets = pd.read_sql("""
--     SELECT ticket_id,
--            title,
--            status,
--            priority,
--            created_at,
--            resolved_at,
--            assigned_to
--     FROM tickets
-- """, conn)
--
-- assignments = pd.read_sql("""
--     SELECT ticket_id,
--            assigned_to,
--            valid_from,
--            valid_to
--     FROM ticket_assignments
-- """, conn)
--
-- def find_agent(ticket_id, event_time):
--     if pd.isna(event_time):
--         return None
--
--     rows = assignments[
--         (assignments["TICKET_ID"] == ticket_id) &
--         (assignments["VALID_FROM"] <= event_time) &
--         (
--             assignments["VALID_TO"].isna() |
--             (assignments["VALID_TO"] > event_time)
--         )
--     ]
--
--     if rows.empty:
--         return None
--
--     return rows.iloc[0]["ASSIGNED_TO"]
--
--
-- created_rows = []
--
-- for _, row in tickets.iterrows():
--     created_agent = find_agent(row["TICKET_ID"], row["CREATED_AT"])
--
--     created_rows.append({
--         "date_key": int(row["CREATED_AT"].strftime("%Y%m%d")),
--         "agent_key": int(created_agent),
--         "status": row["STATUS"],
--         "priority": row["PRIORITY"],
--         "tickets_created": 1,
--         "tickets_resolved": 0
--     })
--
--
-- resolved_rows = []
--
-- for _, row in tickets.dropna(subset=["RESOLVED_AT"]).iterrows():
--     resolved_agent = find_agent(row["TICKET_ID"], row["RESOLVED_AT"])
--
--     resolved_rows.append({
--         "date_key": int(row["RESOLVED_AT"].strftime("%Y%m%d")),
--         "agent_key": int(resolved_agent),
--         "status": row["STATUS"],
--         "priority": row["PRIORITY"],
--         "tickets_created": 0,
--         "tickets_resolved": 1
--     })
--
--
-- fact = pd.DataFrame(created_rows + resolved_rows)
--
-- fact = fact.groupby(
--     ["date_key", "agent_key", "status", "priority"],
--     as_index=False
-- ).sum()
--
-- cursor = conn.cursor()
--
-- cursor.execute("DELETE FROM fact_ticket_daily")
--
-- for _, row in fact.iterrows():
--     cursor.execute("""
--         INSERT INTO fact_ticket_daily (
--             date_key,
--             agent_key,
--             status,
--             priority,
--             tickets_created,
--             tickets_resolved
--         )
--         VALUES (:1, :2, :3, :4, :5, :6)
--     """, (
--         int(row["date_key"]),
--         int(row["agent_key"]),
--         row["status"],
--         row["priority"],
--         int(row["tickets_created"]),
--         int(row["tickets_resolved"])
--     ))
--
-- conn.commit()
-- cursor.close()
-- conn.close()


-- Step 7 — Verify

SELECT
    f.date_key,
    d.agent_name,
    d.team,
    f.status,
    f.priority,
    f.tickets_created,
    f.tickets_resolved
FROM fact_ticket_daily f
JOIN dim_agent d
    ON f.agent_key = d.agent_key
ORDER BY f.date_key, d.agent_name;