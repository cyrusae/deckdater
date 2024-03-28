IF EXISTS (select [name] from sys.databases
 where [name] = 'Info_430_deckdater')
 DROP DATABASE Info_430_deckdater 
GO 

create database Info_430_deckdater 
GO 

ALTER DATABASE Info_430_deckdater 
 set READ_COMMITTED_SNAPSHOT ON 
GO 

ALTER database Info_430_deckdater 
 ADD FILEGROUP dd_memop CONTAINS MEMORY_OPTIMIZED_DATA 
GO 

--for local it's 15.DAWNFIRE; remote is 14.MSSQLSERVER
ALTER DATABASE Info_430_deckdater 
 ADD FILE(name = 'dd_memop430',
    filename = 'C:\Program Files\Microsoft SQL Server\MSSQL15.DAWNFIRE\MSSQL\DATA\dd_memop430') 
    to FILEGROUP dd_memop
GO 

alter database Info_430_deckdater 
 SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = ON ; 

use Info_430_deckdater
GO

--use to generate random usernames:
create table UN_StopWords (
 PK int Identity(1,1) primary key NOT NULL,
 StopWord varchar(10) unique NOT NULL)

create table UN_Wordle (
 PK int Identity(1,1) primary key NOT NULL,
 Wordle char(5) unique NOT NULL)

--use to track variables for randomization:
create table META_ENV_VAR (
 PK int Identity(1,1) primary key NOT NULL,
 TableName nvarchar(50) unique NOT NULL,
 IndexedOn nvarchar(50) NOT NULL,
 nrow int DEFAULT 0,
 smallest int DEFAULT 0,
 biggest int DEFAULT 0)
GO 

--users, cards, decks:
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
 IsInactive char(1) SPARSE NULL)

insert into tblUSER (UserDOB, Email, FirstName, LastName, UserName)
 VALUES ('1993-09-20', 'martin.e.durham@outlook.com', 'Martin', 'Durham Eosphoros', 'Emperor'), ('1995-08-03', 'cyrus.eosphoros@gmail.com', 'Cyrus', 'Eosphoros', 'Magician') --two manually-entered test users for reasons that will become apparent eventually, and also because I am gay 

create table defLAYOUT (
 LayoutID int Identity(1,1) primary key NOT NULL,
 LayoutName varchar(25) unique NOT NULL,
 LayoutNameHumanReadable varchar(25) NULL,
 LayoutDesc varchar(500) NULL)

create table defFACE (
 FaceID int Identity(1,1) primary key NOT NULL,
 FaceName varchar(25) unique NOT NULL,
 FaceDesc varchar(500) NULL)
GO 

create table refLAYOUT_FACE (
 LayoutFaceID int Identity(1,1) primary key NOT NULL,
 LayoutID int FOREIGN KEY references defLAYOUT NOT NULL,
 FaceID int FOREIGN KEY references defFACE NOT NULL,
 LayoutFaceDesc varchar(500) NULL,
 Constraint OneFaceInstancePerLayout UNIQUE (LayoutID, FaceID))

create table tblCARD (
 CardID varchar(36) primary key NONCLUSTERED NOT NULL,
 CardCount int Identity(1,1) NOT NULL)
GO

create CLUSTERED index SandCountingCards on tblCARD (CardCount)
GO 

create table tblCARD_FACE (
 CardFaceID int Identity(1,1) primary key NOT NULL,
 CardID varchar(36) FOREIGN KEY references tblCARD ON DELETE CASCADE,
 LayoutFaceID int FOREIGN KEY references refLAYOUT_FACE NOT NULL,
 CardFaceName varchar(200) NOT NULL,
 CardFaceSearchName varchar(200) unique NOT NULL)
GO 

create table defRARITY (
 RarityID int Identity(1,1) primary key NOT NULL,
 RarityName varchar(25) unique NOT NULL,
 RarityDesc varchar(500) NULL)

create table defSUPERTYPE (
 SupertypeID int Identity(1,1) primary key NOT NULL,
 SupertypeName varchar(25) unique NOT NULL)

create table defTYPE (
 TypeID int Identity(1,1) primary key NOT NULL,
 TypeName varchar(25) unique NOT NULL)

--note: types--and supertypes even more than that--are fixed to the point that introducing a new one would probably be news on, like, Kotaku/Gizmodo. ETL can check for new types in future but the bulk of the heavy "new thing to look up" lifting happens at subtypes.
GO 

create table defSUBTYPE (
 SubtypeID int Identity(1,1) primary key NOT NULL,
 SubtypeName varchar(50) unique NOT NULL)
GO 

create OR alter function fn_chk_TypeLineDuplicates()
 returns int 
 as BEGIN 
 declare @RET int 
 set @RET = (select Count(TypeID) from defTYPE T 
  join defSUPERTYPE S on T.TypeName = S.SupertypeName) + 
  (select Count(TypeID) from defTYPE T
  join defSUBTYPE S on T.TypeName = S.SubtypeName) + 
  (select Count(SupertypeID) from defSUPERTYPE S
   join defSUBTYPE B on S.SupertypeName = B.SubtypeName)
 return @RET 
 END 
