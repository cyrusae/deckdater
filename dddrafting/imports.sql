use deckdater_dev 
GO 

create table SCRY_CANON_SETS (
 PK int Identity(1,1) primary key NOT NULL,
 SetID varchar(36) NOT NULL,
 SetCode char(3),
 SetName varchar(200),
 SetScryfallAPI varchar(200),
 SetScryfallURI varchar(200),
 SetReleaseDate date, --does this want to be char(10) or can I trust it...
 SetTypeName varchar(25),
 CollectorCount int,
 SetIsDigital char(1) NULL,
 BlockCode char(3) NULL,
 BlockName varchar(200) NULL) 
GO 

create type IngestSets as table (
 PK int Identity(1,1) primary key NONCLUSTERED NOT NULL,
 SetID varchar(36) NOT NULL,
 SetCode char(3),
 SetName varchar(200),
 SetScryfallAPI varchar(200),
 SetScryfallURI varchar(200),
 SetReleaseDate date, 
 SetTypeName varchar(25),
 CollectorCount int,
 SetIsDigital char(1) NULL,
 BlockCode char(3) NULL,
 BlockName varchar(200) NULL) 
  with (MEMORY_OPTIMIZED = ON);
GO 

create type IngestBlocks as table (
 PK int Identity(1,1) primary key NONCLUSTERED NOT NULL,
 BlockCode char(3),
 BlockName varchar(200))
  with (MEMORY_OPTIMIZED = ON);
GO 

create OR alter proc GET_orMakeBlockID 
 @GivenCode char(3),
 @GivenName varchar(200),
 @GotBlockID int OUT 
 as BEGIN 
 set @GotBlockID = (select BlockID from tblBLOCK 
  where BlockCode = @GivenCode 
   and BlockName = @GivenName)
 if @GotBlockID IS NULL 
 BEGIN 
  if not exists (select BlockName from tblBLOCK where BlockCode = @GivenCode)
  BEGIN 
   insert into tblBLOCK (BlockCode, BlockName)
    VALUES (@GivenCode, @GivenName)
   set @GotBlockID = scope_identity()
  END 
 ELSE if exists (select BlockName from tblBLOCK where BlockCode = @GivenCode)
  BEGIN 
   begin tran 
   update tblBLOCK 
    set BlockName = @GivenName 
    where BlockCode = @GivenCode 
   commit 
   set @GotBlockID = (select BlockID from tblBLOCK
    where BlockName = @GivenName 
     and BlockCode = @GivenCode)
  END 
 END
 END  
GO 

--cards 
---- note to self use the same thing you did with unpivots in petsdata for the type line strings 
create table SCRY_CANON_CARDS (
 PK int Identity(1,1) primary key NOT NULL,
 CardID varchar(36) NOT NULL,
 CardFaceName varchar(200),
 CardFaceSearchName varchar(200),
 CardSetScryfallAPI varchar(300),
 CardSetScryfallURI varchar(300),
 LayoutName varchar(25),
 FaceName varchar(25),
 Supertypes varchar(100) NULL,
 Types varchar(100), 
 Subtypes varchar(100) NULL,
 SetID varchar(36),
 RarityName varchar(25),
 PlatformList varchar(100),
 IsReprint char(1) NULL)
GO 

create type IngestCardSkeleton as table (
 PK int Identity(1,1) primary key NONCLUSTERED NOT NULL,
 CardID varchar(36) NOT NULL,
 CardFaceName varchar(200),
 CardFaceSearchName varchar(200),
 CardSetScryfallAPI varchar(300),
 CardSetScryfallURI varchar(300),
 LayoutFaceID int,
 Supertypes varchar(100) NULL,
 Types varchar(100), 
 Subtypes varchar(100) NULL,
 SetID varchar(36),
 RarityID int,
 PlatformList varchar(100),
 IsReprint char(1) NULL)
  with (MEMORY_OPTIMIZED = ON);
GO 

--just this once I'm gonna do it by hand and then do the triggers. I guessss.
/*
create OR alter TRIGGER t_IngestSets on SCRY_CANON_SET 
 after insert 
 as BEGIN 
 set NOCOUNT ON 
 declare @Gottem IngestSets, @nrow int, @Blockers IngestBlocks
 insert into @Gottem (SetID, SetCode, SetName, SetScryfallAPI, SetScryfallURI, SetReleaseDate, SetTypeID, CollectorCount, SetIsDigital, BlockCode, BlockName)
  select SetID, SetCode, SetName, SetScryfallAPI, SetScryfallURI, SetReleaseDate, SetTypeName, CollectorCount, SetIsDigital, BlockCode, BlockName from inserted 
 set @nrow = (select Count(PK) from @Gottem)

 END 
GO 



create OR alter TRIGGER t_IngestSkeletonCards on SCRY_CANON_CARDS 
 after INSERT 
 as BEGIN 
 set NOCOUNT ON 


 END 
GO */