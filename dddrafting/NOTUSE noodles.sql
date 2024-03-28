create table META_ENV_VAR (
 PK int Identity(1,1) primary key NOT NULL,
 NameOfTable nvarchar(50) unique NOT NULL, 
 IndexedOn nvarchar(50) NOT NULL,
 nrow int,
 smallest int, 
 biggest int)
GO 

create OR alter proc GET_RANDOM_ROW 
 @FromTable nvarchar(50),
 @randro int OUT 
 as BEGIN 
  declare @SQLstring nvarchar(1000), @ParmDefinition nvarchar(50), @pkol nvarchar(50), @nrow int, @smol int, @big int, @loop int, @attempt int, @coin int, @head int, @tail int 
  set @loop = 1 
  set @ParmDefinition = N'@trial int, @found int OUT'
  select @pkol = IndexedOn, 
   @nrow = nrow, 
   @smol = smallest,
   @big = biggest 
   from META_ENV_VAR 
    where NameOfTable = @FromTable
  set @SQLstring = 'set @found = (select ' 
     + @pkol + ' from ' 
     + @FromTable + ' where ' 
     + @pkol + ' = @trial)'
  while @loop > 0 
  BEGIN 
   set @head = Ceiling(Rand() * @big)
   set @tail = @smol + Floor(Rand() * @nrow)
   set @coin = Floor(Rand() * 2)
   if @coin > 0 
    set @attempt = @head 
   ELSE set @attempt = @tail 
   EXEC sp_executesql @SQLstring,
     @ParmDefinition,
     @trial = @attempt,
     @found = @randro OUT 
   if @randro is NULL 
    set @loop = @loop + 1
    if @loop > 100 
     BREAK 
   ELSE set @loop = 0
  END 
 END 
GO 

create OR alter proc ENV_VAR_ColFunctions 
 @UseTable nvarchar(50),
 @UseColumn nvarchar(50),
 @UseFunction nvarchar(10),
 @res int OUT 
 as BEGIN 
 declare @SQLstring nvarchar(1000), @ParmString nvarchar(100)
 set @SQLstring = 'set @checked = (select '
   + @UseFunction + '(' + @UseColumn + ') from ' + @UseTable + ')'
 set @ParmString = N'@checked int OUT'
 EXEC sp_executesql @SQLstring, 
   @ParmString, @checked = @res OUT 
 END 
GO 

create OR alter proc ENV_VAR_UPD8 
 @ForTable nvarchar(50)
 as BEGIN 
 declare @pkol nvarchar(50), @nrow int, @minrow int, @maxrow int, @SQLcheck nvarchar(1000), @ParmCheck nvarchar(100)
 set @pkol = (select IndexedOn from META_ENV_VAR where NameOfTable = @ForTable)
 exec dbo.ENV_VAR_ColFunctions 
  @UseTable = @ForTable,
  @UseColumn = @pkol,
  @UseFunction = N'Count',
  @res = @nrow OUT 
 exec dbo.ENV_VAR_ColFunctions
  @UseTable = @ForTable,
  @UseColumn = @pkol, 
  @UseFunction = N'Max',
  @res = @maxrow OUT 
 exec dbo.ENV_VAR_ColFunctions 
  @UseTable = @ForTable, 
  @UseColumn = @pkol, 
  @UseFunction = N'Min',
  @res = @minrow OUT 
 if (@nrow is NOT NULL) and (@minrow is NOT NULL) and (@maxrow is NOT NULL)
  update META_ENV_VAR 
   set nrow = @nrow,
     biggest = @maxrow,
     smallest = @minrow
    where NameOfTable = @ForTable
 END 
