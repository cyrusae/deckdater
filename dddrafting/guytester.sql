/*
select * into tblUSER  
 from tblUSER 

GO 

 create table tblUSER (
 UserID int Identity(1,1) primary key NOT NULL,
 UserDOB date NOT NULL,
 Email varchar(200) NULL,
 FirstName varchar(25) NULL,
 LastName varchar(25) NULL,
 UserName varchar(100) unique NOT NULL,
 DisplayName varchar(140) NULL,
 DateCreated datetime DEFAULT GetDate(),
 DateUpdated datetime NULL,
 IsInactive char(1) SPARSE NULL) */

use deckdater_dev
GO 

create type UserNameStopGenerator as table (
 WordOrder int,
 Word varchar(10),
 DisOrder float
)
GO 


create OR alter proc u_NewUser 
 @UserDOB date,
 @Email varchar(200) NULL,
 @FirstName varchar(25) NULL,
 @LastName varchar(25) NULL,
 @UserName varchar(100) NULL,
 @DisplayName varchar(140) NULL 
 as BEGIN 
 set NOCOUNT ON 
 declare @UserExists int, @Wordles UserNameGenerator, @Stops UserNameStopGenerator, @NameString varchar(100), @nwordl int, @nstop int, @wspace int, @stspace int, @unstop int, @restoop int--, @woptions int, @stoptions int 
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
/* if (@UserName is NULL) or exists (select UserID from tblUSER where UserName = @UserName)
  set @UserExists = 1 
 ELSE  set @UserExists = 0 
 while @UserExists > 0 */
 if @UserName is NULL 
  set @UserExists = 13
/* set @woptions = 12974
 set @stoptions = 173 */
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
   declare @SK1 int, @SK2 int, @SK3 int, @SK4 int, @S1 varchar(10), @S2 varchar(10), @S3 varchar(10), @S4 varchar(10)
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
   declare @Spl1 float, @Spl2 float, @Spl3 float, @Spl4 float 
   insert into @Stops (WordOrder, Word, DisOrder)
    VALUES (1, @S1, @Spl1), (3, @S2, @Spl2), (5, @S3, @Spl3), (7, @S4, @Spl4)
   delete from @Stops 
    where WordOrder in (select WordOrder
     from @Stops 
     order by DisOrder
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

/* select * into GUYTESTER 
 from tblUSER 
 where 0 = 1 */
/*
create unique index ix_UserNames on tblUSER (UserName, Email) */
