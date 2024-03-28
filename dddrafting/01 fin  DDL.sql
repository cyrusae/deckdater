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
    filename = 'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\dd_memop430') 
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
 VALUES ('1993-09-20', 'martin.e@o.com', 'Martin', 'Durham Eosphoros', 'Emperor'), ('1995-08-03', 'ce@g.com', 'Cyrus', 'Eosphoros', 'Magician') --two manually-entered test users for reasons that will become apparent eventually, and also because I am gay 

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

create table defFORMAT_TYPE (
 FormatTypeID int Identity(1,1) primary key NOT NULL,
 FormatTypeName varchar(25) unique NOT NULL,
 FormatTypeDesc varchar(500) NULL)

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
