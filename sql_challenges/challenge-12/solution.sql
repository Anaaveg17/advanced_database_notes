-- ============================================================
-- Lesson 07: KPI Dashboards — Class Exercises
-- File: 06_exercises.sql
-- ============================================================

-- PART A: The KPI Contract (Conceptual)


-- EXERCISE 1: Define "Team Velocity"

-- 1. Business question: Which team is finishing the most work after adjusting for team size?
-- 2. Definition: velocity = completed tasks / team members / 19 days.
--    The query joins teams to users and tasks. LEFT JOIN keeps teams even if they have no tasks.
-- 3. Edge cases: teams with no completed work should show 0 or NULL safely, not break the query.
--    NULLIF prevents division by zero when a team has no members.
-- 4. Unit: completed tasks per person per day.
-- 5. Misleading if: tasks have different difficulty but are counted the same.
--    Since there are no story points, this is only an approximate velocity metric.

WITH velocity AS (
    SELECT
        t.name AS team_name,
        COUNT(DISTINCT u.id) AS member_count,
        COUNT(CASE WHEN ts.status = 'completed' THEN 1 END) AS completed_tasks,
        ROUND(
            COUNT(CASE WHEN ts.status = 'completed' THEN 1 END)
            / NULLIF(COUNT(DISTINCT u.id), 0)
            / 19,
            3
        ) AS velocity_per_person_per_day
    FROM teams t
    LEFT JOIN users u ON u.team_id = t.id
    LEFT JOIN tasks ts ON ts.assigned_to = u.id
    GROUP BY t.id, t.name
),
avg_velocity AS (
    SELECT AVG(velocity_per_person_per_day) AS overall_avg
    FROM velocity
)
SELECT
    v.team_name,
    v.member_count,
    v.completed_tasks,
    v.velocity_per_person_per_day,
    CASE
        WHEN v.velocity_per_person_per_day < a.overall_avg THEN 'Below Average'
        ELSE 'At or Above Average'
    END AS velocity_flag
FROM velocity v
CROSS JOIN avg_velocity a
ORDER BY v.velocity_per_person_per_day DESC;


-- EXERCISE 2: Define "On-Time Delivery Rate"

-- 1. Business question: What percent of finished tasks were delivered by their deadline?
-- 2. Definition: a task is on time when TRUNC(completed_at) <= due_date.
--    Only completed tasks with completed_at and due_date are included.
-- 3. Edge cases: tasks with no due date are ignored because they cannot be judged.
--    Finishing any time during the due date counts as on time.
-- 4. Unit: percentage and average lateness in hours.
-- 5. Misleading if: deadlines are not consistent or are set too far in the future.

SELECT
    priority,
    COUNT(*) AS total_completed,
    COUNT(CASE WHEN TRUNC(completed_at) <= due_date THEN 1 END) AS on_time_count,
    ROUND(
        COUNT(CASE WHEN TRUNC(completed_at) <= due_date THEN 1 END)
        * 100.0 / NULLIF(COUNT(*), 0),
        1
    ) AS on_time_rate_pct,
    ROUND(AVG(
        CASE WHEN TRUNC(completed_at) > due_date THEN
            EXTRACT(DAY FROM (completed_at - CAST(due_date AS TIMESTAMP))) * 24 +
            EXTRACT(HOUR FROM (completed_at - CAST(due_date AS TIMESTAMP)))
        END
    ), 1) AS avg_lateness_hours
FROM tasks
WHERE status = 'completed'
  AND completed_at IS NOT NULL
  AND due_date IS NOT NULL
GROUP BY priority
ORDER BY CASE priority
              WHEN 'critical' THEN 1
              WHEN 'high' THEN 2
              WHEN 'medium' THEN 3
              WHEN 'low' THEN 4
          END;


-- PART B: Improve the Class KPIs


-- EXERCISE 3: Improve "Tasks per Team" (KPI 2 from class)

-- Problem:
-- Counting every task together is not enough because completed and cancelled tasks
-- do not represent current work. This version separates total work from active work.

SELECT
    t.name AS team_name,
    COUNT(ts.id) AS total_tasks,
    COUNT(CASE WHEN ts.status IN ('open','in_progress','blocked') THEN 1 END) AS active_tasks,
    ROUND(
        COUNT(CASE WHEN ts.status = 'completed' THEN 1 END) * 100.0
        / NULLIF(COUNT(CASE WHEN ts.status != 'cancelled' THEN 1 END), 0),
        1
    ) AS completion_rate_pct,
    CASE
        WHEN COUNT(CASE WHEN ts.status IN ('open','in_progress','blocked') THEN 1 END) > 10
            THEN 'Overloaded'
        WHEN COUNT(CASE WHEN ts.status IN ('open','in_progress','blocked') THEN 1 END) >= 5
            THEN 'Healthy'
        ELSE 'Underutilized'
    END AS health_score