GO 

alter table defSUPERTYPE 
 add CONSTRAINT UniqueSupertypes 
  CHECK (dbo.fn_chk_TypeLineDuplicates() = 0)
GO 

alter table defTYPE
 add CONSTRAINT UniqueTypes 
  CHECK (dbo.fn_chk_TypeLineDuplicates() = 0)
GO 

alter table defSUBTYPE 
 add CONSTRAINT UniqueSubtypes 
  CHECK (dbo.fn_chk_TypeLineDuplicates() = 0)
  --if something is wrong in type line I'd rather everything grind to a halt really 
GO 

create table tblCARD_FACE_SUPERTYPE (
 PK int Identity(1,1) primary key NOT NULL, --this is a subtype (ironic) relationship but updates that somehow dropped and then re-added something to the type line would break import, hence adding PKs back in.
 SupertypeID int FOREIGN KEY references defSUPERTYPE ON DELETE CASCADE,
 CardFaceID int FOREIGN KEY references tblCARD_FACE ON DELETE CASCADE,
 Constraint ListSupertypeOnce UNIQUE (SupertypeID, CardFaceID))

create table tblCARD_FACE_TYPE (
 PK int Identity(1,1) primary key NOT NULL,
 TypeID int FOREIGN KEY references defTYPE ON DELETE CASCADE,
 CardFaceID int FOREIGN KEY references tblCARD_FACE ON DELETE CASCADE,
 Constraint ListTypeOnce UNIQUE (TypeID, CardFaceID))

create table tblCARD_FACE_SUBTYPE (
 PK int Identity(1,1) primary key NOT NULL,
 SubtypeID int FOREIGN KEY references defSUBTYPE ON DELETE CASCADE,
 CardFaceID int FOREIGN KEY references tblCARD_FACE ON DELETE CASCADE,
 Constraint ListSubtypeOnce UNIQUE (SubtypeID, CardFaceID))
GO 

create OR alter function fn_chk_CardFaceTypes (@PK int)
 returns int 
 as BEGIN 
 declare @RET int 
 set @RET = (select Count(CardFaceID) from tblCARD_FACE_TYPE 
  where CardFaceID = @PK)
 return @RET 
 END 
GO 

create table tblBLOCK (
 BlockID int Identity(1,1) primary key NOT NULL,
 BlockCode char(3) unique NOT NULL,
 BlockName varchar(200) unique NOT NULL)
GO 

create table defSET_TYPE (
 SetTypeID int Identity(1,1) primary key NOT NULL,
 SetTypeName varchar(25) unique NOT NULL,
 SetTypeDesc varchar(500) NULL)

create table defSET_STATUS (
 SetStatusID int Identity(1,1) primary key NOT NULL,
 SetStatusName varchar(25) unique NOT NULL,
 SetStatusDesc varchar(500) NULL)

insert into defSET_STATUS (SetStatusName, SetStatusDesc) 
 VALUES ('legal', 'Exceptions will be bans and restrictions, within applicable time'), ('not_legal', 'Exceptions will be... acorn stamp mostly')

create table defFORMAT_TYPE (
 FormatTypeID int Identity(1,1) primary key NOT NULL,
 FormatTypeName varchar(25) unique NOT NULL,
 FormatTypeDesc varchar(500) NULL)

insert into defFORMAT_TYPE (FormatTypeName, FormatTypeDesc)
 VALUES ('Eternal', 'Cards are legal by default'), ('Era', 'Cards are legal when printed in a timespan (usually based on a begin date only)'), ('Rotating', 'Cards are conditionally legal, based on date printed, for a fixed span of time')

create table defFORMAT_NAME (
 FormatNameID int Identity(1,1) primary key NOT NULL,
 FormatName varchar(100) NULL,
 FormatNameMachineReadable varchar(50) unique NOT NULL,
 FormatAlias varchar(50) NULL,
 FormatNameDesc varchar(500) NULL)
GO 

create table refFORMAT (
 FormatID int Identity(1,1) primary key NOT NULL,
 FormatNameID int FOREIGN KEY references defFORMAT_NAME NOT NULL, 
 FormatTypeID int FOREIGN KEY references defFORMAT_TYPE NOT NULL,
 FormatDesc varchar(500) NULL)
GO 

create table refFORMAT_EPOCH (
 FormatID int FOREIGN KEY references refFORMAT NOT NULL,
 EpochBeginDate date NOT NULL,
 EpochEndDate date NULL,
 Constraint OneEpochPerFormat PRIMARY KEY (FormatID))
GO 

create OR alter function fn_check_FormatEpochRelevance (@PK int)
 returns int 
 as BEGIN 
 declare @RET int 
 set @RET = (select Count(FormatID) from refFORMAT F 
  join defFORMAT_TYPE T on F.FormatTypeID = T.FormatTypeID 
  where FormatID = @PK 
   and FormatTypeName != 'Era')
 return @RET 
 END 
