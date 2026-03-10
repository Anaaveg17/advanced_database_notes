-- Ex 6

-- 1 
FROM movies
  JOIN boxoffice
    ON movies.id = boxoffice.movie_id;

-- 2
SELECT title, domestic_sales, international_sales 
FROM movies
  JOIN boxoffice
    ON movies.id = boxoffice.movie_id;

-- 3
SELECT title, rating
FROM movies
  JOIN boxoffice
    ON movies.id = boxoffice.movie_id
ORDER BY rating DESC;
 

-- Ex 7

-- 1
SELECT DISTINCT building FROM employees;

-- 2
SELECT * FROM buildings;

-- 3
SELECT DISTINCT building_name, role 
FROM buildings 
  LEFT JOIN employees
    ON building_name = building;


-- Extra
SELECT p.page_id 
FROM pages p
LEFT JOIN page_likes pl
ON p.page_id = pl.page_id
WHERE pl.user_id IS NULL
ORDER BY page_id;