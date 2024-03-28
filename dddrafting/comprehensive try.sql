use master 
GO 

DROP database deckdater_dev 
GO 

create DATABASE deckdater_dev 
GO

use deckdater_dev 
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

insert into defFACE (FaceName, FaceDesc)
 VALUES ('default', 'Front face'), ('naming', 'Back, transformed, otherwise contributes to name with own name'), ('alternate', 'Melded, specialized, otherwise does not contribute to name and has own name')
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
 CardFaceNameMachineReadable varchar(200) unique NOT NULL)
GO 

--open question: given how type lines work, would consolidating defTYPE / defSUBTYPE / defSUPERTYPE into refTYPE_LINE + defTYPE_LINE_TYPE make more sense? seems arguably more normalized but places heavier load on logic (cards must have one or more types, supertypes and subtypes are both optional) in ways I worry about? and also only subtypes see frequent updates. I'm not gonna upset the applecart for now but it bears contemplation.

create table defSUPERTYPE (
 SupertypeID int Identity(1,1) primary key NOT NULL,
 SupertypeName varchar(25) unique NOT NULL)

create table defTYPE (
 TypeID int Identity(1,1) primary key NOT NULL,
 TypeName varchar(25) unique NOT NULL)

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
 SupertypeID int FOREIGN KEY references defSUPERTYPE ON DELETE CASCADE,
 CardFaceID int FOREIGN KEY references tblCARD_FACE ON DELETE CASCADE,
 Constraint ListSupertypeOnce PRIMARY KEY (SupertypeID, CardFaceID))

create table tblCARD_FACE_TYPE (
 TypeID int FOREIGN KEY references defTYPE ON DELETE CASCADE,
 CardFaceID int FOREIGN KEY references tblCARD_FACE ON DELETE CASCADE,
 Constraint ListTypeOnce PRIMARY KEY (TypeID, CardFaceID))

create table tblCARD_FACE_SUBTYPE (
 SubtypeID int FOREIGN KEY references defSUBTYPE ON DELETE CASCADE,
 CardFaceID int FOREIGN KEY references tblCARD_FACE ON DELETE CASCADE,
 Constraint ListSubtypeOnce PRIMARY KEY (SubtypeID, CardFaceID))
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

alter table tblCARD_FACE 
 Add CONSTRAINT TypeLineRequiresType 
  CHECK (dbo.fn_chk_CardFaceTypes(CardFaceID) > 0)
GO 

create table tblBLOCK (
 BlockID int Identity(1,1) primary key NOT NULL,
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

create table defFORMAT_MEDIUM (
 FormatMediumID int Identity(1,1) primary key NOT NULL,
 FormatMediumName varchar(25) unique NOT NULL,
 FormatMediumAbbrev varchar(10) unique NOT NULL,
 FormatMediumDesc varchar(500) NULL)

insert into defFORMAT_MEDIUM (FormatMediumName, FormatMediumAbbrev, FormatMediumDesc)
 VALUES ('Best of one', 'BO1', 'No sideboarding between games; default in Arena'), ('Best of three', 'BO3', 'Sideboard used between games; default in most competitive formats, especially paper')

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
 FormatNameDesc varchar(500) NULL)
GO 

create table refFORMAT (
 FormatID int Identity(1,1) primary key NOT NULL,
 FormatNameID int FOREIGN KEY references defFORMAT_NAME NOT NULL,
 FormatMediumID int FOREIGN KEY references defFORMAT_MEDIUM NOT NULL,
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
 CardSetScryfallURI varchar(500),
 CardSetScryfallAPI varchar(500))
GO 

create table defPLATFORM (
 PlatformID int Identity(1,1) primary key NOT NULL,
 PlatformName varchar(10) unique NOT NULL,
 PlatformDesc varchar(250) NULL)
GO