GO 

alter table refFORMAT_EPOCH 
 ADD constraint EraFormatsHaveEpochs 
  CHECK (dbo.fn_check_FormatEpochRelevance(FormatID) = 0)
GO 

create table tblSET (
 SetID varchar(36) primary key NONCLUSTERED NOT NULL,
 SetCount int Identity(1,1) NOT NULL,
 SetCode char(3) unique NOT NULL,
 SetName varchar(200),
 SetReleaseDate date NOT NULL,
 SetTypeID int FOREIGN KEY references defSET_TYPE NOT NULL,
 SetCollectorCount int,
 SetScryfallURI varchar(500),
 SetScryfallAPI varchar(500),
 BlockID int FOREIGN KEY references tblBLOCK NULL,
 SetIsDigital char(1) SPARSE NULL)
GO 

create CLUSTERED INDEX SandCountsSets on tblSET (SetCount)
GO 

create table tblCARD_FACE_SET (
 CardFaceSetID int Identity(1,1) primary key NOT NULL,
 CardFaceID int FOREIGN KEY references tblCARD_FACE ON DELETE CASCADE,
 SetID varchar(36) FOREIGN KEY references tblSET ON DELETE CASCADE,
 RarityID int FOREIGN KEY references defRARITY,
 IsReprint char(1) SPARSE NULL,
 Constraint OnePrintingPerSet UNIQUE (CardFaceID, SetID))
GO 

create table defPLATFORM (
 PlatformID int Identity(1,1) primary key NOT NULL,
 PlatformName varchar(10) unique NOT NULL,
 PlatformDesc varchar(250) NULL)
GO

create table tblCARD_FACE_SET_PLATFORM (
 CardFaceSetID int FOREIGN KEY references tblCARD_FACE_SET ON DELETE CASCADE,
 PlatformID int FOREIGN KEY references defPLATFORM NOT NULL,
 CardSetPlatformScryfallURI varchar(500) NULL,
 CardSetPlatformScryfallAPI varchar(500) NULL,
 Constraint OnePrintingPerSetPerPlatform PRIMARY KEY (CardFaceSetID, PlatformID))
GO


create table tblDECK (
 DeckID int Identity(1,1) primary key NOT NULL,
 UserID int FOREIGN KEY references tblUSER ON DELETE CASCADE,
 DeckName varchar(350) NOT NULL,
 DeckDesc varchar(500) NULL,
 DateCreated datetime DEFAULT GetDate(),
 DateUpdated datetime NULL,
 IsPrivate char(1) SPARSE NULL,
 Constraint UniqueDeckNamesPerUser UNIQUE (UserID, DeckName))
GO 

create table tblDECK_FORMAT (
 DeckID int FOREIGN KEY references tblDECK ON DELETE CASCADE,
 FormatID int FOREIGN KEY references refFORMAT NOT NULL,
 Constraint DeckFormatIsSubtype primary key (DeckID))

create table defZONE (
 ZoneID int Identity(1,1) primary key NOT NULL,
 ZoneName char(4) unique NOT NULL,
 ZoneDesc varchar(500) NULL)
GO 

create table tblDECK_CARD (
 DeckID int FOREIGN KEY references tblDECK ON DELETE CASCADE,
 CardFaceID int FOREIGN KEY references tblCARD_FACE ON DELETE CASCADE,
 Quantity int DEFAULT 1,
 Constraint ListCardsOncePerDeck PRIMARY KEY (DeckID, CardFaceID)) --this *should* interact as intended with nullables (list once in maindeck, separate for e.g. sideboarding extras)

create table tblCARD_HAPAX (
 CardID varchar(36) FOREIGN KEY references tblCARD ON DELETE CASCADE,
 BeginDate date NOT NULL,
 EndDate date NULL,
 Constraint CardsHapaxOnce PRIMARY KEY (CardID)
)

create table tblDECK_CARD_ZONE (
 DeckID int FOREIGN KEY references tblDECK ON DELETE CASCADE,
 ZoneID int FOREIGN KEY references defZONE NOT NULL, 
 CardFaceID int FOREIGN KEY references tblCARD_FACE ON DELETE CASCADE,
 Quantity int DEFAULT 1,
 Constraint ListCardsOncePerDeckZone PRIMARY KEY (DeckID, ZoneID, CardFaceID))
GO --this should be all tables required for deckdating only.

--imports holders:
create table SCRY_CANON_SETS (
 PK int Identity(1,1) primary key NOT NULL,
 SetID varchar(36),
 SetCode varchar(5),
 SetName varchar(200),
 SetReleaseDate date NOT NULL,
 SetTypeName varchar(25),
 SetCollectorCount int,
 SetScryfallURI varchar(500),
 SetScryfallAPI varchar(500),
 BlockCode varchar(5) NULL,
 SetIsDigital varchar(5) NULL)

