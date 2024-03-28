use deckdater_dev 
go 

declare @haveguys int, @whys int 
set @haveguys = (select Count(PK) from GUYTESTER)
set @whys = Cast((@haveguys/1000) as int)

while @whys > 0 
 BEGIN 
 exec dbo.TRY_guyer 
 set @whys = @whys - 1 
 END 