create table tblCARD_FACE_SET_PLATFORM (
 CardFaceSetID int FOREIGN KEY references tblCARD_FACE_SET ON DELETE CASCADE,
 PlatformID int FOREIGN KEY references defPLATFORM NOT NULL,
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

insert into defZONE (ZoneName, ZoneDesc)
 VALUES ('CMDR', 'Command zone (Commander and Background)'), ('SIDE', 'Sideboard'), ('MAYB', 'Maybeboard'), ('WISH', 'Wishboard') --I still don't know if chosen companions are technically something else.
GO 

create table tblDECK_CARD (
 DeckID int FOREIGN KEY references tblDECK ON DELETE CASCADE,
 CardFaceID int FOREIGN KEY references tblCARD_FACE ON DELETE CASCADE,
 Quantity int DEFAULT 1,
 Constraint ListCardsOncePerDeck PRIMARY KEY (DeckID, CardFaceID)) --this *should* interact as intended with nullables (list once in maindeck, separate for e.g. sideboarding extras)

create table tblDECK_CARD_ZONE (
 DeckID int FOREIGN KEY references tblDECK ON DELETE CASCADE,
 ZoneID int FOREIGN KEY references defZONE NOT NULL, 
 CardFaceID int FOREIGN KEY references tblCARD_FACE ON DELETE CASCADE,
 Quantity int DEFAULT 1,
 Constraint ListCardsOncePerDeckZone PRIMARY KEY (DeckID, ZoneID, CardFaceID))
GO --this should be all tables required for deckdating only.

create type BasicLandOutput as table (
 PK int Identity(1,1) primary key NOT NULL,
 CardFaceID int,
 SubtypeID int,
 SubtypeName varchar(25),
 SnowLand int DEFAULT 0) 
  with (MEMORY_OPTIMIZED = ON);
GO 

create OR alter function getme_basiclands()
 returns BasicLandOutput 
 as BEGIN 
 declare @RET BasicLandOutput
  /*
 with Basics (CardFaceID) as (select CardFaceID from tblCARD_FACE_SUPERTYPE CFS
  join defSUPERTYPE S on CFS.SupertypeID = S.SupertypeID 
  where SupertypeName = 'Basic') */

 insert into @RET (CardFaceID, SubtypeID, SubtypeName, SnowLand)
  select CF.CardFaceID, Sub.SubtypeID, Sub.SubtypeName, (Count(Csup.SupertypeID) - 1) as SnowLand --Basic snow lands have the supertypes "Basic" and "Snow" instead of just "Basic"
   from tblCARD_FACE CF 
    join tblCARD_FACE_TYPE CTyp on CF.CardFaceID = CTyp.CardFaceID 
    join defTYPE T on CTyp.TypeID = T.TypeID 
    join tblCARD_FACE_SUPERTYPE CSup on CF.CardFaceID = CSup.CardFaceID 
    join tblCARD_FACE_SUBTYPE CSub on CF.CardFaceID = CSub.CardFaceID 
    join defSUBTYPE Sub on CSub.SubtypeID = Sub.SubtypeID 
    where T.TypeName = 'Land'
     and CF.CardFaceID in (select CardFaceID 
      from tblCARD_FACE_SUPERTYPE CFS
      join defSUPERTYPE S on CFS.SupertypeID = S.SupertypeID 
      where SupertypeName = 'Basic')
    group by CF.CardFaceID, Sub.SubtypeID, Sub.SubtypeName
 return @RET 
 END 
GO 

create type Unlisted as table (
 PK int Identity(1,1) primary key NONCLUSTERED NOT NULL,
 Item varchar(500))
  with (MEMORY_OPTIMIZED = ON);

-- stopping here for now
-- 
create type IngestDecklist as table (
 PK int Identity(1,1) primary key NONCLUSTERED NOT NULL,
 CardFaceName varchar(200) NOT NULL,
 Quantity int DEFAULT 1,
 ZoneName char(4) NULL)
  with (MEMORY_OPTIMIZED = ON);

create type WrangleDecklist as table (
 PK int Identity(1,1) primary key NONCLUSTERED NOT NULL,
 CardFaceID int NOT NULL,
 Quantity int DEFAULT 1,
 ZoneID char(4) NULL)
  with (MEMORY_OPTIMIZED = ON);
GO 

create OR alter function fetch_DeckByID (@DeckID int)
 returns WrangleDecklist 
 as BEGIN 
 declare @RET WrangleDecklist 
 set @RET = (select CardFaceID, Quantity, ZoneID from tblDECK_CARD where DeckID = @DeckID)
 return @RET 
 END 
GO 

create OR alter function fetch_FormatIDbyMachineName (@FormatName varchar(25))
 returns int 
 as BEGIN 
 declare @RET int 
 set @RET = (select F.FormatID from refFORMAT F 
  join defFORMAT_NAME FN on F.FormatNameID = FN.FormatNameID 
  where FormatNameMachineReadable = @FormatName)
 return @RET 
 END 
GO 

create OR alter function ingest_DecklistFromString (
 @ingest varchar(8000))
 returns IngestDecklist 
 as BEGIN 
 declare @RET IngestDecklist, @ticktock int, @ticker int, @Unstring Unlisted 
 insert into @Unstring (Item)
  select value as Item from STRING_SPLIT(@ingest, '|')
 set @ticktock = (select Count(PK) from @Unstring)/3 
 while @ticktock > 0 
  BEGIN 
   declare @CardFaceName varchar(200), @Quantity int, @zonename char(4)
   set @ticker = (select Min(PK) from @Unstring)
   set @CardFaceName = (select Trim(Item) from @Unstring where PK = @ticker)
   delete from @Unstring where PK = @ticker 
   set @ticker = (select Min(PK) from @Unstring)
   set @Quantity = (select Cast(Trim(Item) as int) from @Unstring where PK = @ticker)
   delete from @Unstring where PK = @ticker 
   set @ticker = (select Min(PK) from @Unstring)
   set @zonename = (select Cast(Trim(Item) as char(4)) from @Unstring where PK = @ticker)
   if @zonename = 'ISNA'
    set @zonename = NULL 
   delete from @Unstring where PK = @ticker 
   insert into @RET (CardFaceName, Quantity, zonename)
    VALUES (@CardFaceName, @Quantity, @zonename) 
   set @ticktock = @ticktock - 1
  END 
 return @RET 
 END 
GO 

create OR alter function produce_DecklistFromString (@ingest varchar(8000)) 
 returns WrangleDecklist
 as BEGIN 
 declare @RET WrangleDecklist, @work IngestDecklist 
 set @work = dbo.ingest_DecklistFromString(@ingest)
 insert into @RET (CardFaceID, Quantity, zoneid)
  select CF.CardFaceID, W.Quantity, DC.zoneid 
   from @work W 
   join tblCARD_FACE CF on W.CardFaceName = CF.CardFaceName 
   LEFT join defZONE DC on W.zonename = DC.zonename
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

create OR alter proc u_CREATE_NewDeck 
 @UserID int,
 @WithDeckName varchar(280),
 @InFormat varchar(25) NULL,
 @FromDecklist varchar(8000) NULL
 as BEGIN 
 declare @RealDeckName varchar(350)
 set @RealDeckName = dbo.makeupaguy_deckname(@UserID, @WithDeckName)

 begin tran MakeDeck 
  insert into tblDECK (UserID, DeckName)
   VALUES (@UserID, @RealDeckName)

  if (@FromDecklist is NOT NULL) or (@InFormat is NOT NULL)
   BEGIN 
    declare @DeckID int 
    set @DeckID = scope_identity()
    if @FromDecklist is NOT NULL 
     BEGIN 
     declare @Decklist WrangleDecklist
     set @Decklist = dbo.produce_DecklistFromString(@FromDecklist)
     if (@Decklist is NOT NULL) and ((select Count(PK) from @Decklist) > 0) --no sneaking in malformed deck lists!!
      BEGIN --reformat this to use the update proc later, this is a proof of concept 
       begin tran AddCardsOfNewDeck 
       insert into tblDECK_CARD (DeckID, CardFaceID, Quantity, zoneid)
        select @DeckID, CardFaceID, Quantity, zoneid from @Decklist 
       commit tran AddCardsOfNewDeck
      END 
     END 
     if @InFormat is NOT NULL     --add guessing format and change this accordingly once that's implemented (actually, do that and break out result into proc to add or update format? we'll see)
     BEGIN 
      declare @FormatID int 
      set @FormatID = dbo.fetch_FormatIDbyMachineName(@InFormat)
      if @FormatID is NOT NULL --sucks to be you if you somehow manually entered a malformed format name lmao 
       BEGIN 
        begin tran AddFormatOfDeck 
        insert into tblDECK_FORMAT(DeckID, FormatID)
         VALUES (@DeckID, @FormatID)
        commit AddFormatOfDeck 
       END 
     END 
   END 
 commit MakeDeck
 END 
