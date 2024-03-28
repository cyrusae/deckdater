use master 
GO 

DROP database deckdater_dev 
GO 

create DATABASE deckdater_dev 
GO

ALTER DATABASE deckdater_dev 
 set READ_COMMITTED_SNAPSHOT ON 
GO 

ALTER database deckdater_dev 
 ADD FILEGROUP dd_memop CONTAINS MEMORY_OPTIMIZED_DATA 
GO 

ALTER DATABASE deckdater_dev 
 ADD FILE(name = 'dd_memop1',
    filename = 'C:\Program Files\Microsoft SQL Server\MSSQL15.DAWNFIRE\MSSQL\DATA\dd_memop1') 
    to FILEGROUP dd_memop
GO 

alter database deckdater_dev 
 SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = ON; 

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
 BlockCode char(3) unique NOT NULL,
 BlockName varchar(200) NOT NULL)
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
 --PK int Identity(1,1) primary key NONCLUSTERED NOT NULL,
 CardFaceID int,
 SubtypeID int,
 SubtypeName varchar(25),
 SnowLand int DEFAULT 0) --no PK on this one in specific, because reasons, so not memory-optimized 
GO 

create OR alter function getme_basiclands()
 returns @RET table (
 --PK int Identity(1,1) primary key NONCLUSTERED NOT NULL,
 CardFaceID int,
 SubtypeID int,
 SubtypeName varchar(25),
 SnowLand int DEFAULT 0) 
 as BEGIN 
 declare @filter BasicLandOutput
 insert into @filter (CardFaceID, SubtypeID, SubtypeName, SnowLand)
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
 insert into @RET select * from @filter 
 RETURN
 END 
GO 

create type Unlisted as table (
 PK int Identity(1,1) primary key NONCLUSTERED NOT NULL,
 Item varchar(500))
  with (MEMORY_OPTIMIZED = ON);
GO 

create table tblCARD_NOT_SET_DATE (
 CardFaceSetID int FOREIGN KEY references tblCARD_FACE_SET ON DELETE CASCADE,
 CardReleaseDate date NOT NULL,
 Constraint OneFlukeOneTime PRIMARY KEY (CardFaceSetID))

create table tblCARD_HAPAX (
 HapaxCardID int Identity(1,1) primary key NOT NULL,
 CardID varchar(36) UNIQUE FOREIGN KEY references tblCARD ON DELETE CASCADE,
 BeginDate date,
 EndDate date NULL)