FROM teams t
LEFT JOIN users u ON u.team_id = t.id
LEFT JOIN tasks ts ON ts.assigned_to = u.id
GROUP BY t.id, t.name
ORDER BY active_tasks DESC;


-- EXERCISE 4: Improve "Average Resolution Time" (KPI 5 from class)

-- Problem:
-- One average for all completed tasks hides the difference between priorities.
-- A critical task and a low priority task should not be evaluated with the same expectation.

-- Edge case:
-- If a priority only has one completed task, the result is still shown but marked as low confidence.

SELECT
    priority,
    COUNT(*) AS sample_size,
    ROUND(AVG(
        EXTRACT(DAY FROM (completed_at - created_at)) * 24 +
        EXTRACT(HOUR FROM (completed_at - created_at)) +
        EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
    ), 1) AS avg_resolution_hours,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY
        EXTRACT(DAY FROM (completed_at - created_at)) * 24 +
        EXTRACT(HOUR FROM (completed_at - created_at)) +
        EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
    ), 1) AS median_resolution_hours,
    ROUND(MIN(
        EXTRACT(DAY FROM (completed_at - created_at)) * 24 +
        EXTRACT(HOUR FROM (completed_at - created_at)) +
        EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
    ), 1) AS fastest_hours,
    ROUND(MAX(
        EXTRACT(DAY FROM (completed_at - created_at)) * 24 +
        EXTRACT(HOUR FROM (completed_at - created_at)) +
        EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
    ), 1) AS slowest_hours,
    CASE priority
        WHEN 'critical' THEN 24
        WHEN 'high' THEN 72
        WHEN 'medium' THEN 168
        WHEN 'low' THEN 336
    END AS sla_target_hours,
    CASE
        WHEN ROUND(AVG(
            EXTRACT(DAY FROM (completed_at - created_at)) * 24 +
            EXTRACT(HOUR FROM (completed_at - created_at)) +
            EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
        ), 1) <= CASE priority
                     WHEN 'critical' THEN 24
                     WHEN 'high' THEN 72
                     WHEN 'medium' THEN 168
                     WHEN 'low' THEN 336
                 END
        THEN 'MET'
        ELSE 'MISSED'
    END AS sla_status,
    CASE WHEN COUNT(*) = 1 THEN 'Low confidence (n=1)' ELSE NULL END AS warning
FROM tasks
WHERE status = 'completed'
  AND completed_at IS NOT NULL
GROUP BY priority
ORDER BY CASE priority
              WHEN 'critical' THEN 1
              WHEN 'high' THEN 2
              WHEN 'medium' THEN 3
              WHEN 'low' THEN 4
          END;


-- EXERCISE 5: Improve "Overdue Tasks" (KPI 7 from class)

-- Problem:
-- A simple overdue count does not explain who owns the work or how serious it is.
-- This report gives the task, assignee, team, priority, days overdue, and severity.

-- Part 1: detailed report

SELECT
    ts.title,
    u.full_name AS assignee,
    t.name AS team,
    ts.priority,
    ts.due_date,
    TRUNC(SYSDATE) - ts.due_date AS days_overdue,
    CASE
        WHEN ts.priority = 'critical' THEN 'CRITICAL'
        WHEN ts.priority = 'high' AND TRUNC(SYSDATE)-ts.due_date > 2 THEN 'HIGH'
        WHEN ts.priority = 'medium' AND TRUNC(SYSDATE)-ts.due_date > 5 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS severity
FROM tasks ts
JOIN users u ON u.id = ts.assigned_to
JOIN teams t ON t.id = u.team_id
WHERE ts.due_date < TRUNC(SYSDATE)
  AND ts.status NOT IN ('completed', 'cancelled')
  AND ts.due_date IS NOT NULL
ORDER BY
    CASE
        WHEN ts.priority = 'critical' THEN 1
        WHEN ts.priority = 'high' AND TRUNC(SYSDATE)-ts.due_date > 2 THEN 2
        WHEN ts.priority = 'medium' AND TRUNC(SYSDATE)-ts.due_date > 5 THEN 3
        ELSE 4
    END,
    TRUNC(SYSDATE) - ts.due_date DESC;


-- Part 2: summary by severity using ROLLUP