GO 
--move format ID getting up earlier later 

create OR alter function fetch_UserIDbyUsername (@UserName varchar(100))
 returns int 
 as BEGIN 
 declare @RET int 
 set @RET = (select UserID from tblUSER where UserName = @UserName)
 return @RET 
 END 
GO

create or alter proc i_ADD_RealDeck 
 @UserName varchar(100),
 @LetWithDeckName varchar(280),
 @LetInFormat varchar(25) NULL,
 @LetFromDecklist varchar(8000) NULL
 as BEGIN 
 declare @LetUserID int 
 set @LetUserID = dbo.fetch_UserIDbyUsername(@UserName)
 if @LetUserID IS NULL 
  BEGIN 
   print 'No user with that username found';
   throw 938593, 'UserID not found by UserID fetcher. Check spelling. Terminating for now.', 13;
  END 
 exec dbo.u_CREATE_NewDeck 
  @UserID = @UserID,
  @WithDeckName = @LetWithDeckName,
  @InFormat = @LetInFormat,
  @FromDecklist = @LetFromDecklist
 END 
GO 

create OR alter proc o_WRAP_CreateRealDeckReturnID 
 @ForUserName varchar(100),
 @DeckName varchar(280),
 @Format varchar(25) NULL,
 @Decklist varchar(8000) NULL,
 @DeckID int OUT 
 as BEGIN 
 declare @UserID int 
 set @UserID = dbo.fetch_UserIDbyUsername(@ForUserName) --duplicated work here for now for reasons that will be cleaned up later 
 exec dbo.i_ADD_RealDeck 
  @UserName = @ForUserName,
  @LetWithDeckName = @DeckName,
  @LetInFormat = @Format,
  @LetFromDecklist = @Decklist 
 set @DeckID = (select Top 1 DeckID from tblDECK
  where UserID = @UserID
  order by DateCreated desc)
 END 