GO 
/*
insert into META_ENV_VAR (NameOfTable, IndexedOn, nrow, smallest, biggest)
 VALUES(N'UN_StopWord', N'PK', 0, 0, 0), (N'UN_Wordle', N'PK', 0, 0, 0), (N'tblUSER', N'UserID', 0, 0, 0), (N'tblDECK', N'DeckID', 0, 0, 0), (N'tblDECK_FORMAT', N'DeckID', 0, 0, 0), (N'tblCARD', N'CardCount', 0, 0, 0), (N'tblCARD_FACE', N'CardFaceID', 0, 0, 0), (N'tblCARD_FACE_SET', N'CardFaceSetID', 0, 0, 0), (N'tblSET', N'SetCount', 0, 0, 0) */

create OR alter proc ENV_VAR_UPD8_MASS 
 as BEGIN 
 declare @Tab nvarchar(50), @rowboat int, @oar int 
 set @rowboat = (select Count(PK) from META_ENV_VAR)
 while @rowboat > 0
  BEGIN
   set @oar = (select Min(PK) from META_ENV_VAR)
   set @Tab = (select NameOfTable from META_ENV_VAR where PK = @oar)
   exec dbo.ENV_VAR_UPD8 @Tab 
   set @rowboat = @rowboat - 1 
  END 
 END 
GO 

create type Unlisted as table (
 PK int Identity(1,1) primary key NONCLUSTERED NOT NULL,
 Item varchar(500))
  with (MEMORY_OPTIMIZED = ON);
GO 


create type UnlistedInts as table (
 PK int Identity(1,1) primary key NONCLUSTERED NOT NULL,
 Item int)
  with (MEMORY_OPTIMIZED = ON);
GO 

declare @pickuser int, @UserName varchar(100), @UserID int, @deckcount int, @deck Unlisted, @deckids UnlistedInts, @dupes int, @pickcard int 
set @deckcount = CEILING(Rand() * 100)
set NOCOUNT ON 
while @deckcount > 0 
 BEGIN 
 exec dbo.GET_RANDOM_ROW 
  @FromTable = N'tblUSER',
  @randro = @pickcard OUT 
 insert into @deckids (Item) VALUES (@pickcard)
 if (@deckcount % 7 = 0)
  BEGIN 
   set @dupes = CEILING(Rand() * 3)
   while @dupes > 0 
    BEGIN 
     insert into @deckids (Item) VALUES (@pickcard)
     set @dupes = @dupes - 1 
    END 
  END 
 set @deckcount = @deckcount - 1 
 END 
insert into @deck (Item)
 select CF.UserName from tblUSER CF
  join @deckids D on CF.UserID = D.Item 

select STRING_AGG(Item, '|') from @deck 

exec sp_rename N'tblCARD_FACE.CardFaceNameMachineReadable', N'CardFaceSearchName', 'column'

 
drop table #tmptst 
drop table #tmptst2  

create table #tmptst (
 PK int Identity(1,1) primary key NOT NULL,
 CardnameEx varchar(200) NOT NULL,
 Supertypes varchar(100) NULL,
 Types varchar(100) NOT NULL,
 Subtypes varchar(100) NULL,
 PlatformList varchar(100) NOT NULL
)

insert into #tmptst (CardnameEx, Supertypes, Types, Subtypes, PlatformList) VALUES ('Jace, the Mind Sculptor', 'Legendary', 'Planeswalker', 'Jace', 'paper'), ('Jorn, whatshisface', 'Legendary Snow', 'Creature', 'Zombie Wizard', 'paper, arena')

select CardnameEx, SupertypeID, Types, Subtypes, PlatformList into #tmptst2 
 from #tmptst T 
 CROSS APPLY STRING_SPLIT(T.Supertypes, ' ')
 join defSUPERTYPE S on value = S.SupertypeName 
 
select * from #tmptst2 Too 
 CROSS APPLY STRING_SPLIT(PlatformList, ',')
 LEFT join defPLATFORM P on Trim(value) = P.PlatformName 

select * from defPLATFORM 

select S.SupertypeID, S.SupertypeName from defSUPERTYPE S 
 join STRING_SPLIT('Legendary Snow', ' ') on value = S.SupertypeName 
 