use Info_430_deckdater 
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

create OR alter proc GET_RANDOM_ROW
 @FromTable nvarchar(50),
 @randro int OUT 
 as BEGIN 
  declare @SQLstring nvarchar(1000), @ParmDefinition nvarchar(50), @pkol nvarchar(50), @nrow int, @smol int, @big int, @loop int, @coin int, @head int, @tail int, @try1 int, @try2 int 
  set @loop = 1 
  set @ParmDefinition = N'@trial int, @found int OUT'
  select @pkol = IndexedOn, 
   @nrow = nrow, 
   @smol = smallest,
   @big = biggest 
   from META_ENV_VAR 
    where TableName = @FromTable
  set @SQLstring = 'set @found = (select ' 
     + @pkol + ' from ' 
     + @FromTable + ' where ' 
     + @pkol + ' = @trial)'
  while @loop > 0 
  BEGIN 
   set @head = Ceiling(Rand() * @big)
   set @tail = @smol + Floor(Rand() * @nrow)
   set @coin = Floor(Rand() * 2)
   EXEC sp_executesql @SQLstring,
     @ParmDefinition,
     @trial = @head,
     @found = @try1 OUT 
   EXEC sp_executesql @SQLstring,
     @ParmDefinition,
     @trial = @tail,
     @found = @try2 OUT 
   if (@coin > 0) 
    BEGIN 
     if (@try1 is NULL) set @randro = @try2
      ELSE set @randro = @try1 
    END 
   ELSE 
    BEGIN 
     if (@try2 is NULL) set @randro = @try1 
      ELSE set @randro = @try2 
    END 
   if @randro is NULL 
    set @loop = @loop + 1
   if @loop > 100 --give up eventually 
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
 set @pkol = (select IndexedOn from META_ENV_VAR where TableName = @ForTable)
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
 if @ForTable = 'tblUSER' --override here 
  set @minrow = (select Min(UserID) from tblUSER 
   where UserName not in ('Emperor', 'Magician'))
 if (@nrow is NOT NULL) and (@minrow is NOT NULL) and (@maxrow is NOT NULL)
  update META_ENV_VAR 
   set nrow = @nrow,
     biggest = @maxrow,
     smallest = @minrow
    where TableName = @ForTable
 END 
GO 

create OR alter function makeupaguy_deckname(@UserID int, @DeckName varchar(280)) 
 returns varchar(350)
 as BEGIN 
 declare @RET varchar(350), @repeats int 
 if @DeckName IS NULL 
  set @DeckName = 'New Deck'
 set @repeats = (select Count(DeckID) from tblDECK where DeckName = @DeckName and UserID = @UserID)
 if @repeats > 0 
  BEGIN 
   declare @GenericizedDeckName varchar(350)
   set @GenericizedDeckName = @DeckName + ' %'
   set @repeats = @repeats + (select Count(DeckID) from tblDECK where UserID = @UserID and DeckName like @DeckName)
   set @RET = @DeckName + ' ' + Cast(@repeats as varchar)
  END 
  ELSE set @RET = @DeckName
 return @RET 
 END 
GO 

