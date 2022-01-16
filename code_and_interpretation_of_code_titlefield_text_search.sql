--First run this line of code at the beginning in order to interact with the database test
psql test

--Create table 'Movies 'if not exists
CREATE TABLE IF NOT EXISTS movies (
url text,
title text,
ReleaseDate text,
Distributor text,
Starring text,
Summary text,
Director text,
Genre text,
Rating text,
Runtime text,
Userscore text,
Metascore text,
scoreCounts text
);

--Copy the scraped data from the MetaCritic website into the movies table
\copy movies FROM '/home/pi/RSL/moviesFromMetacritic.csv' delimiter ';' csv header;

--SELECT all the movies where the url, or the name of the movies = interstellar.
SELECT * FROM movies where url='interstellar';

--Clean the data in the 'title field' by adding a column, called lexemesTitle. This should make sure that the entire title column is better readable, as stopwords are removed.
--Furthermore, the title text can now be tokenized to make sure that other movies can be found that contain the same sort of words within the title text. 
ALTER TABLE movies
ADD column IF NOT EXISTS lexemestitle tsvector;
UPDATE movies
SET lexemestitle = to_tsvector(title);

--Search for movies about the title includes sci-fi: 
SELECT url FROM movies WHERE lexemestitle @@ to_tsquery('sci-fi');

--Add a rank to the movies based on what the tsvector is appointed to. 
ALTER TABLE movies ADD column IF NOT EXISTS rank float4;

--In this case, the movies with the same title vectors will be provided in descending order.
UPDATE movies
SET rank = ts_rank(lexemestitle,plainto_tsquery(
(
SELECT title FROM movies WHERE url='interstellar'
)
));

--Create a new table if not exists, recommendationsBasedOntitleField where the vectors in the titlefield have to be the same as the vectors in the titlefield of interstellar. 
--Summaries of movies with the same vectors in the titlefield will be listed on top in descending order with maximum limit of 50. As there are no other movies with the same title, which is logic, this output is not very interesting. The results of the starring, and summaryfield should provide better results.
CREATE TABLE IF NOT EXISTS recommendationsBasedOntitleField AS
SELECT url, rank FROM movies WHERE rank >-1 ORDER BY rank DESC LIMIT 50;

--Copy this table into a new file called top50recommendations_titlefield. 
\COPY (SELECT * FROM recommendationsBasedOntitleField) to '/home/pi/RSL/top50recommendations_titlefield.csv' with CSV;

