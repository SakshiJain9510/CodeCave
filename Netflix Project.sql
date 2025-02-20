select * from titles;
select * from credits;

-- A. Data cleaning

-- 1. Creating Copy of original tables 
use netflix_movies_shows;
create table titles_dup like titles;
insert into titles_dup select * from titles;
select * from titles_dup;

use netflix_movies_shows;
create table credits_dup like credits;
insert into credits_dup select * from credits;
select * from credits_dup;

-- 2. Checking for blank / irrelevant values
select distinct d.character from credits_dup d;
select * from credits_dup d where d.character = ''; #9 rows
update credits_dup d
set d.character = null
where d.character = '';

select * from titles_dup where imdb_score = ''; #2 rows
delete from titles_dup where imdb_score = '';

select *
from titles_dup where production_countries = '[]';
update titles_dup 
set production_countries = null
where production_countries = '[]';

select count(*) from titles_dup where seasons =''; #67 rows out of 77 rows
alter table titles_dup drop column seasons;

select * from titles_dup where age_certification = ''; #40 rows
update titles_dup 
set age_certification = null
where age_certification = '';

-- 3. Checking for duplicates
with row_title_cte as(
select * , row_number() over(partition by id, title, type, description, 
release_year, age_certification, runtime, genres, production_countries, 
seasons, imdb_id, imdb_score, imdb_votes, tmdb_popularity,tmdb_score) as rn from titles_dup)
select * from row_title_cte where rn > 1
;

with row_credit_cte as(
select * , row_number() over(partition by d.person_id, d.id, d.name, d.character, d.role) as rn from credits_dup d)
select * from row_credit_cte where rn > 1
;

select * from credits_dup;
select * from titles_dup;

-- B. Exploratory Data Analysis

-- 1. What are the Top 10 movies based on IMDB score?
select id, title, imdb_score from titles_dup
where type = 'MOVIE'
order by imdb_score desc
limit 10;

-- 2. What are the Top 10 shows based on IMDB score?
select id, title, imdb_score from titles_dup
where type = 'SHOW'
order by imdb_score desc
limit 10;

-- 3. What are the average IMDB and TMDB scores for shows and movies? 
select distinct type, Round(avg(imdb_score),2) as Average_IMDB_Score, Round(avg(tmdb_score),2) as Average_TMDB_Score from titles_dup
group by type
order by Average_IMDB_Score desc;

-- 4. What is the count of movies and shows in each decade?
select concat((floor(release_year/10))*10 , 's') as Decade, count(*) as Count_titles from titles_dup
group by concat((floor(release_year/10))*10 , 's')
order by 1;

-- 5. What are the average IMDB and TMDB scores for each production country?
select distinct production_countries,
Round(avg(imdb_score),2) as Average_IMDB_Score, 
Round(avg(tmdb_score),2) as Average_TMDB_Score 
from titles_dup
where production_countries is not null
group by production_countries
order by Average_IMDB_Score desc;

-- 6. What are the average IMDB and TMDB scores for each age certification for shows and movies?
select distinct age_certification,
Round(avg(imdb_score),2) as Average_IMDB_Score, 
Round(avg(tmdb_score),2) as Average_TMDB_Score 
from titles_dup
where age_certification is not null
group by age_certification
order by Average_IMDB_Score desc;

-- 7. What are the 5 most common age certifications for movies?
select age_certification, count(*) as Movie_count from titles_dup
where type = 'MOVIE' and age_certification is not null
group by age_certification
order by Movie_count desc
limit 5;

-- 8. Who are the top 20 actors that appeared the most in movies/shows? 
select distinct name, count(*) as count_titles from credits_dup
where role = 'ACTOR'
group by name
order by count(*) desc, name asc
limit 20;

-- 9. Who are the top 20 directors that directed the most movies/shows? 
select distinct name, count(*) as count_titles from credits_dup
where role = 'DIRECTOR'
group by name
order by count(*) desc, name asc
limit 20;

-- 10. What is the average runtime of movies and TV shows?
select distinct type,
Round(avg(runtime),2) as Average_runtime
from titles_dup
group by type
order by Average_runtime desc;

-- 11. What are the titles and  directors of movies released on or after 1970?
select distinct t.title, c.name, t.release_year
from titles_dup t
join credits_dup c 
on t.id = c.id
where t.type = 'MOVIE'
and t.release_year >=1970
and c.role = 'DIRECTOR'
order by t.release_year desc;

-- 12. Which genres had the most movies? 
select distinct genres, count(*) as count_movies from titles_dup
where type = 'MOVIE'
group by genres
order by count(*) desc
limit 10;

-- 13. List Cast of Actors starred in the 20 most highly rated movies or shows.
with top_rated as(
select id, title, imdb_score from titles_dup
order by imdb_score desc limit 20)
select distinct t.title, 
group_concat(c.name) as Cast
from credits_dup c
join
top_rated t
on c.id = t.id
where c.role = 'ACTOR'
group by t.title;

-- 14. Which actors/actresses played the same character in multiple movies or TV shows? 
select d.name, d.character, count(distinct id) as movie_show_count from credits_dup d
where d.character is not null and d.role = 'ACTOR'
group by  d.name, d.character
having count(distinct id) > 1;

-- 15. What is the average IMDB score for leading actors/actresses in movies or shows?
select distinct d.name,
round(avg(c.imdb_score) over(partition by d.name),2) as average_IMDB_score
from credits_dup d
join
titles_dup c
on d.id = c.id
order by average_IMDB_score desc, d.name asc
limit 10;