GO 

create table SCRY_CANON_SETS (
 PK int Identity(1,1) primary key NOT NULL,
 SetCode char(3) unique NOT NULL,
 SetName varchar(200),
 SetReleaseDate date NOT NULL,
 SetTypeName varchar(25),
 SetCollectorCount int,
 SetScryfallURI varchar(500),
 SetScryfallAPI varchar(500),
 BlockName varchar(200) NULL,
 SetIsDigital char(1) SPARSE NULL)
GO 

create type ImportSets as table (
 PK int Identity(1,1) primary key NOT NULL,
 SetID varchar(36) NOT NULL,
 SetCode char(3) unique NOT NULL,
 SetName varchar(200),
 SetReleaseDate date NOT NULL,
 SetTypeID int NOT NULL,
 SetCollectorCount int,
 SetScryfallURI varchar(500),
 SetScryfallAPI varchar(500),
 BlockID int NULL,
 SetIsDigital char(1) SPARSE NULL)
  with (MEMORY_OPTIMIZED = ON);
GO 

create trigger t_AddCanonSets on SCRY_CANON_SETS 
 after INSERT 
 as BEGIN 
 set NOCOUNT ON 
 declare @Processor ImportSets
 begin tran NewBlocks 
  insert into tblBLOCK (BlockName)
   select i.BlockName from inserted i 
   where i.BlockName not in (select BlockName from tblBLOCK)
 commit 
 insert into @Processor
  select SetID, SetCode, SetName, SetReleaseDate, SetTypeID, SetCollectorCount, SetScryfallURI, SetScryfallAPI, BlockID, SetIsDigital
   from inserted i 
   join defSET_TYPE ST on i.SetTypeName = ST.SetTypeName
   LEFT join tblBLOCK B on i.BlockName = B.BlockName 
 update tblSET 
  set tblSET.SetCode = i.SetCode, 
   tblSET.SetName = i.SetName, 
   tblSET.SetReleaseDate = i.SetReleaseDate,
   tblSET.SetTypeID = i.SetTypeID,
   tblSET.SetCollectorCount = i.SetCollectorCount,
   tblSET.SetScryfallURI = i.SetScryfallURI,
   tblSET.SetScryfallAPI = i.SetScryfallAPI,
   tblSET.BlockID = i.BlockID,
   tblSET.SetIsDigital = i.SetIsDigital 
   from @Processor i
    join tblSET on i.SetID = tblSET.SetID 
   where tblSET.SetID = i.SetID 
 insert into tblSET (SetID, SetCode, SetName, SetReleaseDate, SetTypeID, SetCollectorCount, SetScryfallURI, SetScryfallAPI, BlockID, SetIsDigital)
  select SetID, SetCode, SetName, SetReleaseDate, SetTypeID, SetCollectorCount, SetScryfallURI, SetScryfallAPI, BlockID, SetIsDigital
  from @Processor
  where SetID not in (select SetID from tblSET)
 delete from SCRY_CANON_SETS 
  where SetID in (select SetID from @ImportSets)
 END 
