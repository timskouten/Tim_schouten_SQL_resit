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

--Clean the data in the 'summary field' by adding a column, called lexemesSummary. This should make sure that the entire Summary column is better readable, as stopwords are removed.
--Furthermore, the summary text can now be tokenized to make sure that other movies can be found that contain the same sort of words within the summary text. 
ALTER TABLE movies
ADD column IF NOT EXISTS lexemesSummary tsvector;
UPDATE movies
SET lexemesSummary = to_tsvector(Summary);

--Search for movies about the genre science fiction: 
SELECT url FROM movies WHERE lexemesSummary @@ to_tsquery('sci-fi');

--Add a rank to the movies based on what the tsvector is appointed to. 
ALTER TABLE movies ADD column IF NOT EXISTS rank float4;

--In this case, the movies with the same summary vectors will be provided in descending order.
UPDATE movies
SET rank = ts_rank(lexemesSummary,plainto_tsquery(
(
SELECT Summary FROM movies WHERE url='interstellar'
)
));

--Create a new table if not exists, recommendationsBasedOnSummaryField where the vectors in the summaryfield have to be the same as the vectors in the Summaryfield of interstellar. 
--Summaries of movies with the same vectors in the summaryfield will be listed on top in descending order with maximum limit of 50. 
CREATE TABLE IF NOT EXISTS recommendationsBasedOnSummaryField AS
SELECT url, rank FROM movies WHERE rank > 0.95 ORDER BY rank DESC LIMIT 50;

--Copy this table into a new file called top50recommendations_summaryfield. 
\COPY (SELECT * FROM recommendationsBasedOnSummaryField) to '/home/pi/RSL/top50recommendations_Summaryfield.csv' with CSV;
 
--I would say that the outcome of this file somehow makes sense, as some of these movies are also sci-fi. However, not all of them seem to me as the same type of movies. Nevertheless, I think that the other movies also seem interesting, as these are somehow related to the original pick, interstellar, as the genre can be the same, especially when looking at the movies that are provided in the top 10 of the results file. 
