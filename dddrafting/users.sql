use deckdater 
GO 

create table tblUSER (
 UserID int Identity(1,1) primary key NOT NULL,
 UserEmail varchar(200) NULL,
 UserName varchar(100),
 DisplayName varchar(100) NULL,
 FirstName varchar(50) NULL,
 LastName varchar(50) NULL,
 UserDOB date,
 UserBio varchar(3000) NULL,
 AccountCreated datetime DEFAULT GetDate(),
 AccountUpdated datetime NULL,
 IsInactive char(1) SPARSE NULL)
GO 

create type ProcessingUsers as table (
 PK int Identity(1,1) primary key NOT NULL,
 UserEmail varchar(200) NULL,
 UserName varchar(100) NULL,
 DisplayName varchar(100) NULL,
 FirstName varchar(50) NULL,
 LastName varchar(50) NULL,
 UserBio varchar(3000) NULL,
 UserDOB date NULL)
GO 

--create rawable table 
declare @Table as ProcessingUsers 
select * into RAW_UsersJoin from @Table 
GO 

create table UN_Wordles (
 PK int Identity(1,1) primary key NOT NULL,
 Wordle char(5) unique NOT NULL)

create table UN_StopWords (
 PK int Identity(1,1) primary key NOT NULL,
 StopWord varchar(10))

create type RandomUserNameMaker as table (
 DoOrder int NULL,
 Word varchar(10))
GO 

create OR alter function lookup_userID(@ByUserName varchar(100)) returns INT 
 as BEGIN 
 declare @RET int 
 set @RET = (select UserID from tblUSER where UserName = @ByUserName)
 return @RET 
 END 
GO 

create OR alter function makeupaguy_username()
 returns varchar(100)
 as BEGIN 
 declare @RET varchar(100), @UserExistsMyDude int, @W_offsetting int, @W_fetching int, @W_order int, @S_offsetting int, @S_fetching int, @S_interpolating int, @S_pace int, @NextWord char(5), @NextStop varchar(10)

 set @UserExistsMyDude = 1 
 while @UserExistsMyDude > 0 
  BEGIN 
  --create a random name 
   declare @GivWs RandomUserMaker, @GivSs RandomUserMaker, @Generator RandomUserMaker --declaring here means it will do it from scratch every time the loop runs so we don't accumulate crud from multiple attempts if we hit a duplicate. (which is close to mathematically impossible! but I am being silly.)
   set @W_fetching = (select Floor(Rand() * 3)) + 1
   set @W_offsetting = (select Floor(Rand() * 12974)) - @W_fetching
   if @W_offsetting < 0 set @W_offsetting = 0
   set @S_fetching = (select Floor(Rand() * 4))
   set @S_offsetting = (select Floor(Rand() * 175)) - @S_fetching 
   if @S_offsetting < 0 set @S_offsetting = 0 
   set @W_order = 2 
   insert into @GetWs (Word)
    select Wordle from UN_Wordles 
     order by PK 
     offset @W_offsetting rows 
     fetch next @W_fetching rows only 

   if @W_fetching < 3 
    BEGIN 
     declare @Wwant3 int, @dup char(5)
     set @Wwant3 = 3 - @W_fetching
     while @Wwant3 > 0 
      BEGIN
       set @dup = (select Top(1) Word from @GetWs)
       insert into @GetWs (Word) VALUES (@dup)
       set @Wwant3 = @Wwant3 - 1  
      END 
    END 
   while @W_order < 6 
    BEGIN 
     set @NextWord = (select Top(1) Word from @GetWs) 
     insert into @Generator (DoOrder, Word)
      VALUES (@W_order, @NextWord)
     delete Top(1) from @GetWs where Word = @NextWord  --don't care about order so if it will run without an order by I actually want it to do that 
     set @W_order = @W_order + 2 
    END    
   if @S_fetching > 0 
    BEGIN 
    declare @S_pacing table (place int)
    insert into @S_pacing 
     select Cast(value as int) from STRING_SPLIT('1,3,5,7')
    insert into @GetSs (Word)
     select StopWord from UN_StopWords 
      order by PK 
      offset @S_offsetting rows 
      fetch next @S_fetching rows only 
    set @S_interpolating = 7 - (2 * @S_fetching)
    set @S_pace = 1 + (2 * @S_fetching)
    delete from @S_pacing where place = @S_pace 
    while @S_interpolating < 7 
     BEGIN       
     set @NextStop = (select Top(1) Word from @GetSs)
      set @S_pace = (select Top(1) place from @S_pacing)
      insert into @Generator (WordOrder, Word)
       VALUES (@S_pace, @NextStop)
      delete from @GetSs where Word = @NextStop 
      delete from @S_pacing where place = @S_pace 
      set @S_interpolating = 7 - (2 * (select Count(Word) from @GetSs))
     END 
    END 
   set @RET = (select STRING_AGG(Word, '') 
    from @Generator 
    order by DoOrder desc)
   if (select dbo.lookup_userID(@RET)) IS NULL 
    set @UserExistsMyDude = 0 
  END 
 return @RET 
 END 
