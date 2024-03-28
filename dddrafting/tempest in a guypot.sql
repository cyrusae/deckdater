/*insert into dbo.GUYTESTER (UserDOB, Email, FirstName, LastName)
 select DOB, Email, Fname, Lname from dbo.LOAD_OF_GUYS 
ALTER DATABASE deckdater_dev 
 set READ_COMMITTED_SNAPSHOT ON 
GO 
*/

use deckdater_dev 
GO 

set TRANSACTION ISOLATION LEVEL SNAPSHOT 
GO 

insert into dbo.GUYTESTER (UserDOB, Email, FirstName, LastName)
 select Top 100 DOB, Email, Fname, Lname from LOAD_OF_GUYS 
 order by DOB asc 

set NOCOUNT ON 

declare @chunks int 
set @chunks = (select Cast(Count(Email)/1000 as int) from LOAD_OF_GUYS) + 1
print @chunks 

select Top(10000) DOB, Email, Fname, Lname into #Atempguys from LOAD_OF_GUYS 
select * into #Atemperguys 
 from #Atempguys where 1 = 0 
select * into #Atempestguys 
 from #Atempguys where 1 = 0

declare @bits int 
set @bits = 5
print (@chunks - @bits)
while @bits > 0 
BEGIN 

insert into #Atempestguys (DOB, Email, Fname, Lname)
 select Top 50 DOB, Email, Fname, Lname from #Atempguys
 order by DOB asc 

insert into #Atemperguys (DOB, Email, Fname, Lname)
 select DOB, Email, Fname, Lname from #Atempguys 
 except select DOB, Email, Fname, Lname from #Atempestguys 

insert into dbo.GUYTESTER (UserDOB, Email, FirstName, LastName)
 select DOB, Email, Fname, Lname from #Atempestguys

truncate table #Atempestguys 
truncate table #Atempguys 
insert into #Atempguys (DOB, Email, Fname, Lname) 
 select DOB, Email, Fname, Lname from #Atemperguys 
truncate table #Atemperguys 
set @bits = @bits - 1 
END 



select * from #Atemperguys where Lname = 'Aid'

select * from #Atempguys 

drop table #Atempguys 
drop table #Atemperguys 
drop table #Atempestguys 

select * from TEST_USER 

select * from GUYTESTER 

select Top(10) * into #Atempguys from LOAD_OF_GUYS

select * from #Atempguys

insert into dbo.GUYTESTER (UserDOB, Email, FirstName, LastName)
 select DOB, Email, Fname, Lname from #Atempguys

insert into dbo.GUYTESTER (UserDOB, Email, FirstName, LastName)
 select DOB, Email, Fname, Lname from LOAD_OF_GUYS

select * from TEST_USER

delete from TEST_USER where DateCreated is NULL 

truncate table GUYTESTER 
select * from GUYTESTER 

declare @haveguys int, @whys int 
set @haveguys = (select Count(PK) from GUYTESTER)
set @whys = Cast((@haveguys/1000) as int)

while @whys > 0 
 BEGIN 
 exec dbo.TRY_guyer 
 set @whys = @whys - 1 
 END 
