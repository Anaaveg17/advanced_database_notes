--EX 1

--EX 2
WITH ranked AS (
  SELECT
    e.name,
    e.salary,
    e.department_id,
    DENSE_RANK() OVER (
      PARTITION BY e.department_id
      ORDER BY e.salary DESC
    ) AS salary_rank
  FROM employee e
)
SELECT
  d.department_name,
  r.name,
  r.salary
FROM ranked r
JOIN department d
  ON d.department_id = r.department_id
WHERE r.salary_rank <= 3
ORDER BY
  d.department_name ASC,
  r.salary DESC,
  r.name ASC;


  --EX 2

  