GO 

create OR alter proc CREATE_NewUser 
 @UserRow ProcessingUsers READONLY 
 as BEGIN 
 --invalid input handling
 ----too many rows wyd 
 if (select Count(PK) from @UserRow) > 1 
  BEGIN
   print 'CREATE_NewUser must be fed one row at a time. There are too many rows here.';
   throw 398428, 'Invalid number of rows in input (greater than 1). Terminating', 9; 
  END 
  ----too few rows wyd
 if (select Count(PK) from @UserRow) = 0
  BEGIN
   print 'CREATE_NewUser must be fed one row at a time. There are no rows here.';
   throw 398440, 'Invalid number of rows in input (none given). Terminating', 9; 
  END 
 
 declare @UserEmail varchar(200), @UserName varchar(100), @DisplayName varchar(100) NULL, @FirstName varchar(50), @LastName varchar(50), @UserBio varchar(3000), @UserDOB date, /*remove this when not testing */ @FakeCreateDate datetime, @FakeDays int 
 set @FakeDays = Floor(Rand() * 420)
 set @FakeCreateDate = Cast(DateAdd(days, -@FakeDays, GetDate()) as datetime) --remove when not testing 

 select @UserEmail = UserEmail, 
   @UserName = UserName,
   @DisplayName = DisplayName, 
   @FirstName = FirstName, 
   @LastName = LastName, 
   @UserBio = UserBio,
   @UserDOB = UserDOB 
  from @UserRow 
 
 --handle input errors (because type is shared with updating)
 if @UserDOB IS NULL 
  BEGIN 
   print 'Users must provide their date of birth.';
   throw 99569, 'Users must provide date of birth. No date of birth provided. Account creation without a valid date of birth cannot be completed.', 9;
  END 
 if @UserDOB > DateAdd(year, -16, @FakeCreateDate)
  BEGIN 
   print 'Users must be older than 16. Not taking your location means GDPR everywhere, guys. Use the contact page to submit parental consent for an override if you absolutely must.';
   throw 99569, 'Date of birth provided is not GDPR compliant. Account creation without a valid date of birth cannot be completed.', 9;
  END 

 begin transaction 
  if exists (select UserID from tblUSER where UserName = @UserName) 
   BEGIN
    print 'Account already exists! That is your problem. :)';
    throw 346973, 'Usernames must be unique. Try again, generate a random one, or log into your account.', 8;
   END 

  if @UserName IS NULL 
   set @UserName = dbo.makeupaguy_username()
   
  insert into tblUSER (UserEmail, UserName, DisplayName, FirstName, LastName, UserDOB, UserBio, AccountCreated) 
   VALUES (@UserEmail, @UserName, @DisplayName, @FirstName, @LastName, @UserDOB, @UserBio, /*remove this when not testing */ @FakeCreateDate)
 commit 
 END 
GO 

create OR alter proc YEET_InactiveUser 
 as BEGIN --garbage collection for inactive accounts 
  delete from tblUSER 
   where IsInactive is NOT NULL 
    and AccountUpdated < DateAdd(week, -3, GetDate())
 END 
GO --run periodically (gives nine days wiggle room before GDPR problems)

create trigger t_FakeUsersForDev on RAW_UsersJoin --deactivate this trigger in prod, you know, as if it was going to be clear copy-pasted to prod otherwise lmao 
 after insert 
 as BEGIN 
 declare @added int, @currow ProcessingUsers, @pointme int, @checkemails varchar(200)
 set @added = (select Count(PK) from inserted)
 while @added > 0 
  BEGIN 
   set @pointme = (select Min(PK) from inserted)
   set @checkemails = (select UserEmail from inserted where PK = @pointme)
   insert into @currow 
    select * from inserted where PK = @pointme 
   begin transaction 
    if (@checkemails is NOT NULL) and exists (select UserID from tblUSER where UserEmail = @checkemails and IsInactive is NULL)
     BEGIN --let's deactivate the dupes, hell with it
     --(would this want to be a nested transaction?)
      declare @now as datetime 
      set @now = GetDate()
      update tblUSER 
       set IsInactive = 'Y', AccountUpdated = @now
       where UserEmail = @checkemails
     END

    exec dbo.CREATE_NewUser 
     @UserRow = @currow 

    delete from RAW_UsersJoin where PK = @pointme
    set @added = @added - 1 
   commit 
  END 
 END 
GO 