GO 

create table SCRY_CANON_CARDS_SKELETON (
 PK int Identity(1,1) primary key NOT NULL,
 CardID varchar(36) NOT NULL,
 CardFaceName varchar(100),
 LayoutName varchar(25) NULL,
 FaceName varchar(25) NULL,
 SetID varchar(36) NOT NULL,
 FaceSupertypes varchar(100) NULL,
 FaceTypes varchar(100) NOT NULL,
 FaceSubtypes varchar(100) NULL,
 CardSetScryfallURI varchar(500),
 CardSetScryfallAPI varchar(500))
GO 

create type ImportCards as table (
 PK int Identity(1,1) primary key NONCLUSTERED NOT NULL,
 CardID varchar(36) NOT NULL,
 CardFaceName varchar(100),
 LayoutFaceID int NULL,
 SetID varchar(36) NOT NULL,
 PlatformID int,
 FaceSupertypes varchar(100) NULL,
 FaceTypes varchar(100) NOT NULL,
 FaceSubtypes varchar(100) NULL,
 CardSetScryfallURI varchar(500),
 CardSetScryfallAPI varchar(500)) 
  with (MEMORY_OPTIMIZED = ON);
GO 

create type TypeLineProcessor as table (
 PK int Identity(1,1) primary key NONCLUSTERED NOT NULL,
 CardFaceID int,
 TypeLineContent varchar(100)) 
  with (MEMORY_OPTIMIZED = ON);
GO

create OR alter proc ADD_CardTypes
 @ToCardFaceID int,
 @TypeString varchar(100)
 as BEGIN 
 declare @TypeLine TypeLineProcessor
 insert into @TypeLine (CardFaceID, TypeLineContent)
  select @ToCardFaceID, value from STRING_SPLIT(@TypeString, ' ')
 delete from tblCARD_FACE_TYPE 
  where CardFaceID = @ToCardFaceID 
   and TypeID not in (select T.TypeID from @TypeLine TL
    join defTYPE T on TL.TypeLineContent = T.TypeName)
 insert into tblCARD_FACE_TYPE (CardFaceID, TypeID)
  select @ToCardFaceID, T.TypeID from @TypeLine TL
   join defTYPE T on TL.TypeLineContent = T.TypeName
 END 
GO 

create OR alter proc ADD_CardSupertypes
 @ToCardFaceID int,
 @TypeString varchar(100)
 as BEGIN 
 declare @TypeLine TypeLineProcessor
 insert into @TypeLine (CardFaceID, TypeLineContent)
  select @ToCardFaceID, value from STRING_SPLIT(@TypeString, ' ')
 delete from tblCARD_FACE_SUPERTYPE 
  where CardFaceID = @ToCardFaceID 
   and SupertypeID not in (select T.SupertypeID from @TypeLine TL
    join defSUPERTYPE T on TL.TypeLineContent = T.SupertypeName)
 insert into tblCARD_FACE_SUPERTYPE (CardFaceID, SupertypeID)
  select @ToCardFaceID, T.SupertypeID from @TypeLine TL
   join defSUPERTYPE T on TL.TypeLineContent = T.SupertypeName
 END 