create table SCRY_CANON_CARDS (
 PK int Identity(1,1) primary key NOT NULL,
 CardID varchar(40),
 CardFaceName varchar(200),
 CardFaceSearchName varchar(200),
 CardSetScryfallAPI varchar(300),
 CardSetScryfallURI varchar(300),
 LayoutName varchar(25),
 FaceName varchar(25),
 Supertypes varchar(200) NULL,
 Types varchar(200),
 Subtypes varchar(200) NULL,
 SetID varchar(40),
 RarityName varchar(25),
 PlatformName varchar(25),
 IsReprint varchar(5) NULL)
GO 

select * into STAGE_CARDS from SCRY_CANON_CARDS where 1=0
alter table STAGE_CARDS 
 drop column PK 

select * into STAGE_SETS from SCRY_CANON_SETS where 1=0
alter table STAGE_SETS 
 drop column PK 
GO 

create OR alter proc UNSTAGE_SetsExisting 
 as BEGIN 
 set NOCOUNT ON 
 if exists (select SetID from STAGE_SETS)
  BEGIN 
   begin tran addsets
   insert into SCRY_CANON_SETS (SetID, SetCode, SetName, SetReleaseDate, SetTypeName, SetCollectorCount, SetScryfallURI, SetScryfallAPI, BlockCode, SetIsDigital)
    select SetID, SetCode, SetName, SetReleaseDate, SetTypeName, SetCollectorCount, SetScryfallURI, SetScryfallAPI, BlockCode, SetIsDigital from STAGE_SETS 
   commit 
   truncate table STAGE_SETS 
  END 
 END 
GO 
GO 

create OR alter proc UNSTAGE_CardsExisting 
 as BEGIN 
 set NOCOUNT ON 
 if exists (select CardID from STAGE_CARDS)
  BEGIN 
   begin tran addcards 
   insert into SCRY_CANON_CARDS (CardID, CardFaceName, CardFaceSearchName, CardSetScryfallAPI, CardSetScryfallURI, LayoutName, FaceName, Supertypes, Types, Subtypes, SetID, RarityName, PlatformName, IsReprint)
    select CardID, CardFaceName, CardFaceSearchName, CardSetScryfallAPI, CardSetScryfallURI, LayoutName, FaceName, Supertypes, Types, Subtypes, SetID, RarityName, PlatformName, IsReprint from STAGE_CARDS
   commit 
   truncate table STAGE_CARDS 
  END 
 END 
GO 

--manual insert for the small lookup tables:

insert into META_ENV_VAR (TableName, IndexedOn)
 VALUES (N'UN_Wordle', N'PK'), (N'UN_StopWords', N'PK'), (N'tblCARD', N'CardCount'), (N'tblSET', N'SetCount'), (N'tblCARD_FACE', N'CardFaceID'), (N'tblCARD_FACE_SET', N'CardFaceSetID'), ('refFORMAT', 'FormatID'), (N'tblUSER', N'UserID'), (N'tblDECK', N'DeckID')
GO 

insert into defFACE (FaceName, FaceDesc)
 VALUES ('default', 'Front face'), ('naming', 'Back, transformed, otherwise contributes to name with own name'), ('alternate', 'Melded, specialized, otherwise does not contribute to name and has own name')

insert into defTYPE (TypeName)
 VALUES ('Land'), ('Instant'), ('Sorcery'), ('Enchantment'), ('Artifact'), ('Creature'), ('Planeswalker'), ('Tribal'), ('Conspiracy'), ('Plane'), ('Phenomenon'), ('Scheme'), ('Vanguard'), ('Dungeon') 

insert into defSUPERTYPE (SupertypeName)
 VALUES ('Basic'), ('Legendary'), ('Snow'), ('World'), ('Ongoing'), ('Elite'), ('Host'), ('Token'), ('Emblem') --Token and Emblem aren't a "real" card supertype, it's another kind of object, but we're doing that here for now for reasons that will be apparent another day.

insert into defPLATFORM (PlatformName, PlatformDesc) 
 VALUES ('paper', 'Traditionally-printed Magic; the "canonical" default'), ('mtgo', 'Magic: the Gathering Online'), ('arena', 'Magic: the Gathering Arena (includes Rebalanced cards)')

insert into defRARITY (RarityName)
 VALUES ('common'), ('uncommon'), ('rare'), ('mythic')

insert into defZONE (ZoneName, ZoneDesc)
 VALUES ('CMDR', 'Command zone (Commander and Background)'), ('SIDE', 'Sideboard'), ('MAYB', 'Maybeboard'), ('WISH', 'Wishboard') --I still don't know if chosen companions are technically something else.

insert into defFORMAT_NAME (FormatNameMachineReadable, FormatAlias)
 VALUES ('standard', 'Standard'), ('explorer', 'Explorer'), ('pioneer', 'Pioneer'), ('gladiator', 'Gladiator'), ('alchemy', 'Alchemy'), ('historic', 'Historic'), ('commander', 'EDH'), ('paupercommander', 'Pauper EDH'), ('historicbrawl', 'Historic Brawl'), ('modern', 'Modern'), ('vintage', 'Vintage'), ('legacy', 'Legacy'), ('brawl', 'Brawl')
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

