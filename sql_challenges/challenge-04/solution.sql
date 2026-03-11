-- 1
select b.*,
       count(*) over 
       (
         partition by shape
       ) bricks_per_shape,
       median ( weight ) over 
       (
         partition by shape
       ) median_weight_per_shape
from   bricks b
order  by shape, weight, brick_id;

-- 1.1 
select b.brick_id, b.weight,
       round ( avg ( weight ) over 
       (
         order by brick_id
       ), 2 ) running_average_weight
from   bricks b
order  by brick_id;


-- 2
The count of rows with the same weight as the current and one value following
select b.*,
       min ( colour ) over 
       (
         order by brick_id
         rows between 2 preceding and 1 preceding
       ) first_colour_two_prev,
       count (*) over 
       (
         order by weight
         range between current row and 1 following
       ) count_values_this_and_next
from   bricks b
order  by weight;


-- 2.1
with totals as 
(
  select b.*,
         sum ( weight ) over 
         (
           partition by shape
         ) weight_per_shape,
         sum ( weight ) over (order by brick_id) running_weight_by_id
  from   bricks b
)
select * from totals
where  weight_per_shape > 4 and running_weight_by_id > 4
order  by brick_id



-- Interview 

WITH ranked_salary AS 
(
  SELECT name, salary, department_id,
    DENSE_RANK() OVER 
    (
      PARTITION BY department_id ORDER BY salary DESC
    ) AS ranking
  FROM employee
)
SELECT  d.department_name, s.name, s.salary
FROM ranked_salary AS s
JOIN department AS d
ON s.department_id = d.department_id
WHERE s.ranking <= 3
ORDER BY d.department_name ASC, s.salary DESC, s.name ASC;