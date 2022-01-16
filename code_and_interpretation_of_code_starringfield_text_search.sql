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

--Clean the data in the 'starring field' by adding a column, called lexemesStarring. This should make sure that the entire Starring column is better readable, as stopwords are removed.
--Furthermore, the starring text can now be tokenized to make sure that other movies can be found that contain the same sort of words within the starring text. 
ALTER TABLE movies
ADD column IF NOT EXISTS lexemesStarring tsvector;
UPDATE movies
SET lexemesStarring = to_tsvector(Starring);

--Add a rank to the movies based on what the tsvector is appointed to (in case that it does not yet exist). 
ALTER TABLE movies ADD column IF NOT EXISTS rank float4;

--In this case, the movies with the same starring vectors will be provided in descending order.
UPDATE movies
SET rank = ts_rank(lexemesstarring,plainto_tsquery(
(
SELECT starring FROM movies WHERE url='interstellar'
)
));

--Create a new table if not exists, recommendationsBasedOnStarringField where the vectors in the starringfield have to be the same as the vectors in the starringfield of interstellar. 
--movies with the same vectors in the starringfield will be listed on top in descending order with maximum limit of 50. As there are no other movies with the exactly the same actors, which is logic, this output is not as good as the summary output. 
CREATE TABLE IF NOT EXISTS recommendationsBasedonstarringField AS
SELECT url, rank FROM movies WHERE rank >-1 ORDER BY rank DESC LIMIT 50;

--Copy this table into a new file called top50recommendations_starringfield. 
\COPY (SELECT * FROM recommendationsBasedOnStarringField) to '/home/pi/RSL/top50recommendations_Starringfield.csv' with CSV;