SELECT
    CASE
        WHEN ts.priority = 'critical' THEN 'CRITICAL'
        WHEN ts.priority = 'high' AND TRUNC(SYSDATE)-ts.due_date > 2 THEN 'HIGH'
        WHEN ts.priority = 'medium' AND TRUNC(SYSDATE)-ts.due_date > 5 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS severity,
    COUNT(*) AS overdue_count,
    ROUND(AVG(TRUNC(SYSDATE) - ts.due_date), 1) AS avg_days_overdue
FROM tasks ts
WHERE ts.due_date < TRUNC(SYSDATE)
  AND ts.status NOT IN ('completed', 'cancelled')
  AND ts.due_date IS NOT NULL
GROUP BY ROLLUP(
    CASE
        WHEN ts.priority = 'critical' THEN 'CRITICAL'
        WHEN ts.priority = 'high' AND TRUNC(SYSDATE)-ts.due_date > 2 THEN 'HIGH'
        WHEN ts.priority = 'medium' AND TRUNC(SYSDATE)-ts.due_date > 5 THEN 'MEDIUM'
        ELSE 'LOW'
    END
);


-- PART C: The "Bad KPI" Challenge


-- EXERCISE 6: Fix the "Productivity Score"

-- PROBLEM:
-- It counts assigned tasks instead of actual finished work.
-- A user with many open tasks can look productive even if nothing is completed.
-- It also does not consider priority, so all tasks are treated equally.

SELECT
    u.full_name,
    COUNT(CASE WHEN ts.status = 'completed' THEN 1 END) AS completed_tasks,
    SUM(CASE
        WHEN ts.status = 'completed' AND ts.priority = 'critical' THEN 5
        WHEN ts.status = 'completed' AND ts.priority = 'high' THEN 4
        WHEN ts.status = 'completed' AND ts.priority = 'medium' THEN 3
        WHEN ts.status = 'completed' AND ts.priority = 'low' THEN 2
        ELSE 0
    END) AS weighted_score,
    ROUND(
        SUM(CASE
            WHEN ts.status = 'completed' AND ts.priority = 'critical' THEN 5
            WHEN ts.status = 'completed' AND ts.priority = 'high' THEN 4
            WHEN ts.status = 'completed' AND ts.priority = 'medium' THEN 3
            WHEN ts.status = 'completed' AND ts.priority = 'low' THEN 2
            ELSE 0
        END)
        / NULLIF(TRUNC(SYSDATE) - TRUNC(MIN(ts.created_at)), 0),
        3
    ) AS weighted_score_per_day
FROM users u
LEFT JOIN tasks ts ON ts.assigned_to = u.id
GROUP BY u.id, u.full_name
ORDER BY weighted_score_per_day DESC NULLS LAST;


-- EXERCISE 7: Fix the "Team Efficiency"

-- PROBLEM:
-- AVG(ts.id) has no useful meaning because task IDs are just identifiers.
-- It does not measure speed, completion, or quality.
-- A better measure is the percentage of tasks completed by each team.

SELECT
    t.name AS team_name,
    COUNT(ts.id) AS total_tasks,
    COUNT(CASE WHEN ts.status = 'completed' THEN 1 END) AS completed_tasks,
    ROUND(
        COUNT(CASE WHEN ts.status = 'completed' THEN 1 END) * 100.0
        / NULLIF(COUNT(ts.id), 0),
        1
    ) AS completion_ratio_pct
FROM teams t
LEFT JOIN users u ON u.team_id = t.id
LEFT JOIN tasks ts ON ts.assigned_to = u.id
GROUP BY t.id, t.name
ORDER BY completion_ratio_pct DESC NULLS LAST;


-- EXERCISE 8: Fix the "Urgency Index"

-- PROBLEM:
-- Priority is text, so it cannot be multiplied by a number.
-- Due date should be converted into a useful urgency value.

SELECT title,
       priority,
       due_date,

       CASE priority
           WHEN 'critical' THEN 5
           WHEN 'high' THEN 4
           WHEN 'medium' THEN 3
           WHEN 'low' THEN 2
       END
       +
       (
           CASE
               WHEN due_date < TRUNC(SYSDATE)
               THEN 4
               ELSE 0
           END
       ) AS urgency_score

FROM tasks

ORDER BY urgency_score DESC;


-- Extra Chart Query

SELECT TRUNC(completed_at) AS completion_date,
       COUNT(*) AS tasks_completed
FROM tasks
WHERE status = 'completed'
  AND completed_at IS NOT NULL
GROUP BY TRUNC(completed_at)
ORDER BY completion_date;