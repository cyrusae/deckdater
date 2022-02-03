CREATE PROCEDURE carpentry 
AS
SELECT name, id, released_at, set 
 INTO cards 
 FROM bulk 
 WHERE reprint = 'false' 
  AND multiverse_ids IS NOT NULL
GO;

--How best to break this functionality down into saved procedures? What works better in JS vs SQL? 

CREATE PROCEDURE deckcheck @entries nvarchar(500)
AS 
CREATE TABLE #thisDeck 
SELECT name, released_at, set 
 INTO thisDeck
 FROM cards
 WHERE name LIKE @entries
GO;

CREATE PROCEDURE carbon 
AS 
SELECT MAX(released_at) FROM thisDeck
--how (or whether) to define that as a variable we have as a takeaway here?
GO;
