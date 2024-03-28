create OR alter function fetch_UserIDbyUsername (@UserName varchar(100))
 returns int 
 as BEGIN 
 declare @RET int 
 set @RET = (select UserID from tblUSER where UserName = @UserName)
 return @RET 
 END 
GO

create OR alter function fetch_FormatID (@FormatName varchar(25), @FormatMedium char(3) NULL)
 returns int 
 as BEGIN 
 declare @RET int 
 if @FormatMedium is NOT NULL 
  set @RET = (select F.FormatID from refFORMAT F 
   join defFORMAT_MEDIUM M on F.FormatMediumID = M.FormatMediumID 
   join defFORMAT_NAME N on F.FormatNameID = N.FormatNameID 
   where FormatNameMachineReadable = @FormatName 
    and FormatMediumAbbrev = @FormatMedium)
 ELSE 
  set @RET = (select Top 1 FormatID from refFORMAT F 
   join defFORMAT_NAME N on F.FormatNameID = N.FormatNameID
   where FormatNameMachineReadable = @FormatName
    or FormatName = @FormatName
   order by FormatID)
 return @RET 
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
   set @repeats = @repeats + (select Count(DeckID) from tblDECK where UserID = @UserID and DeckName like @GenericizedDeckName)
   set @RET = @DeckName + @repeats
  END 
  ELSE set @RET = @DeckName
 return @RET 
 END 
GO 

create type Unlisted as table (
 PK int Identity(1,1) primary key NOT NULL,
 Item varchar(500))
  with (MEMORY_OPTIMIZED = ON);

create type IngestDecklist as table (
 PK int Identity(1,1) primary key NOT NULL,
 CardFaceName varchar(200) NOT NULL,
 Quantity int DEFAULT 1,
 ZoneName char(4) NULL)
  with (MEMORY_OPTIMIZED = ON);

create type WrangleDecklist as table (
 PK int Identity(1,1) primary key NOT NULL,
 CardFaceID int NOT NULL,
 Quantity int DEFAULT 1,
 ZoneID char(4) NULL)
  with (MEMORY_OPTIMIZED = ON);
GO 

create OR alter proc ADD_DeckFromList --break this out into procedures so it's easier to spaghet. 
 @UserID int,
 @NewDeckName varchar(200),
 @InFormat varchar(25),
 @FormatMedium char(3) NULL,
 @MainDecklist varchar(8000) NULL,
 @SideboardList varchar(8000) NULL,
 @WishboardList varchar(8000) NULL,
 @MaybeboardList varchar(8000) NULL,
 @CommandZoneList varchar(8000) NULL
 as BEGIN 
 declare @RealDeckName varchar(350), @Mainboard Unlisted, @Sideboard Unlisted, @Maybeboard Unlisted, @Command Unlisted, @Wishboard Unlisted, @Ingester IngestDecklist, @Wrangler WrangleDecklist, @DeckID int, @FormatNameID int 
 set @RealDeckName = dbo.makeupaguy_deckname(@NewDeckName)
 set @FormatID = dbo.fetch_FormatNameID(@InFormat)
 insert into @Mainboard (Item)
  select value from STRING_SPLIT(@MainDecklist, '|')
 insert into @Sideboard (Item)
  select value from STRING_SPLIT(@SideboardList, '|')
 insert into @Wishboard (Item)
  select value from STRING_SPLIT(@WishboardList, '|')
 insert into @Maybeboard (Item)
  select value from STRING_SPLIT(@MaybeboardList, '|')
 insert into @Command (Item)
  select value from STRING_SPLIT(@CommandZoneList, '|')
 insert into @Ingester (CardFaceName, Quantity)
  select Item, Count(*) from @Mainboard 
  group by Item 
 insert into @Ingester (CardFaceName, Quantity, ZoneName)
  select Item, Count(*), 'SIDE' from @Sideboard 
  group by Item 
 insert into @Ingester (CardFaceName, Quantity, ZoneName)
  select Item, Count(*), 'MAYB' from @Maybeboard 
  group by Item 
 insert into @Ingester (CardFaceName, Quantity, ZoneName)
  select Item, Count(*), 'WISH' from @Wishboard 
  group by Item 
 insert into @Ingester (CardFaceName, Quantity, ZoneName)
  select Item, Count(*), 'CMDR' from @Command 
  group by Item
 insert into @Wrangler (CardFaceID, Quantity, ZoneID)
  select CF.CardFaceID, I.Quantity, Z.ZoneID 
  from @Ingester I 
  join tblCARD_FACE CF on I.CardFaceName = CF.CardFaceNameMachineReadable 
  join defZONE Z on I.ZoneName = DC.ZoneName 
 begin tran CreateDeck 
  insert into tblDECK (UserID, DeckName)
   VALUES (@UserID, @RealDeckName)
  begin tran DeckDetails 
   set @DeckID = scope_identity()
   begin tran DeckFormat 
    if @FormatNameID is NOT NULL 
     insert into tblDECK_FORMAT (DeckID, FormatID) 
      VALUES (@DeckID, @FormatID)
   commit 
   begin tran DeckMaindeck 
    insert into tblDECK_CARD (DeckID, CardFaceID, Quantity)
     select @DeckID, CardFaceID, Quantity from @Wrangler 
      where ZoneID is NULL 
   commit 
   begin tran DeckOtherZones 
    insert into tblDECK_CARD_ZONE (DeckID, CardFaceID, Quantity, ZoneID) --this will just fizzle if there's nothing to add, right?
     select @DeckID, CardFaceID, Quantity, ZoneID from @Wrangler 
      where ZoneID is NOT NULL 
   commit 
  commit 
 commit 
 END 
GO 

create OR alter proc u_ADD_NewDeck 
 @UserName varchar(100),
 @DeckName varchar(200) NULL,
 @Format varchar(50) NULL,
 @Gamesplay varchar(25) NULL,
 @Decklist varchar(8000) NULL,
 @Sideboard varchar(8000) NULL,
 @Wishboard varchar(8000) NULL,
 @Maybeboard varchar(8000) NULL,
 @CommandZone varchar(8000) NULL
 as BEGIN 
 declare @ByUserID int, @GameMedium char(3)
 set @ByUserID = dbo.fetch_UserIDbyUsername(@UserName)
 if @ByUserID is NULL 
  BEGIN
   print 'User not found!';
   throw 394846, 'No User ID found. Check spelling.', 13;
  END 
 if @Gamesplay is NOT NULL 
  set @GameMedium = (select FormatMediumAbbrev 
   from defFORMAT_MEDIUM 
   where FormatMediumName = @Gamesplay)
 ELSE set @GameMedium = @Gamesplay 
 exec dbo.ADD_DeckFromList 
  @UserID = @ByUserID,
  @NewDeckName = @DeckName,
  @InFormat = @Format,
  @FormatMedium = @GameMedium,
  @MainDecklist = @Decklist,
  @SideboardList = @Sideboard,
  @WishboardList = @Wishboard,
  @MaybeboardList = @Maybeboard,
  @CommandZoneList = @CommandZone
 END 
GO 