GO 

create OR alter proc ADD_CardSubtypes
 @ToCardFaceID int,
 @TypeString varchar(100)
 as BEGIN 
 declare @TypeLine TypeLineProcessor
 insert into @TypeLine (CardFaceID, TypeLineContent)
  select @ToCardFaceID, value from STRING_SPLIT(@TypeString, ' ')
 delete from tblCARD_FACE_SUBTYPE 
  where CardFaceID = @ToCardFaceID 
   and SubtypeID not in (select T.SubtypeID from @TypeLine TL
    join defSUBTYPE T on TL.TypeLineContent = T.SubtypeName)
 insert into tblCARD_FACE_SUBTYPE (CardFaceID, SubtypeID)
  select @ToCardFaceID, T.SubtypeID from @TypeLine TL
   join defSUBTYPE T on TL.TypeLineContent = T.SubtypeName
 END 
GO 

create OR alter proc ADD_CardFacePrint --needs tran breakout; not currently tracking the date anomalies or bans/restrictions.
 @OfCardFaceID int,
 @InSetID varchar(36),
 @OnPlatformID int,
 @ScryfallURI varchar(500),
 @ScryfallAPI varchar(500)
 as BEGIN 
 if exists (select CardFaceSetID from tblCARD_FACE_SET where CardFaceID = @OfCardFaceID and SetID = @InSetID)
  BEGIN 
  update tblCARD_FACE_SET 
   set PlatformID = @OnPlatformID, 
     CardSetScryfallURI = @ScryfallURI, 
     CardSetScryfallAPI = @ScryfallAPI
    where CardFaceID = @OfCardFaceID 
     and SetID = @InSetID 
  END 
  ELSE 
  BEGIN 
  insert into tblCARD_FACE_SET (CardFaceID, SetID, PlatformID, CardSetScryfallURI, CardSetScryfallAPI)
   VALUES (@CardFaceID, @SetID, @PlatformID, @ScryfallURI, @ScryfallAPI)
  END 
 END 
GO 

create OR alter proc ADD_CardFace --needs tran breakout 
 @ToCardID varchar(36),
 @WithFaceName varchar(100),
 @LetLayoutFaceID int,
 @LetPlatformID int,
 @LetSetID varchar(36),
 @LetSupertypeString varchar(100) NULL,
 @LetTypeString varchar(100) NOT NULL,
 @LetSubtypeString varchar(100) NULL,
 @LetCardSetURI varchar(500),
 @LetCardSetAPI varchar(500)
 as BEGIN 
 declare @CardFaceID int 
 set @CardFaceID = (select CardFaceID from tblCARD_FACE
  where CardID = @ToCardID and LayoutFaceID = @LetLayoutFaceID)
 if @CardFaceID IS NULL 
  BEGIN 
  insert into tblCARD_FACE (CardID, CardFaceName, LayoutFaceID)
   VALUES (@ToCardID, @WithfaceName, @LetLayoutFaceID)
  set @CardFaceID = scope_identity()
  END 
  ELSE 
   BEGIN
    update tblCARD_FACE 
     set CardFaceName = @WithFaceName, 
       LayoutFaceID = @LetLayoutFaceID 
     where CardFaceID = @CardFaceID 
   END 
 exec dbo.ADD_CardTypes 
  @ToCardFaceID = @CardFaceID,
  @TypeString = @LetTypeString 
 if @LetSupertypeString is NOT NULL 
  BEGIN 
  exec dbo.ADD_CardSupertypes 
   @ToCardFaceID = @CardFaceID,
   @TypeString = @LetSupertypeString
  END 
 if @LetSubtypeString is NOT NULL 
  BEGIN 
  exec dbo.ADD_CardSubtypes 
   @ToCardFaceID = @CardFaceID,
   @TypeString = @LetSubtypeString 
  END 
 exec dbo.ADD_CardFacePrint 
  @OfCardFaceID = @CardFaceID,
  @InSetID = @LetSetID,
  @OnPlatformID = @LetPlatformID,
  @ScryfallURI = @LetCardSetURI,
  @ScryfallAPI = @LetCardSetAPI
 END 
