use deckdater_dev 
go 

declare @haveguys int, @whys int 
set @haveguys = (select Count(PK) from GUYTESTER)
set @whys = Cast((@haveguys/1000) as int)
print @whys 

set @whys = 5
set NOCOUNT ON 
print SYSDATETIME()
while @whys > 0 
 BEGIN 
 print @whys 
 print 'Guying...'
 exec dbo.TRY_guyer NULL 
 print SYSDATETIME()
 --WAITFOR DELAY '00:00:05'
 set @whys = @whys - 1 
 END 