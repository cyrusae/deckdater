create database dd_benchmarks 
GO 

ALTER DATABASE dd_benchmarks 
 set READ_COMMITTED_SNAPSHOT ON 
GO 

ALTER database dd_benchmarks 
 ADD FILEGROUP ddb_memop CONTAINS MEMORY_OPTIMIZED_DATA 
GO 

ALTER DATABASE dd_benchmarks
 ADD FILE(name = 'ddb_memop',
    filename = 'C:\Program Files\Microsoft SQL Server\MSSQL15.DAWNFIRE\MSSQL\DATA\dd_memop2') 
    to FILEGROUP ddb_memop
GO 

alter database dd_benchmarks
 SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = ON ; 

use dd_benchmarks 
GO


--select * into CARD_TEST from Info_430_deckdater.dbo.STAGE_CARDS where 0=1
select * into defLAYOUT from Info_430_deckdater.dbo.defLAYOUT 
alter table defLAYOUT 
 add constraint PK_defLAYOUT PRIMARY KEY (LayoutID) 
GO 

alter table defLAYOUT 
 add constraint ix_LayoutName UNIQUE (LayoutName)
GO 

select * into defFACE from Info_430_deckdater.dbo.defFACE
alter table defFACE 
 add constraint PK_defFACE PRIMARY KEY (FaceID)
GO 

select * into refLAYOUT_FACE from Info_430_deckdater.dbo.refLAYOUT_FACE 
alter table refLAYOUT_FACE 
 Add constraint PK_LayoutFace PRIMARY KEY (LayoutFaceID)
GO 

alter table refLAYOUT_FACE 
 add constraint FK_LFofLayout FOREIGN KEY (LayoutID) references defLAYOUT ON DELETE CASCADE 
GO 

select * into defRARITY from Info_430_deckdater.dbo.defRARITY 
alter table defRARITY 
 add constraint PK_RarityID PRIMARY KEY (RarityID)
 GO 

alter table refLAYOUT_FACE 
 add constraint FK_LFofFace FOREIGN KEY (FaceID) references defFACE ON DELETE CASCADE 
GO 

select * into tblSET from Info_430_deckdater.dbo.tblSET 

alter table tblSET 
 add constraint PK_SetID PRIMARY KEY NONCLUSTERED (SetID)
GO 

create CLUSTERED index ix_SandCountCards on tblSET (SetCount)
GO 

select * into defPLATFORM from Info_430_deckdater.dbo.defPLATFORM
alter table defPLATFORM 
 Add constraint PK_PlatformID PRIMARY KEY (PlatformID)
GO 

select * into defSUPERTYPE from Info_430_deckdater.dbo.defSUPERTYPE
alter table defSUPERTYPE 
 add constraint PK_SupertypeID PRIMARY KEY (SupertypeID)
GO 

select * into defTYPE from Info_430_deckdater.dbo.defTYPE
alter table defTYPE 
 add constraint PK_TypeID PRIMARY KEY (TypeID)
GO 

select * into defSUBTYPE from Info_430_deckdater.dbo.defSUBTYPE
alter table defSUBTYPE 
 add constraint PK_SubtypeID PRIMARY KEY (SubtypeID)
GO 

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

create table tblCARD_FACE_SET (
 CardFaceSetID int Identity(1,1) primary key NOT NULL,
 CardFaceID int FOREIGN KEY references tblCARD_FACE ON DELETE CASCADE,
 SetID varchar(36) FOREIGN KEY references tblSET ON DELETE CASCADE,
 RarityID int FOREIGN KEY references defRARITY,
 IsReprint char(1) SPARSE NULL,
 Constraint OnePrintingPerSet UNIQUE (CardFaceID, SetID))
GO 

create table tblCARD_FACE_SET_PLATFORM (
 CardFaceSetID int FOREIGN KEY references tblCARD_FACE_SET ON DELETE CASCADE,
 PlatformID int FOREIGN KEY references defPLATFORM NOT NULL,
 CardSetPlatformScryfallURI varchar(500) NULL,
 CardSetPlatformScryfallAPI varchar(500) NULL,
 Constraint OnePrintingPerSetPerPlatform PRIMARY KEY (CardFaceSetID, PlatformID))
GO
--select * from CARD_TEST 
drop table #CTest 
drop table #typelineprocessing 
drop table #processplatform 
drop table #oldcards 
drop table #newfaces  