GO 

create trigger t_AddSkeletonCards on SCRY_CANON_CARDS_SKELETON 
 after INSERT 
 as BEGIN 
 declare @Processor ImportCards, @ticker int, @CardID varchar(36), @CardFaceName varchar(100), @LayoutFaceID int, @PlatformID int, @SetID varchar(36), @Supertypes varchar(100), @Types varchar(100), @Subtypes varchar(100), @URI varchar(500), @API varchar(500)
 /*  @ToCardID varchar(36),
 @WithFaceName varchar(100),
 @LetLayoutFaceID int,
 @LetPlatformID int,
 @LetSetID varchar(36),
 @LetSupertypeString varchar(100) NULL,
 @LetTypeString varchar(100) NOT NULL,
 @LetSubtypeString varchar(100) NULL,
 @LetCardSetURI varchar(500),
 @LetCardSetAPI varchar(500) */
 select LayoutName, FaceName, LayoutFaceID into #layoutfacts 
  from refLAYOUT_FACE LF 
  join defLAYOUT L on LF.LayoutID = L.LayoutID 
  join defFACE F on LF.FaceID = F.FaceID 

 insert into @Processor (CardID, CardFaceName, PlatformID, LayoutFaceID, SetID, FaceSupertypes, FaceTypes, FaceSubtypes, CardSetScryfallURI, CardSetScryfallAPI)
  select CardID, CardFaceName, PlatformID, LF.LayoutFaceID, SetID, FaceSupertypes, FaceTypes, FaceSubtypes, CardSetScryfallURI, CardSetScryfallAPI 
   from inserted i 
   join defPLATFORM P on i.PlatformName = P.PlatformName 
   LEFT join #layoutfacts LF on i.LayoutName = LF.LayoutName 
    and i.FaceName = LF.FaceName 
 update @Processor 
  set LayoutFaceID = (select LayoutFaceID from #layoutfacts where LayoutName = 'normal' and FaceName = 'default')
  where LayoutFaceID IS NULL 
 
 set @ticker = (select Count(PK) from @Processor)
 while @ticker > 0 
  BEGIN 
  declare @pickcard int
  set @pickcard = (select MIN(PK) from @Processor)
  select @CardID = CardID, /* CardID, CardFaceName, PlatformID, LayoutFaceID, SetID, FaceSupertypes, FaceTypes, FaceSubtypes, CardSetScryfallURI, CardSetScryfallAPI */
    @CardFaceName = CardFaceName,
    @PlatformID = PlatformID,
    @SetID = SetID,
    @LayoutFaceID = LayoutFaceID,
    @Supertypes = FaceSupertypes,
    @Subtypes = FaceSubtypes, 
    @Types = FaceTypes, 
    @URI = CardSetScryfallURI,
    @API = CardSetScryfallAPI 
    from @Processor where PK = @pickcard 
  if NOT EXISTS (select CardID from tblCARD where CardID = @CardID)
   BEGIN 
   insert into tblCARD (CardID)
    VALUES (@CardID)
   END 
  exec dbo.ADD_CardFace 
   @ToCardID = @CardID,
   @WithFaceName = @CardFaceName, 
   @LetLayoutFaceID = @LayoutFaceID,
   @LetSetID = @SetID,
   @LetSupertypeString = @Supertypes,
   @LetSubtypeString = @Subtypes,
   @LetTypeString = @Types,
   @LetCardSetURI = @URI,
   @LetCardSetAPI = @API 
  delete from @Processor where PK = @pickcard 

  --does the card already exist?
  --do the faces already exist?
  --does the printing in a set exist?
  --okay let's update types/subtypes etc.
  set @ticker = @ticker - 1 
  END 
 END 
GO 

