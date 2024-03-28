/* create nonclustered index ix_BetterGuys on LOAD_OF_GUYS (DOB, Email, Fname, Lname)
GO 
alter table LOAD_OF_GUYS 
 Add PK int Identity(1,1)
alter table LOAD_OF_GUYS 
 Add Constraint SANE_PK_FOR_GUYS PRIMARY KEY (PK)
GO 

declare @nonexisting as table( 
 DOB date,
 Email varchar(200),
 Fname varchar(25),
 Lname varchar(25)
)
declare @existing as table( 
 DOB date,
 Email varchar(200),
 Fname varchar(25),
 Lname varchar(25)
)

insert into @existing (DOB, Email, Fname, Lname) 
 select DOB, UT.Email as Email, Fname, Lname 
 from tblUSER UT 
 join LOAD_OF_GUYS L on UT.UserDOB = L.DOB 
   and UT.Email = L.Email 
   and UT.FirstName = L.Fname 
   and UT.LastName = L.Lname 
*/

--select * from ##GUYS 
/*
drop table ##GUYS 
GO */



use deckdater_dev 
GO 
--drop table ##GUYS 
select DOB, Email, Fname, Lname into ##GUYS from LOAD_OF_GUYS where 1 = 0
alter table ##GUYS 
 Add PK int Identity(1,1)
GO 
alter table ##GUYS 
 ADD Constraint TempGuysPK PRIMARY KEY (PK)
GO 
create nonclustered index ix_TEMP_GUYS on ##GUYS (DOB, Email, Fname, Lname)
GO
insert into ##GUYS (DOB, Email, Fname, Lname)
select DOB, Email, Fname, Lname from LOAD_OF_GUYS 
 except (select UserDOB, Email, FirstName, LastName from tblUSER)
GO 
update ##GUYS 
 set Email = NULL 
 where Email = 'NULL'
delete from ##GUYS where Email is NULL 
GO 
 /*
insert into ##GUYS (DOB, Email, Fname, Lname) 
select Top(1000) DOB, Email, Fname, Lname from LOAD_OF_GUYS 


drop trigger try_trytry 
*/ 

use deckdater_dev 
GO 

create OR alter trigger try_trytry on GUYTRYER 
 after INSERT 
 as BEGIN 
 if @@ROWCOUNT < 1 RETURN;
 set NOCOUNT ON
 declare @affected int, @aguy int, @guyDOB date, @guymail varchar(200), @guyFname varchar(25), @guyLname varchar(25)
 select * into #newsies from inserted 
 alter table #newsies 
  Add Constraint PK_temp_NewGuys PRIMARY KEY (PK)
 set @affected = (select Count(PK) from #newsies)
 while @affected > 0 
  BEGIN 
   set @aguy = (select Min(PK) from #newsies)
   select @guyDOB = UserDOB, 
     @guyFname = FirstName, 
     @guyLname = LastName, 
     @guymail = Email 
     from #newsies where PK = @aguy
   exec dbo.u_NewUser 
    @UserDOB = @guyDOB,
    @Email = @guymail, 
    @FirstName = @guyFname,
    @LastName = @guyLname,
    @UserName = NULL,
    @DisplayName = NULL 
   delete from #newsies where PK = @aguy 
   delete from GUYTRYER where PK = @aguy 
   set @affected = @affected - 1 
  END 
 END 
GO 

--select * from ##GUYS 
declare @guysleft int 
set @guysleft = (select Count(PK) from ##GUYS)
print @guysleft/1000
--drop index ix_TEMP_GUYS on ##GUYS 

SELECT CASE  
          WHEN transaction_isolation_level = 1 
             THEN 'READ UNCOMMITTED' 
          WHEN transaction_isolation_level = 2 
               AND is_read_committed_snapshot_on = 1 
             THEN 'READ COMMITTED SNAPSHOT' 
          WHEN transaction_isolation_level = 2 
               AND is_read_committed_snapshot_on = 0 THEN 'READ COMMITTED' 
          WHEN transaction_isolation_level = 3 
             THEN 'REPEATABLE READ' 
          WHEN transaction_isolation_level = 4 
             THEN 'SERIALIZABLE' 
          WHEN transaction_isolation_level = 5 
             THEN 'SNAPSHOT' 
          ELSE NULL
       END AS TRANSACTION_ISOLATION_LEVEL 
FROM   sys.dm_exec_sessions AS s
       CROSS JOIN sys.databases AS d
WHERE  session_id = @@SPID
  AND  d.database_id = DB_ID();

--select Count(UserID) from tblUSER 
--select nrow from META_ENV_VAR where NameOfTable = 'tblUSER'

--select Count(PK) from ##GUYS where Email is NULL 
select count(PK) from ##GUYS 
select * from GUYTRYER 

declare @mini int, @maxi int, @rep int, @startprn int, @stopprn int 
set NOCOUNT ON 
set @rep = 10
set @mini = (select Min(PK) from ##GUYS)
while @rep > 0 
BEGIN 
set @maxi = @mini + 1000
--begin tran 
--begin tran 
insert into GUYTRYER (UserDOB, Email, FirstName, LastName)
 select DOB, Email, Fname, Lname from ##GUYS 
  where PK < /* between @mini and */ @maxi 
--commit 
delete from ##GUYS where PK /* between @mini and */ < @maxi 
--commit 
set @mini = @maxi /* + 1 */
set @rep = @rep - 1 
END 

drop table ##GUYS 
 /*

set @stopprn = (select Count(PK) from ##GUYS)
print (@startprn - @stopprn)
  except (select DOB, UT.Email as Email, Fname, Lname 
  from tblUSER UT 
  join ##GUYS L on UT.UserDOB = L.DOB 
    and UT.Email = L.Email 
    and UT.FirstName = L.Fname 
    and UT.LastName = L.Lname )


GO 

select Top(10) * from LOAD_OF_GUYS 

drop table ##GUYLOADER 
drop table #oldguys 



select * into #oldguys from ##GUYS 

truncate table ##GUYS */

insert into ##GUYS (DOB, Email, Fname, Lname) 
 select DOB, Email, Fname, Lname from --##GUYLOADER 
  LOAD_OF_GUYS except (select UserDOB, Email, FirstName, LastName from tblUSER)


select Min(PK) from ##GUYS 