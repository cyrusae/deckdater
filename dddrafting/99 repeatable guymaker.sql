use deckdater_dev 
GO 

/*
create type UserNameGenerator as table (
 WordOrder int PRIMARY KEY NONCLUSTERED NOT NULL,
 Word varchar(10))
  with (MEMORY_OPTIMIZED = ON);
*/

create OR alter proc u_NewUser 
 @UserDOB date,
 @Email varchar(200) NULL,
 @FirstName varchar(25) NULL,
 @LastName varchar(25) NULL,
 @UserName varchar(100) NULL,
 @DisplayName varchar(140) NULL 
 as BEGIN 
 if @@ROWCOUNT < 1 RETURN ;
 set NOCOUNT ON 
 declare @UserExists int, @Wordles UserNameGenerator, @NameString varchar(100), @nwordl int, @nstop int, @wspace int, @stspace int, @unstop int, @restoop int, @SK1 int, @SK2 int, @SK3 int, @SK4 int, @S1 varchar(10), @S2 varchar(10), @S3 varchar(10), @S4 varchar(10) 
 declare @Stops as table (
  WordOrder int,
  Word varchar(10),
  DisOrder int)
 if @UserDOB > DateAdd(year, -16, GetDate()) 
  BEGIN 
   print 'GDPR compliance says no users under 16 allowed. Come back later';
   throw 296777, 'Users must be 16 or older. Terminating account creation', 13;
  END 
 if (@Email is NOT NULL) and exists (select UserID from tblUSER where Email = @Email) 
  BEGIN 
   declare @now datetime 
   set @now = GetDate()
   update tblUSER 
    set IsInactive = 'Y',
     DateUpdated = @now 
     where Email = @Email 
  END 
 if @UserName is NULL 
  set @UserExists = 13
 while @UserExists > 0 
  BEGIN 
   declare @PK1 int, @PK2 int, @PK3 int, @W1 varchar(10), @W2 varchar(10), @W3 varchar(10), @fstop int 
   exec dbo.get_RandomWordleWord
    @WordlePK = @PK1 OUT 
   exec dbo.get_RandomWordleWord
    @WordlePK = @PK2 OUT 
   exec dbo.get_RandomWordleWord
    @WordlePK = @PK3 OUT 
   set @W1 = Cast(dbo.fetch_WordleByPK(@PK1) as varchar(10))
   set @W2 = Cast(dbo.fetch_WordleByPK(@PK2) as varchar(10))
   set @W3 = Cast(dbo.fetch_WordleByPK(@PK3) as varchar(10))
   insert into @Wordles (WordOrder, Word) 
    VALUES (2, @W1), (4, @W2), (6, @W3)
   set @fstop = Floor(Rand() * 5)
   set @unstop = Abs(Floor(Rand() * 3) - 1)
   set @restoop = Abs(@fstop - @unstop)
   set @nstop = /*Abs(@fstop - @unstop)*/ 4 - (@restoop * @unstop)
   exec dbo.get_RandomStopWord
    @StopPK = @SK1 OUT 
   exec dbo.get_RandomStopWord
    @StopPK = @SK2 OUT 
   exec dbo.get_RandomStopWord
    @StopPK = @SK3 OUT 
   exec dbo.get_RandomStopWord
    @StopPK = @SK4 OUT 
   set @S1 = dbo.fetch_StopByPK(@SK1)
   set @S2 = dbo.fetch_StopByPK(@SK2)
   set @S3 = dbo.fetch_StopByPK(@SK3)
   set @S4 = dbo.fetch_StopByPK(@SK4)
   declare @Spl1 int, @Spl2 int, @Spl3 int, @Spl4 int 
   set @Spl1 = Cast((Rand() * 1000) as int)
   set @Spl2 = Cast((Rand() * 1000) as int)
   set @Spl3 = Cast((Rand() * 1000) as int)
   set @Spl4 = Cast((Rand() * 1000) as int)
   insert into @Stops (WordOrder, Word, DisOrder)
    VALUES (1, @S1, @Spl1), (3, @S2, @Spl2), (5, @S3, @Spl3), (7, @S4, @Spl4)
   delete from @Stops 
    where WordOrder in (select WordOrder
     from @Stops 
     order by DisOrder desc 
     offset 0 rows
     fetch next @nstop rows only)
   insert into @Wordles (WordOrder, Word) 
    select WordOrder, Word from @Stops
   set @NameString = (select STRING_AGG(Word, '') from @Wordles)
   if not exists (select UserID from tblUSER 
    where UserName = @NameString)
    set @UserExists = 0
   ELSE continue 
  END 
 if (@UserExists = 0) and (@UserName is NULL) 
  set @UserName = @NameString 
 insert into tblUSER (UserDOB, Email, FirstName, LastName, UserName, DisplayName)
  VALUES (@UserDOB, @Email, @FirstName, @LastName, @UserName, @DisplayName)
 END 
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

