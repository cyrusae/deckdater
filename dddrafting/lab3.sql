/*
create table META_ENV_VAR (
 PK int Identity(1,1) primary key NOT NULL,
 NameOfTable nvarchar(50) unique NOT NULL, 
 IndexedOn nvarchar(50) NOT NULL,
 nrow int,
 smallest int, 
 biggest int)
GO 
*/

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
 VALUES(N'UN_StopWord', N'PK', 0, 0, 0), --used for username generation
  (N'UN_Wordle', N'PK', 0, 0, 0), --also used for username generation
  (N'tblUSER', N'UserID', 0, 0, 0), 
  (N'tblDECK', N'DeckID', 0, 0, 0), (N'tblDECK_FORMAT', N'DeckID', 0, 0, 0), 
  (N'tblCARD', N'CardCount', 0, 0, 0), 
  (N'tblCARD_FACE', N'CardFaceID', 0, 0, 0), (N'tblCARD_FACE_SET', N'CardFaceSetID', 0, 0, 0), 
  (N'tblSET', N'SetCount', 0, 0, 0) 
GO 
*/

create OR alter proc ENV_VAR_UPD8_MASS --auto-update environment variables 
 as BEGIN 
 declare @Tab nvarchar(50), @rowboat int, @oar int, @SQLstring nvarchar(500)
 set @rowboat = (select Count(PK) from META_ENV_VAR)
 while @rowboat > 0
  BEGIN
   set @oar = (select Min(PK) from META_ENV_VAR)
   set @SQLstring = 'exec dbo.ENV_VAR_UPD8 N''' + (select NameOfTable from META_ENV_VAR where PK = @oar) + ''''
   EXEC sp_executesql @SQLstring
   --exec dbo.ENV_VAR_UPD8 @ForTable = @Tab 
   set @rowboat = @rowboat - 1 
  END 
 END 
GO 

/*
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
*/

create OR alter function fetch_FormatIDbyMachineName (@FormatName varchar(25), @MediumAbbrev char(3))
 returns int 
 as BEGIN 
 declare @RET int 
 set @RET = (select F.FormatID from refFORMAT F 
  join defFORMAT_NAME FN on F.FormatNameID = FN.FormatNameID 
  join defFORMAT_MEDIUM FM on F.FormatMediumID = FM.FormatMediumID
  where FormatNameMachineReadable = @FormatName
   and FormatMediumAbbrev = @MediumAbbrev)
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
   set @repeats = @repeats + (select Count(DeckID) from tblDECK where UserID = @UserID and DeckName like @DeckName)
   set @RET = @DeckName + ' ' + Cast(@repeats as varchar)
  END 
  ELSE set @RET = @DeckName
 return @RET 
 END 
GO 

create OR alter function fetch_UserIDbyUsername (@UserName varchar(100))
 returns int 
 as BEGIN 
 declare @RET int 
 set @RET = (select UserID from tblUSER where UserName = @UserName)
 return @RET 
 END 
GO

create OR alter function fetch_UsernameByID (@UserID int)
 returns varchar(100) 
 as BEGIN 
 declare @RET varchar(100) 
 set @RET = (select UserName from tblUSER where UserID = @UserID)
 return @RET 
 END 
GO

create OR alter proc ADD_NewDeck 
 @ForUserName varchar(100),
 @InFormatID int NULL,
 @DeckNameString varchar(280) NULL,
 @WithMaindeck varchar(8000),
 @WithCMDR varchar(8000) NULL,
 @WithSIDE varchar(8000) NULL, 
 @WithMAYB varchar(8000) NULL,
 @WithWISH varchar(8000) NULL,
 @IsPrivate char(1) NULL
 as BEGIN 
 set NOCOUNT ON 
 declare @CommandZoneID int, @SideZoneID int, @MaybeZoneID int, @WishZoneID int, @DeckName varchar(350), @DeckID int, @side Unlisted, @maybe Unlisted, @cmdr Unlisted, @wish Unlisted, @main Unlisted, @UserID int 
 set @UserID = dbo.fetch_UserIDbyUsername(@ForUserName)
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
 exec dbo.ADD_NewDeck 
  @ForUserName = @UserName,
  @InFormatID = NULL, --format isn't mandatory so let's not spoof that for now (I have reasons)
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


exec dbo.ENV_VAR_UPD8_MASS

delete from tblDECK_CARD 

select UserID, Count(DeckID) from tblDECK group by UserID order by Count(DeckID) desc 

with CheckMultiDeckUsers (UserID) as (
 select UserID from tblDECK group by UserID having Count(DeckID) > 1
)
select DeckID, DeckName from tblDECK D 
 join CheckMultiDeckUsers C on D.UserID = C.UserID ; 

exec dbo.SPAGHETTI_decking_AUTO 1000

select DeckID, Sum(Quantity) from tblDECK_CARD group by DeckID 

select * from META_ENV_VAR

exec dbo.ENV_VAR_UPD8 N'tblSET'
select * from META_ENV_VAR




exec dbo.ADD_NewDeck 
 @ForUserName = 'Emperor', 
 @InFormatID = 6,
 @DeckNameString = 'warmer than wine', 
 @WithMaindeck = 'Ancient Ziggurat|Anointed Procession|Arcane Signet|Black Market|Blood Artist|Bloodcrazed Paladin|Bloodline Keeper|Bojuka Bog|Boros Charm|Boros Garrison|Brightclimb Pathway|Captivating Vampire|Cathars Crusade|Chance for Glory|Coat of Arms|Command Tower|Cordial Vampire|Cruel Celebrant|Dark Impostor|Darksteel Ingot|Door of Destinies|Drana Liberator of Malakir|Drana the Last Bloodchief|Dusk|Dawn|Evolving Wilds|Exquisite Blood|Falkenrath Gorger|Feed the Swarm|Force of Despair|Go for the Throat|Guul Draz Assassin|Heralds Horn|Indulgent Aristocrat|Indulging Patrician|Isolated Chapel|Kalastria Highborn|Kindred Charge|Knight of the Ebon Legion|Legions Landing|Luxury Suite|Malakir Rebirth|Mathas Fiend Seeker|Merciless Eviction|Metallic Mimic|Mountain|Mountain|Mountain|New Blood|Nighthawk Scavenger|Nomad Outpost|Nullpriest of Oblivion|Obelisk of Urd|Olivia Mobilized for War|Opal Palace|Orzhov Basilica|Path of Ancestry|Pawn of Ulamog|Pillar of Origins|Plains|Plains|Plains|Rakdos Carnarium|Rakdos Signet|Reliquary Tower|Return to Dust|Savai Triome|Shadow Alley Denizen|Skullclamp|Slate of Ancestry|Smoldering Marsh|Smothering Tithe|Sol Ring|Sorin Lord of Innistrad|Sorin Solemn Visitor|Spark Harvest|Stensia Masquerade|Stromkirk Captain|Swamp|Swamp|Swamp|Swamp|Swamp|Swamp|Swords to Plowshares|Teferis Protection|Temple of the False God|Terramorphic Expanse|Thriving Bluff|Thriving Heath|Thriving Moor|Twilight Prophet|Unclaimed Territory|Valakut Awakening|Vampire Nocturnus|Vances Blasting Cannons|Vanquishers Banner|Vault of Champions|Vito Thorn of the Dusk Rose|Yahenni Undying Partisan',
 @WithCMDR = 'Edgar Markov', 
 @WithSIDE = NULL,
 @WithMAYB = NULL,
 @WithWISH = NULL,
 @IsPrivate = NULL 


select U.UserID, D.DeckID, DC.CardFaceID, DC.Quantity from tblDECK_CARD DC 
 join tblDECK D on DC.DeckID = D.DeckID 
 join tblUSER U on D.UserID = U.UserID 
 where U.UserName = 'Emperor'

--delete from tblDECK where UserID = 1

select * from tblDECK D 
 where D.UserID = 1 

select * from tblDECK_CARD where DeckID = 4231


with Edgar (Quantity, CardFaceSearchName, CardID)
as (
select DC.Quantity, CF.CardFaceSearchName, CF.CardID from tblDECK_CARD DC 
 join tblCARD_FACE CF on DC.CardFaceID = CF.CardFaceID 
 where DeckID = 4231
 group by DeckID, DC.Quantity, CF.CardFaceSearchName, CF.CardID),
UseRankedCards (CardFaceID, CardFaceSearchName, CardRank) as (select CardFaceID, CardFaceSearchName, Dense_Rank() over (partition by CardFaceSearchName order by CardFaceID desc) as CardRank from tblCARD_FACE )

select * from UseRankedCards R 
 join Edgar E on R.CardFaceSearchName = E.CardFaceSearchName
 where CardRank = 1 