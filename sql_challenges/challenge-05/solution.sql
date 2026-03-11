-- 1

select distinct * from 
(
    select colour from my_brick_collection
    union all
    select colour from your_brick_collection
    order by colour
);

-- 1.1

select shape from my_brick_collection
union all
select shape from your_brick_collection
order  by shape;

-- 2

select shape from my_brick_collection
minus
select shape from your_brick_collection;

-- 2.1
select colour from my_brick_collection
intersect
select colour from your_brick_collection
order  by colour;