use deckdater_dev
GO 

select DOB, Email, Fname, Lname into #GUYS from LOAD_OF_GUYS where 1 = 0
alter table #GUYS 
 Add PK int Identity(1,1)
GO 
alter table #GUYS 
 ADD Constraint TempGuysPK PRIMARY KEY (PK)
GO 
create nonclustered index ix_TEMP_GUYS on #GUYS (DOB, Email, Fname, Lname)
GO
insert into #GUYS (DOB, Email, Fname, Lname)
select DOB, Email, Fname, Lname from LOAD_OF_GUYS 
 except (select UserDOB, Email, FirstName, LastName from tblUSER)
GO 
update #GUYS 
 set Email = NULL 
 where Email = 'NULL'
delete from #GUYS where Email is NULL 
GO 

select Count(UserID) as ExistingUsers from tblUSER 
select Count(PK) as RemainingGuys from #GUYS
--started checking again at: 588955 users, 956395 remaining 
--10 batches of 100 takes 1:20 
--1 "batch" of 1000 also takes 1:20
--100 of 10 (as a lark) *also* takes 1:20

declare @mini int, @maxi int, @rep int--, @startprn int, @stopprn int 
set NOCOUNT ON 
set @rep = 10
set @mini = (select Min(PK) from #GUYS)
while @rep > 0 
BEGIN 
set @maxi = @mini + 1000
--begin tran 
--begin tran 
insert into GUYTRYER (UserDOB, Email, FirstName, LastName)
 select DOB, Email, Fname, Lname from #GUYS 
  where PK < /* between @mini and */ @maxi 
--commit 
delete from #GUYS where PK /* between @mini and */ < @maxi 
--commit 
set @mini = @maxi /* + 1 */
set @rep = @rep - 1 
END 
GO 

--run just one without loop?

select DOB, Email, Fname, Lname into #GUYS from LOAD_OF_GUYS where 1 = 0
alter table #GUYS 
 Add PK int Identity(1,1)
GO 
alter table #GUYS 
 ADD Constraint TempGuysPK PRIMARY KEY (PK)
GO 
create nonclustered index ix_TEMP_GUYS on #GUYS (DOB, Email, Fname, Lname)
GO
insert into #GUYS (DOB, Email, Fname, Lname)
select DOB, Email, Fname, Lname from LOAD_OF_GUYS 
 except (select UserDOB, Email, FirstName, LastName from tblUSER)
GO 
update #GUYS 
 set Email = NULL 
 where Email = 'NULL'
delete from #GUYS where Email is NULL 
GO 

select Count(UserID) as ExistingUsers from tblUSER --586876
select Count(PK) as RemainingGuys from #GUYS --958374
--10 in .8s
--1000 in 58.1s to 1:21.14
--conclusion: while loop isn't costing anything here 

declare @mini int, @maxi int, @rep int
set NOCOUNT ON 
set @mini = (select Min(PK) from #GUYS)
set @maxi = @mini + 1000

insert into GUYTRYER (UserDOB, Email, FirstName, LastName)
 select DOB, Email, Fname, Lname from #GUYS 
  where PK < @maxi 
--commit 
delete from #GUYS where PK < @maxi 