create OR alter proc u_ADD_NewDeck 
 @ForUserName varchar(100),
 @FormatMachineName varchar(25) NULL,
 @DeckNameString varchar(280) NULL,
 @WithMaindeck varchar(8000),
 @WithCMDR varchar(8000) NULL,
 @WithSIDE varchar(8000) NULL, 
 @WithMAYB varchar(8000) NULL,
 @WithWISH varchar(8000) NULL,
 @IsPrivate char(1) NULL
 as BEGIN 
 set NOCOUNT ON 
 declare @CommandZoneID int, @SideZoneID int, @MaybeZoneID int, @WishZoneID int, @DeckName varchar(350), @DeckID int, @side Unlisted, @maybe Unlisted, @cmdr Unlisted, @wish Unlisted, @main Unlisted, @UserID int, @InFormatID int 
 set @InFormatID = dbo.fetch_FormatIDbyMachineName(@FormatMachineName)
 set @UserID = dbo.fetch_UserIDbyUsername(@ForUserName)
 if @UserID is NULL 
  BEGIN 
   print 'User ID not found. Check spelling and uniqueness';
   throw 93846, 'UserID lookup requires unique username and deck name. Check inputs', 14;
  END 
 insert into @main (Item)
  select value as Item from STRING_SPLIT(@WithMaindeck, '|')
 set @DeckName = dbo.makeupaguy_deckname(@UserID, @DeckNameString)
 set @CommandZoneID = (select ZoneID from defZONE where ZoneName = 'CMDR')
 set @SideZoneID = (select ZoneID from defZONE where ZoneName = 'SIDE')
 set @MaybeZoneID = (select ZoneID from defZONE where ZoneName = 'MAYB')
 set @WishZoneID = (select ZoneID from defZONE where ZoneName = 'WISH')
 begin tran NewDeck 
  insert into tblDECK (UserID, DeckName, IsPrivate)
   VALUES (@UserID, @DeckName, @IsPrivate)
  set @DeckID = scope_identity()
  
  begin tran NewDeckDetails 
   if @InFormatID is NOT NULL 
    BEGIN 
     insert into tblDECK_FORMAT (DeckID, FormatID)
      VALUES (@DeckID, @InFormatID)
    END 
   insert into tblDECK_CARD (DeckID, CardFaceID, Quantity)
    select @DeckID, CF.CardFaceID, Count(U.PK) as Quantity
     from @main U 
     join tblCARD_FACE CF on U.Item = CF.CardFaceSearchName 
  --   where CFS.IsReprint is NULL 
     group by CF.CardFaceID
   if (@WithCMDR is NOT NULL) or (@WithSIDE is NOT NULL) or (@WithMAYB is NOT NULL) or (@WithWISH is NOT NULL) 
   BEGIN 
    if @WithMAYB is NOT NULL 
     insert into @maybe (Item) 
      select value as Item from STRING_SPLIT(@WithMAYB, '|')
    if @WithWISH is NOT NULL 
     insert into @wish (Item) 
      select value as Item from STRING_SPLIT(@WithWISH, '|')
    if @WithCMDR is NOT NULL 
     insert into @cmdr (Item)
      select value as Item from STRING_SPLIT(@WithCMDR, '|')
    if @WithSIDE is NOT NULL 
     insert into @side (Item)
      select value as Item from STRING_SPLIT(@WithSIDE, '|')
    insert into tblDECK_CARD_ZONE (DeckID, CardFaceID, Quantity, ZoneID)
    select @DeckID, X.CardFaceID, X.Quantity, X.ZoneID from (
     select CF.CardFaceID, Count(U.PK) as Quantity, @CommandZoneID as ZoneID 
      from @cmdr U 
      join tblCARD_FACE CF on U.Item = CF.CardFaceSearchName 
      group by CF.CardFaceID 
     UNION ALL 
     select CF.CardFaceID, Count(U.PK) as Quantity, @SideZoneID as ZoneID 
      from @side U 
      join tblCARD_FACE CF on U.Item = CF.CardFaceSearchName 
      group by CF.CardFaceID 
     UNION ALL 
     select CF.CardFaceID, Count(U.PK) as Quantity, @MaybeZoneID as ZoneID 
      from @maybe U 
      join tblCARD_FACE CF on U.Item = CF.CardFaceSearchName 
      group by CF.CardFaceID 
     UNION ALL 
     select CF.CardFaceID, Count(U.PK) as Quantity, @WishZoneID as ZoneID
      from @wish U 
      join tblCARD_FACE CF on U.Item = CF.CardFaceSearchName 
      group by CF.CardFaceID 
    ) as X 
   END 
  commit tran NewDeckDetails 
 commit tran NewDeck 
 END 
GO 

exec dbo.ENV_VAR_UPD8 N'tblUSER'
GO 

create OR alter proc SPAGHETTI_decking --run with up-to-date environment variables!
 as BEGIN 
 declare @pickuser int, @UserName varchar(100), @UserID int, @deckcount int, @deck Unlisted, @deckids UnlistedInts, @dupes int, @pickcard int, @priv char(1), @decklist varchar(8000)
 set NOCOUNT ON 
 exec dbo.GET_RANDOM_ROW 
  @FromTable = N'tblUSER',
  @randro = @pickuser OUT 
 set @UserName = dbo.fetch_UsernameByID(@pickuser)
 if @UserName is NULL 
  BEGIN 
   exec dbo.GET_RANDOM_ROW 
    @FromTable = N'tblUSER',
    @randro = @pickuser OUT 
   set @UserName = dbo.fetch_UsernameByID(@pickuser)
  END 
 set @deckcount = CEILING(Rand() * 50)
 if (@deckcount % 5 = 0) set @priv = 'Y'
 while @deckcount > 0 
  BEGIN 
  exec dbo.GET_RANDOM_ROW 
   @FromTable = N'tblCARD_FACE',
   @randro = @pickcard OUT 
  insert into @deckids (Item) VALUES (@pickcard)
  if (@deckcount % 17 = 0)
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
  select CF.CardFaceSearchName from tblCARD_FACE CF
   join @deckids D on CF.CardFaceID = D.Item 
 set @decklist = (select STRING_AGG(Item, '|') from @deck)
 exec dbo.u_ADD_NewDeck 
  @ForUserName = @UserName,
  @FormatMachineName = NULL, --format isn't mandatory so let's not spoof that for now (I have reasons)
  @DeckNameString = NULL,
  @WithMaindeck = @decklist,
  @WithSIDE = NULL,
  @WithMAYB = NULL,
  @WithCMDR = NULL,
  @WithWISH = NULL,
  @IsPrivate = @priv 
 END 
GO 

create OR alter proc SPAGHETTI_decking_AUTO 
 @times int
 as BEGIN 
 set NOCOUNT ON 
 while @times > 0 
  BEGIN 
  exec dbo.SPAGHETTI_decking 
  set @times = @times - 1 
  END 
 END 
GO 