select CT.CardID, C.CardID as OldCardID, CT.CardFaceName, CT.CardFaceSearchName, CF.CardFaceID, CFS.CardFaceSetID, CT.CardSetScryfallURI, CT.CardSetScryfallAPI, LF.LayoutFaceID, CT.Supertypes as SupertypeList, CT.Types as TypeList, CT.Subtypes as SubtypeList, CT.SetID, R.RarityID, P.PlatformID, CT.IsReprint into #CTest from CARD_TEST CT 
 LEFT join tblCARD C on CT.CardID = C.CardID 
 LEFT join tblCARD_FACE CF on (CT.CardID = CF.CardID 
  and CT.CardFaceSearchName = CF.CardFaceSearchName)
 join defRARITY R on CT.RarityName = R.RarityName 
 join defPLATFORM P on CT.PlatformName = P.PlatformName
 join defLAYOUT L on CT.LayoutName = L.LayoutName 
 join defFACE F on CT.FaceName = F.FaceName 
 join refLAYOUT_FACE LF on (L.LayoutID = LF.LayoutID 
  and F.FaceID = LF.FaceID)
 LEFT join tblCARD_FACE_SET CFS on (CF.CardFaceID = CFS.CardFaceID
   and CT.SetID = CFS.SetID) 

 insert into tblCARD (CardID)
  select distinct CardID from #CTest 
   where OldCardID is NULL 
  group by CardID 

 select CF.CardID, CF.CardFaceID, P.LayoutFaceID, P.CardFaceName, P.CardFaceSearchName into #oldcards 
  from #CTest p 
  join tblCARD_FACE CF on (p.CardID = CF.CardID
   and p.LayoutFaceID = CF.LayoutFaceID)
  group by CF.CardID, CF.CardFaceID, P.LayoutFaceID, P.CardFaceName, P.CardFaceSearchName
 
 select CardID, LayoutFaceID, CardFaceName, CardFaceSearchName into #newfaces 
  from #CTest p 
  except (select CardID, LayoutFaceID, CardFaceName, CardFaceSearchName from #oldcards)

 insert into tblCARD_FACE (CardID, LayoutFaceID, CardFaceName, CardFaceSearchName)
  select CardID, LayoutFaceID, CardFaceName, CardFaceSearchName 
   from #newfaces p

 update #CTest 
  set CardFaceID = CF.CardFaceID 
   from tblCARD_FACE CF 
    join #CTest p
     on (CF.CardFaceSearchName = p.CardFaceSearchName 
      and CF.CardID = p.CardID)
    where p.CardFaceID is NULL 
    ;

 select CardFaceID, SupertypeList, TypeList, SubtypeList into #typelineprocessing 
  from  #CTest 
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
   except (select CardFaceID, SupertypeID from tblCARD_FACE_SUPERTYPE)
    ;


 with TypeLine (CardFaceID, TypeName) as (
  select CardFaceID, Trim(value) as TypeName 
  from #typelineprocessing 
  CROSS APPLY String_Split(TypeList, ' '))

 insert into tblCARD_FACE_TYPE (CardFaceID, TypeID)
  select p.CardFaceID, T.TypeID 
  from TypeLine p 
  join defTYPE T on p.TypeName = T.TypeName 
  except (select CardFaceID, TypeID from tblCARD_FACE_TYPE) 
  ;

 with SubtypeLine (CardFaceID, SubtypeName) as (
  select CardFaceID, Trim(value) as SubtypeName 
  from #typelineprocessing 
  CROSS APPLY String_Split(SubtypeList, ' ')
  where SubtypeList is NOT NULL)

 insert into tblCARD_FACE_SUBTYPE (CardFaceID, SubtypeID)
select p.CardFaceID, S.SubtypeID 
  from SubtypeLine p 
  join defSUBTYPE S on p.SubtypeName = S.SubtypeName 
  except (select CardFaceID, SubtypeID from tblCARD_FACE_SUBTYPE) 
  ;


 insert into tblCARD_FACE_SET (CardFaceID, SetID, RarityID, IsReprint)
  select CardFaceID, SetID, RarityID, IsReprint
  from #CTest 
   where CardFaceSetID is NULL 
  group by CardFaceID, SetID, RarityID, IsReprint
 
 update #CTest 
  set CardFaceSetID = CFS.CardFaceSetID 
  from tblCARD_FACE_SET CFS 
   join #CTest p on (CFS.CardFaceID = p.CardFaceID 
    and CFS.SetID = p.SetID )
   where p.CardFaceSetID is NULL 

 update tblCARD_FACE_SET 
  set 
   RarityID = p.RarityID, 
   IsReprint = p.IsReprint
  from tblCARD_FACE_SET CFS 
   join #CTest p on CFS.CardFaceSetID = p.CardFaceSetID 
   where CFS.RarityID != p.RarityID 
    OR CFS.IsReprint != p.IsReprint 
    
;

 select CardFaceSetID, PlatformID, CardSetScryfallURI, CardSetScryfallAPI into #processplatform 
  from #CTest p 
 
 MERGE tblCARD_FACE_SET_PLATFORM as TARGET 
  using #processplatform as SOURCE 
  on (TARGET.CardFaceSetID = SOURCE.CardFaceSetID 
    and TARGET.PlatformID = SOURCE.PlatformID)
  when MATCHED and (TARGET.CardSetPlatformScryfallURI != SOURCE.CardSetScryfallURI or TARGET.CardSetPlatformScryfallAPI != SOURCE.CardSetScryfallAPI) 
   THEN update set TARGET.CardSetPlatformScryfallURI = SOURCE.CardSetScryfallURI, TARGET.CardSetPlatformScryfallAPI = SOURCE.CardSetScryfallAPI 
  when NOT MATCHED by TARGET 
   THEN insert (CardFaceSetID, PlatformID, CardSetPlatformScryfallURI, CardSetPlatformScryfallAPI) VALUES (SOURCE.CardFaceSetID, SOURCE.PlatformID, SOURCE.CardSetScryfallURI, SOURCE.CardSetScryfallAPI) ; 
