create OR alter proc get_RandomWordleWord2
 @WordleCount int,
 @WordlePK int OUT 
 as BEGIN 
 declare @nrow int, @off int 
 set @nrow = @WordleCount 
 while @WordlePK is NULL 
  BEGIN 
   set @off = Floor(Rand() * @nrow)
   set @WordlePK = (select PK from UN_Wordle
    order by PK 
    offset @off rows 
    fetch next 1 rows only)
  END 
 END 
GO 

create OR alter proc get_RandomStopWord2 
 @StopCount int, 
 @StopPK int OUT 
 as BEGIN 
 declare @nrow int, @off int 
 set @nrow = @StopCount 
 while @StopPK is NULL 
  BEGIN 
   set @off = Floor(Rand() * @nrow)
   set @StopPK = (select PK from UN_StopWord
    order by PK 
    offset @off rows 
    fetch next 1 rows only)
  END 
 END 
GO 

declare 
 @UserDOB date,
 @Email varchar(200),
 @FirstName varchar(25),
 @LastName varchar(25),
 @UserName varchar(100),
 @DisplayName varchar(140) 
 set NOCOUNT ON 
  set NOCOUNT ON 
 declare @UserExists int, @Wordles UserNameGenerator, @Stops UserNameGenerator, @NameString varchar(100), @nwordl int, @nstop int, @wspace int, @stspace int, @unstop int--, @woptions int, @stoptions int 
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
   declare @PK1 int, @PK2 int, @PK3 int, @W1 varchar(10), @W2 varchar(10), @W3 varchar(10)
   exec dbo.get_RandomWordleWord2 
    @WordleCount = 12794,
    @WordlePK = @PK1 OUT 
   exec dbo.get_RandomWordleWord2 
    @WordleCount = 12794,
    @WordlePK = @PK2 OUT 
   exec dbo.get_RandomWordleWord2 
    @WordleCount = 12794,
    @WordlePK = @PK3 OUT 
   set @W1 = Cast(dbo.fetch_WordleByPK(@PK1) as varchar(10))
   set @W2 = Cast(dbo.fetch_WordleByPK(@PK2) as varchar(10))
   set @W3 = Cast(dbo.fetch_WordleByPK(@PK3) as varchar(10))
   insert into @Wordles (WordOrder, Word) 
    VALUES (2, @W1), (4, @W2), (6, @W3)
   set @nstop = Floor(Rand() * 5)
   set @unstop = Floor(Rand() * 2)
   set @nstop = @nstop * @unstop 
   declare @SK1 int, @SK2 int, @SK3 int, @SK4 int, @S1 varchar(10), @S2 varchar(10), @S3 varchar(10), @S4 varchar(10)
   exec dbo.get_RandomStopWord2 
    @StopCount = 173, 
    @StopPK = @SK1 OUT 
   exec dbo.get_RandomStopWord2 
    @StopCount = 173, 
    @StopPK = @SK2 OUT 
   exec dbo.get_RandomStopWord2 
    @StopCount = 173, 
    @StopPK = @SK3 OUT 
   exec dbo.get_RandomStopWord2 
    @StopCount = 173, 
    @StopPK = @SK4 OUT 
   set @S1 = dbo.fetch_StopByPK(@SK1)
   set @S2 = dbo.fetch_StopByPK(@SK2)
   set @S3 = dbo.fetch_StopByPK(@SK3)
   set @S4 = dbo.fetch_StopByPK(@SK4)
   insert into @Stops (WordOrder, Word)
    VALUES (1, @S1), (3, @S2), (5, @S3), (7, @S4)
   delete from @Stops 
    where WordOrder in (select WordOrder
     from @Stops 
     order by NewID()
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

