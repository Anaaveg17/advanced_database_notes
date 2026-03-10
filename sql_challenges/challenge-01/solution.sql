--Ex 1
SELECT title FROM movies;

SELECT director FROM movies;

SELECT title, director FROM movies;

SELECT title, year FROM movies;

SELECT * FROM movies;

--Ex 2.
SELECT title FROM movies WHERE id = 6;

SELECT title FROM movies WHERE year BETWEEN 2000 AND 2010;

SELECT title FROM movies WHERE year NOT BETWEEN 2000 AND 2010;

SELECT title FROM movies WHERE  id IN(1,2,3,4,5);

--Ex 3
SELECT title FROM movies WHERE title LIKE "Toy Story%";

SELECT title FROM movies WHERE director = "John Lasseter";

SELECT title, director FROM movies WHERE director != "John Lasseter";

SELECT title FROM movies WHERE title LIKE "WALL-%";

--Ex 4
SELECT distinct director FROM movies ORDER BY director ASC;

SELECT title FROM movies ORDER BY Year DESC LIMIT 4;

SELECT title FROM movies ORDER BY title ASC LIMIT 5;

SELECT title FROM movies ORDER BY title ASC LIMIT 5 OFFSET 5;

--Ex 5 
SELECT city, Population FROM north_american_cities WHERE country = 'Canada';

SELECT city FROM north_american_cities WHERE country = 'United States' ORDER BY Latitude DESC;

SELECT city, Longitude FROM north_american_cities WHERE Longitude < -87.629798 ORDER BY Longitude ASC;

SELECT city, Population FROM north_american_cities WHERE country = 'Mexico' ORDER BY Population DESC LIMIT 2;

SELECT * FROM north_american_cities WHERE Country == 'United States' ORDER BY Population DESC LIMIT 2 OFFSET 2;