create OR alter proc get_RandomWordleWord 
 @WordlePK int OUT 
 as BEGIN 
 exec dbo.GET_RANDOM_ROW N'UN_Wordle', @WordlePK OUT 
 END 
GO 

create OR alter function fetch_WordleByPK (
 @PK int
) returns char(5)
 as BEGIN 
 declare @RET char(5)
 set @RET = (select Wordle from UN_Wordle where PK = @PK)
 return @RET 
 END 
GO 

create OR alter proc get_RandomStopWord 
 @StopPK int OUT 
 as BEGIN 
 exec dbo.GET_RANDOM_ROW N'UN_StopWords', @StopPK OUT 
 END 
GO 

create OR alter function fetch_StopByPK (
 @PK int
) returns varchar(10)
 as BEGIN 
 declare @RET varchar(10)
 set @RET = (select StopWord from UN_StopWords where PK = @PK)
 return @RET 
 END 
GO 

create OR alter function fetch_UserIDbyUserName (
 @UserName varchar(100)
) returns INT 
 as BEGIN 
 declare @RET int 
 set @RET = (select UserID from tblUSER 
  where UserName = @UserName)
 return @RET 
 END 
GO 

create OR alter function fetch_UserNamebyID (
 @UserID int
) returns int 
 as BEGIN 
 declare @RET varchar(100)
 set @RET = (select UserName from tblUSER 
  where UserID = @UserID)
 return @RET 
 END 
GO 

create OR alter function fetch_DeckIDbyName (
 @UserName varchar(100),
 @DeckName varchar(350)
) returns INT 
 as BEGIN 
 declare @RET int 
 set @RET = (select DeckID from tblDECK D 
  join tblUSER U on D.UserID = U.UserID 
  where UserName = @UserName 
   and DeckName = @DeckName)
 return @RET 
 END 
GO 

create OR alter function fetch_FormatTypeIDbyName (
 @FormatTypeName varchar(25)
) returns INT 
 as BEGIN 
 declare @RET int 
 set @RET = (select FormatTypeID 
  from defFORMAT_TYPE
  where FormatTypeName = @FormatTypeName)
 return @RET 
 END 
GO 

create OR alter function fetch_FormatNameIDbyMachine (
 @FormatMachineName varchar(25)
) returns INT 
 as BEGIN 
 declare @RET int 
 set @RET = (select FormatNameID from defFORMAT_NAME 
  where FormatNameMachineReadable = @FormatMachineName)
 return @RET 
 END 
GO 

create OR alter function fetch_FormatIDbyMachineName(
 @FormatMachineName varchar(25)
) returns INT 
 as BEGIN 
 declare @RET int, @NameID int 
 set @NameID = dbo.fetch_FormatNameIDbyMachine(@FormatMachineName)
 set @RET = (select Top 1 FormatID from refFORMAT 
  where FormatNameID = @NameID
  order by FormatID desc) --the order by is to make this generic for later when subtyping of formats is implemented in a way I'm happy with, since there are cases where format subtyping doesn't matter to a lookup 
 return @RET 
 END 
GO 

create OR alter function fetch_ZoneIDbyName (
 @ZoneName char(4)
) returns INT 
 as BEGIN 
 declare @RET int 
 set @RET = (select ZoneID from defZONE 
  where ZoneName = @ZoneName)
 return @RET 
 END 
GO 

create OR alter function fetch_CardFaceIDbyName (
 @CardFaceSearchName varchar(100)
) returns INT 
 as BEGIN 
 declare @RET int 
 set @RET = (select CardFaceID from tblCARD_FACE 
  where CardFaceSearchName = @CardFaceSearchName)
 return @RET 
 END 
GO 

create OR alter function fetch_CardIDbyFaceName(
 @CardFaceSearchName varchar(100)
) returns varchar(36) 
 as BEGIN 
 declare @RET varchar(36), @CardFaceID int 
 set @CardFaceID = dbo.fetch_CardFaceIDbyName(@CardFaceSearchName)
 set @RET = (select CardID from tblCARD_FACE 
  where CardFaceID = @CardFaceID)
 return @RET 
 END 
GO 

--manual-ish format load 
create OR alter proc a_ADD_NewFormats
 @TypeName varchar(25),
 @FormatString varchar(500)
 as BEGIN 
 declare @TypeID int 
 set @TypeID = dbo.fetch_FormatTypeIDbyName(@TypeName)
 if @TypeID is NULL 
  BEGIN 
   print 'Type not found!';
   throw 89356, 'Type ID not found. Check spelling, and remember Type input is one at a time here.', 14;
  END ;
 
 with FormatsInvolved (FormatTypeID, FormatNameID) as (
  select @TypeID as FormatTypeID, FormatNameID 
   from defFORMAT_NAME FN 
   join STRING_SPLIT(@FormatString, ',')
    on value = FormatNameMachineReadable)
 
 insert into refFORMAT (FormatTypeID, FormatNameID) 
  select FormatTypeID, FormatNameID 
   from FormatsInvolved 
   except (select F.FormatTypeID, F.FormatNameID 
    from refFORMAT F 
    join FormatsInvolved FI on (F.FormatTypeID = FI.FormatTypeID 
     and F.FormatNameID = FI.FormatNameID)) ;
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

