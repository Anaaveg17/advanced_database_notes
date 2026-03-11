-- 10.

--ex1 
SELECT MAX(years_employed) FROM employees;

--ex2
SELECT role, AVG(years_employed)
FROM employees
GROUP BY role;

--ex3
SELECT building, SUM(years_employed) 
FROM employees
GROUP BY building;


-- 11

-- ex1
SELECT role, COUNT(*) 
FROM employees
WHERE role = "Artist";

--ex2
SELECT role, COUNT(*)
FROM employees
GROUP BY role;

--ex3
SELECT role, SUM(years_employed)
FROM employees
GROUP BY role
HAVING role = "Engineer";


-- Try It 4
select count (distinct shape) number_of_shapes,
       stddev (distinct weight) distinct_weight_stddev
from   bricks;

-- Try It 6
select shape, sum (weight) shape_weight
from   bricks
group  by shape;

-- Try It 8
select shape, sum (weight)
from   bricks
group  by shape
having sum (weight) < 4;