select * into STAGE_CARDS from SCRY_CANON_CARDS where 1=0
alter table STAGE_CARDS 
 drop column PK 

select * into STAGE_SETS from SCRY_CANON_SETS where 1=0
alter table STAGE_SETS 
 drop column PK 
GO 

create OR alter proc UNSTAGE_SetsExisting 
 as BEGIN 
 set NOCOUNT ON 
 if exists (select SetID from STAGE_SETS)
  BEGIN 
  begin tran 
   begin tran addsets
   insert into SCRY_CANON_SETS (SetID, SetCode, SetName, SetReleaseDate, SetTypeName, SetCollectorCount, SetScryfallURI, SetScryfallAPI, BlockCode, SetIsDigital)
    select SetID, SetCode, SetName, SetReleaseDate, SetTypeName, SetCollectorCount, SetScryfallURI, SetScryfallAPI, BlockCode, SetIsDigital from STAGE_SETS 
   commit 
   truncate table STAGE_SETS 
  commit 
  END 
 END 
GO 
GO 

create OR alter proc UNSTAGE_CardsExisting 
 as BEGIN 
 set NOCOUNT ON 
 if exists (select CardID from STAGE_CARDS)
  BEGIN 
  begin tran 
   begin tran addcards 
   insert into SCRY_CANON_CARDS (CardID, CardFaceName, CardFaceSearchName, CardSetScryfallAPI, CardSetScryfallURI, LayoutName, FaceName, Supertypes, Types, Subtypes, SetID, RarityName, PlatformName, IsReprint)
    select CardID, CardFaceName, CardFaceSearchName, CardSetScryfallAPI, CardSetScryfallURI, LayoutName, FaceName, Supertypes, Types, Subtypes, SetID, RarityName, PlatformName, IsReprint from STAGE_CARDS
   commit 
   truncate table STAGE_CARDS 
  commit 
  END 
 END 
GO 


create OR alter trigger t_AddCanonSets on SCRY_CANON_SETS 
 after INSERT 
 as BEGIN 

 if @@ROWCOUNT < 1 RETURN ; 
 set NOCOUNT ON 
 begin tran ImportSets 
 begin tran SetData 
 select i.SetID, S.SetID as OldSetID, i.SetCode, i.SetName, i.SetReleaseDate, T.SetTypeID, i.SetCollectorCount, i.SetScryfallURI, i.SetScryfallAPI, B.BlockID, i.SetIsDigital into #inserted  
  from inserted i 
  join defSET_TYPE T on i.SetTypeName = T.SetTypeName 
  LEFT join tblBLOCK B on Cast(i.BlockCode as char(3)) = B.BlockCode 
  LEFT join tblSET S on i.SetID = S.SetID 
 commit 
 begin tran InsertionBatch 
 create NONCLUSTERED index ix_ins_SetID on #inserted (SetID)
 
 insert into tblSET (SetID, SetCode, SetName, SetReleaseDate, SetTypeID, SetCollectorCount, SetScryfallURI, SetScryfallAPI, BlockID, SetIsDigital)
  select SetID, SetCode, SetName, SetReleaseDate, SetTypeID, SetCollectorCount, SetScryfallURI, SetScryfallAPI, BlockID, SetIsDigital from #inserted 
  where OldSetID is NULL 
 commit 
 begin tran UpdateBatch 
 update tblSET 
  set SetReleaseDate = i.SetReleaseDate, 
   SetTypeID = i.SetTypeID,
   SetCollectorCount = i.SetCollectorCount,
   SetScryfallURI = i.SetScryfallURI,
   SetScryfallAPI = i.SetScryfallAPI,
   BlockID = i.BlockID,
   SetIsDigital = i.SetIsDigital 
  from #inserted i 
   join tblSET S on i.SetID = S.SetID 
    where (i.SetReleaseDate != S.SetReleaseDate 
      and i.SetReleaseDate is NOT NULL)
     or (i.SetTypeID != S.SetTypeID 
      and i.SetTypeID is NOT NULL)
     or (i.SetCollectorCount > S.SetCollectorCount 
      or S.SetCollectorCount is NULL)
     or (i.SetScryfallURI != S.SetScryfallURI 
      and i.SetScryfallURI is NOT NULL)
     or (i.SetScryfallAPI != S.SetScryfallAPI 
      and i.SetScryfallAPI is NOT NULL) 
     or (i.BlockID != S.BlockID 
      and S.BlockID is NULL)
  commit 
 delete from SCRY_CANON_SETS 
  where SetID in (select SetID from #inserted)
 drop index ix_ins_SetID on #inserted 
 drop table #inserted 
 commit 
 END 
GO 

create OR alter trigger t_AddCanonCards on SCRY_CANON_CARDS 
 after INSERT 
 as BEGIN 
 
 if @@ROWCOUNT < 1 RETURN ;
 set NOCOUNT ON 
 begin tran prep  

 begin tran CheckPrecursors 
 if exists (select SetID from STAGE_SETS) 
  BEGIN 
   print 'WARNING: Cannot load cards without unstaging sets first. Executing sets loader.';
   exec dbo.UNSTAGE_SetsExisting 
   print 'Set unstaging attempted. wARNING: This card insertion should be considered high-risk; reevaluate pipeline.';
  END 
 commit 

 select * into #inserted from inserted 

 alter table #inserted 
  Add Constraint temp_ins_PK PRIMARY KEY NONCLUSTERED (PK)

 create NONCLUSTERED INDEX ix_ins_CardID on #inserted(CardID)
 INCLUDE (CardFaceSearchName, LayoutName, FaceName, SetID)

 begin tran CheckNewSets 
  if (select Count(i.SetID) from #inserted i 
   where i.SetID not in (select SetID from tblSET S)) > 0
   BEGIN 
    print 'WARNING: Attempted card import with a nonexisting set! Cards in that set will be deleted at join with no remaining records. Check pipeline integrity.';
   END 
 commit 

 select i.PK as PK, i.CardID as CardID, C.CardID as OldCardID, CF.CardFaceID as CardFaceID, i.CardFaceName as CardFaceName, i.CardFaceSearchName as CardFaceSearchName, LF.LayoutFaceID as LayoutFaceID, i.Supertypes as SupertypeList, i.Types as TypeList, i.Subtypes as SubtypeList, CFS.CardFaceSetID as CardFaceSetID, i.SetID as SetID, P.PlatformID as PlatformID, i.CardSetScryfallURI as ScryfallURI, i.CardSetScryfallAPI as ScryfallAPI, R.RarityID as RarityID, Cast(i.IsReprint as char(1)) as IsReprint into #processing
  from #inserted i 
  join defPLATFORM P on i.PlatformName = P.PlatformName 
  join defRARITY R on i.RarityName = R.RarityName 
  join defLAYOUT L on i.LayoutName = L.LayoutName 
  join defFACE F on i.FaceName = F.FaceName
  join refLAYOUT_FACE LF 
   on (L.LayoutID = LF.LayoutID 
       AND F.FaceID = LF.FaceID)
  LEFT join tblCARD C on i.CardID = C.CardID 
  LEFT join tblCARD_FACE CF 
   on (i.CardID = CF.CardID 
      AND i.CardFaceSearchName = CF.CardFaceSearchName 
      AND LF.LayoutFaceID = CF.LayoutFaceID)
  LEFT join tblCARD_FACE_SET CFS 
   on (i.SetID = CFS.SetID 
      AND CF.CardFaceID = CFS.CardFaceID) 
  group by i.PK, i.CardID, C.CardID, CF.CardFaceID, i.CardFaceName, i.CardFaceSearchName, LF.LayoutFaceID, i.Supertypes, i.Types, i.Subtypes, CFS.CardFaceSetID, i.SetID, P.PlatformID, i.CardSetScryfallURI, i.CardSetScryfallAPI, R.RarityID, i.IsReprint
 
 alter table #processing 
  Add Constraint temp_procss_PK PRIMARY KEY NONCLUSTERED (PK)

 create NONCLUSTERED index ix_process_CardID on #processing(CardID)
  INCLUDE (CardFaceID, CardFaceSearchName, CardFaceSetID, SetID, PlatformID)
 commit 

 begin tran CardImport 
 begin tran DoCards 
 insert into tblCARD (CardID)
  select distinct CardID from #processing 
   where OldCardID is NULL 
  group by CardID 
 commit 
 
 begin tran DoFaces 
 select CF.CardID, CF.CardFaceID, P.LayoutFaceID, P.CardFaceName, P.CardFaceSearchName into #oldcards 
  from #processing p 
  join tblCARD_FACE CF on (p.CardID = CF.CardID 
   and p.CardFaceSearchName = CF.CardFaceSearchName 
   and p.LayoutFaceID = CF.LayoutFaceID)
  group by CF.CardID, CF.CardFaceID, P.LayoutFaceID, P.CardFaceName, P.CardFaceSearchName
 
 select CardID, LayoutFaceID, CardFaceName, CardFaceSearchName into #newfaces 
  from #processing p 
  except (select CardID, LayoutFaceID, CardFaceName, CardFaceSearchName from #oldcards)

 insert into tblCARD_FACE (CardID, LayoutFaceID, CardFaceName, CardFaceSearchName)
  select CardID, LayoutFaceID, CardFaceName, CardFaceSearchName 
   from #newfaces p
 commit 

 begin tran ReDoFaces 
 update #processing 
  set CardFaceID = CF.CardFaceID 
   from tblCARD_FACE CF 
    join #processing p
     on (CF.CardFaceSearchName = p.CardFaceSearchName 
      and CF.CardID = p.CardID)
    where p.CardFaceID is NULL 
   commit ;
 
 begin tran DoTypeLine 
 select CardFaceID, SupertypeList, TypeList, SubtypeList into #typelineprocessing 
  from #processing 
  group by CardFaceID, SupertypeList, TypeList, SubtypeList ; 

 with SupertypeLine (CardFaceID, SupertypeName) as (
 select CardFaceID, Trim(value) as SupertypeName 
  from #typelineprocessing 
  CROSS APPLY String_Split(SupertypeList, ' ')
  where SupertypeList is NOT NULL)

 insert into tblCARD_FACE_SUPERTYPE (CardFaceID, SupertypeID)
  select p.CardFaceID, S.SupertypeID 
  from SupertypeLine p 
   join defSUPERTYPE S on p.SupertypeName = S.SupertypeName
   except (select CardFaceID, SupertypeID from tblCARD_FACE_SUPERTYPE) ;

 with TypeLine (CardFaceID, TypeName) as (
  select CardFaceID, Trim(value) as TypeName 
  from #typelineprocessing 
  CROSS APPLY String_Split(TypeList, ' '))

 insert into tblCARD_FACE_TYPE (CardFaceID, TypeID) 
  select p.CardFaceID, T.TypeID 
  from TypeLine p 
  join defTYPE T on p.TypeName = T.TypeName 
  except (select CardFaceID, TypeID from tblCARD_FACE_TYPE) ;

 with SubtypeLine (CardFaceID, SubtypeName) as (
  select CardFaceID, Trim(value) as SubtypeName 
  from #typelineprocessing 
  CROSS APPLY String_Split(SubtypeList, ' ')
  where SubtypeList is NOT NULL)

 insert into tblCARD_FACE_SUBTYPE (CardFaceID, SubtypeID)
  select p.CardFaceID, S.SubtypeID 
  from SubtypeLine p 
  join defSUBTYPE S on p.SubtypeName = S.SubtypeName 
  except (select CardFaceID, SubtypeID from tblCARD_FACE_SUBTYPE) ;
 commit 

 begin tran DoPrintings 
 insert into tblCARD_FACE_SET (CardFaceID, SetID, RarityID, IsReprint)
  select CardFaceID, SetID, RarityID, IsReprint
  from #processing 
   where CardFaceSetID is NULL 
  group by CardFaceID, SetID, RarityID, IsReprint
 commit 

 begin tran ReDoPrintings 
 update #processing 
  set CardFaceSetID = CFS.CardFaceSetID 
  from tblCARD_FACE_SET CFS 
   join #processing p on (CFS.CardFaceID = p.CardFaceID 
    and CFS.SetID = p.SetID )
   where p.CardFaceSetID is NULL 

 update tblCARD_FACE_SET 
  set 
   RarityID = p.RarityID, 
   IsReprint = p.IsReprint
  from tblCARD_FACE_SET CFS 
   join #processing p on CFS.CardFaceSetID = p.CardFaceSetID 
   where CFS.RarityID != p.RarityID 
    OR CFS.IsReprint != p.IsReprint 
    
    commit ;

 begin tran DoPlatformInclusion 
 select CardFaceSetID, PlatformID, ScryfallURI, ScryfallAPI into #processplatform 
  from #processing p 
 
 MERGE tblCARD_FACE_SET_PLATFORM as TARGET 
  using #processplatform as SOURCE 
  on (TARGET.CardFaceSetID = SOURCE.CardFaceSetID 
    and TARGET.PlatformID = SOURCE.PlatformID)
  when MATCHED and (TARGET.CardSetPlatformScryfallURI != SOURCE.ScryfallURI or TARGET.CardSetPlatformScryfallAPI != SOURCE.ScryfallAPI) 
   THEN update set TARGET.CardSetPlatformScryfallURI = SOURCE.ScryfallURI, TARGET.CardSetPlatformScryfallAPI = SOURCE.ScryfallAPI 
  when NOT MATCHED by TARGET 
   THEN insert (CardFaceSetID, PlatformID, CardSetPlatformScryfallURI, CardSetPlatformScryfallAPI) VALUES (SOURCE.CardFaceSetID, SOURCE.PlatformID, SOURCE.ScryfallURI, SOURCE.ScryfallAPI) ; 
 commit 

 delete from SCRY_CANON_CARDS where PK in (select PK from #inserted)
 alter table #inserted 
  drop constraint temp_ins_PK
 alter table #processing 
  drop constraint temp_procss_PK
 drop index ix_ins_CardID on #inserted 
 drop table #inserted 
 drop index ix_process_CardID on #processing 
 drop table #processing 
 drop table #typelineprocessing 
 drop table #processplatform 
 commit 
 END 
GO 


