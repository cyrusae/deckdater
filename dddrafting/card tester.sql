use deckdater_dev 
GO 

/* REMAKE!! 
alter table tblCARD_FACE 
 drop constraint FK__tblCARD_F__CardI__47DBAE45 
alter table tblCARD_FACE 
 drop constraint UQ__tblCARD___791C755CEACBB379 */

drop table #inserted 
drop table #processing
drop table #pplatforms 

set NOCOUNT ON 
select Top 10 * into #inserted from SCRY_CANON_CARDS order by PK asc 
create NONCLUSTERED INDEX ix_ins_CardID on #inserted(CardID)
 INCLUDE (CardFaceSearchName, LayoutName, FaceName, SetID)

select i.PK as PK, i.CardID as CardID, C.CardID as OldCardID, CF.CardFaceID as CardFaceID, i.CardFaceName as CardFaceName, i.CardFaceSearchName as CardFaceSearchName, LF.LayoutFaceID as LayoutFaceID, i.Supertypes as SupertypeList, i.Types as TypeList, i.Subtypes as SubtypeList, CFS.CardFaceSetID as CardFaceSetID, i.SetID as SetID, i.PlatformList as PlatformList, i.CardSetScryfallURI as ScryfallURI, i.CardSetScryfallAPI as ScryfallAPI, R.RarityID as RarityID, i.IsReprint as IsReprint into #processing
 from #inserted i 
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
 group by i.PK, i.CardID, C.CardID, CF.CardFaceID, i.CardFaceName, i.CardFaceSearchName, LF.LayoutFaceID, i.Supertypes, i.Types, i.Subtypes, CFS.CardFaceSetID, i.SetID, i.PlatformList, i.CardSetScryfallURI, i.CardSetScryfallAPI, R.RarityID, i.IsReprint

--drop table #inserted --when relevant 
create NONCLUSTERED index ix_process_CardID on #processing(CardID)
 INCLUDE (CardFaceID, CardFaceSearchName, CardFaceSetID, SetID)

select * from #processing 

insert into tblCARD (CardID)
 select CardID from #processing 
  where OldCardID is NULL 
 group by CardID 
--I wanted to use a merge statement but I think I'm not going to risk it for now just in case

insert into tblCARD_FACE (CardID, LayoutFaceID, CardFaceName, CardFaceSearchName)
 select CardID, LayoutFaceID, CardFaceName, CardFaceSearchName 
  from #processing p
  where p.CardFaceID is NULL 
update #processing 
 set CardFaceID = CF.CardFaceID 
  from tblCARD_FACE CF 
   join #processing p
    on CF.CardFaceSearchName = p.CardFaceSearchName 
     and CF.CardID = p.CardID
   where p.CardFaceID is NULL 

update tblCARD_FACE 
 set CardFaceName = p.CardFaceName, 
  CardFaceSearchName = p.CardFaceSearchName,
  LayoutFaceID = p.LayoutFaceID 
 from tblCARD_FACE CF 
  join #processing p on CF.CardFaceID = p.CardFaceID 
 where p.CardFaceName != CF.CardFaceName 
  OR p.CardFaceSearchName != CF.CardFaceSearchName 
  OR p.LayoutFaceID != CF.LayoutFaceID ;

--supertype: 
with SupertypeLine (CardFaceID, SupertypeName) as (
 select CardFaceID, Trim(value) as SupertypeName 
  from #processing 
  CROSS APPLY String_Split(SupertypeList, ' ')
  where SupertypeList is NOT NULL)

insert into tblCARD_FACE_SUPERTYPE (CardFaceID, SupertypeID)
 select p.CardFaceID, S.SupertypeID 
 from SupertypeLine p 
  join defSUPERTYPE S on p.SupertypeName = S.SupertypeName
  except (select CardFaceID, SupertypeID from tblCARD_FACE_SUPERTYPE) ;

with TypeLine (CardFaceID, TypeName) as (
 select CardFaceID, Trim(value) as TypeName 
 from #processing 
 CROSS APPLY String_Split(TypeList, ' '))

insert into tblCARD_FACE_TYPE (CardFaceID, TypeID) 
 select p.CardFaceID, T.TypeID 
 from TypeLine p 
 join defTYPE T on p.TypeName = T.TypeName 
 except (select CardFaceID, TypeID from tblCARD_FACE_TYPE) ;

with SubtypeLine (CardFaceID, SubtypeName) as (
 select CardFaceID, Trim(value) as SubtypeName 
 from #processing 
 CROSS APPLY String_Split(SubtypeList, ' ')
 where SubtypeList is NOT NULL )

insert into tblCARD_FACE_SUBTYPE (CardFaceID, SubtypeID)
 select p.CardFaceID, S.SubtypeID 
 from SubtypeLine p 
 join defSUBTYPE S on p.SubtypeName = S.SubtypeName 
 except (select CardFaceID, SubtypeID from tblCARD_FACE_SUBTYPE) ;

insert into tblCARD_FACE_SET (CardFaceID, SetID, CardSetScryfallURI, CardSetScryfallAPI, IsReprint)
 select CardFaceID, SetID, ScryfallURI, ScryfallAPI, IsReprint
 from #processing 
  where CardFaceSetID is NULL 

update #processing 
 set CardFaceSetID = CFS.CardFaceSetID 
 from tblCARD_FACE_SET CFS 
  join #processing p on CFS.CardFaceID = p.CardFaceID 
   and CFS.SetID = p.SetID 
  where p.CardFaceSetID is NULL ;
/*
 update tblCARD_FACE_SET 
  set CardSetScryfallURI = p.ScryfallURI, 
   CardSetScryfallAPI = p.ScryfallAPI 
  from tblCARD_FACE_SET CFS 
   join #processing p on CFS.CardFaceSetID = p.CardFaceSetID 
   where CFS.CardSetScryfallURI <> p.ScryfallURI OR CFS.CardSetScryfallAPI <> p.ScryfallAPI
   */
--pass down to platforms processor 
--or temps for now: 
with MatchPlatforms (CardFaceSetID, PlatformName) as (
select CardFaceSetID, Trim(value) as PlatformName 
 from #processing 
 cross apply string_split(PlatformList, ','))

insert into tblCARD_FACE_SET_PLATFORM (CardFaceSetID, PlatformID)
 select p.CardFaceSetID, DP.PlatformID 
  from MatchPlatforms p 
  join defPLATFORM DP on DP.PlatformName = p.PlatformName 
  group by p.CardFaceSetID, DP.PlatformID 
  except (select CardFaceSetID, PlatformID from tblCARD_FACE_SET_PLATFORM) ;
  --additive-only for the time being 
/*
delete from SCRY_CANON_CARDS where PK = (select PK from #inserted)
*/
/*
select p.CardFaceSetID, p.PlatformName, DP.PlatformID --into #pplatforms 
 from MatchPlatforms p 
  join defPLATFORM DP on DP.PlatformName = p.PlatformName 
  LEFT join tblCARD_FACE_SET_PLATFORM CSP on p.CardFaceSetID != CSP.CardFaceSetID 
 --where CSP.PlatformID != DP.PlatformID
/*
select p.CardFaceSetID as CardFaceSetID, p.PlatformID as PlatformID into #platformsupdate from #pplatforms p
 join tblCARD_FACE_SET_PLATFORM CSP on p.CardFaceSetID = CSP.CardFaceSetID 
 where CSP.PlatformID != p.PlatformID */

SELECT 
TABLE_CATALOG,
TABLE_SCHEMA,
TABLE_NAME, 
COLUMN_NAME, 
DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'tblCARD' 

select * from information_schema.constraint_column_usage 

alter table tblCARD ADD PRIMARY KEY (CardCount)

create nonclustered index ix_CardIDs on tblCard(CardID)

alter table tblCARD 
 Add CONSTRAINT const_Unique_CardIDs UNIQUE (CardID)

select * from tblCARD 
--alter table tblCARD 
 --drop constraint PK__tblCARD__55FECD8FF35F38A2
--select * from tblCARD_FACE_SET 

select * from SCRY_CANON_CARDS where CardID = '20e7a93f-77ce-466b-8586-35d390689d0c'

select * from tblCARD_FACE 

alter table tblCARD_FACE 
 Add Constraint const_Cards_HaveFaces FOREIGN KEY (CardID) references tblCARD(CardID)

alter table tblCARD_FACE 
 Add Constraint const_Unique_FacesPerCard UNIQUE (CardID, CardFaceSearchName)

alter table tblCARD_FACE_SET 
 ADD RarityID int,
  IsReprint char(1) SPARSE NULL 


select * from tblCARD_FACE_SET_PLATFORM

select * into BACKUP_SCRY_CANON_CARDS from SCRY_CANON_CARDS

create table tblCARD_FACE_SET_PLATFORM (
 CardFaceSetID int FOREIGN KEY references tblCARD_FACE_SET ON DELETE CASCADE,
 PlatformID int FOREIGN KEY references defPLATFORM,
 Constraint PK_CardFaceSetPlatform PRIMARY KEY (CardFaceSetID, PlatformID)
)

truncate table tblCARD_FACE_SET_PLATFORM
delete from tblCARD_FACE_SET 
truncate table tblCARD_FACE_TYPE
truncate table tblCARD_FACE_SUBTYPE
truncate table tblCARD_FACE_SUPERTYPE
truncate table tblCARD_FACE 
truncate table tblCARD_FACE_SET  
delete from tblCARD 

select * from tblCARD_FACE 

truncate table SCRY_CANON_CARDS
drop trigger t_CanonCardTest

use deckdater_dev
GO 
insert into SCRY_CANON_CARDS (CardID, CardFaceName, CardFaceSearchName, CardSetScryfallAPI, CardSetScryfallURI, LayoutName, FaceName, Supertypes, Types, Subtypes, SetID, RarityName, PlatformList, IsReprint)
 select CardID, CardFaceName, CardFaceSearchName, CardSetScryfallAPI, CardSetScryfallURI, LayoutName, FaceName, Supertypes, Types, Subtypes, SetID, RarityName, PlatformList, IsReprint from WORK_FROM

select C.CardID, CF.CardFaceID, CF.CardFaceName, CFS.CardFaceSetID, CFS.SetID from tblCARD_FACE_SET CFS 
 join tblCARD_FACE CF on CFS.CardFaceID = CF.CardFaceID 
 join tblCARD C on CF.CardID = C.CardID 
 where CFS.RarityID is NOT NULL 

delete from tblCARD_FACE_SET where RarityID is NOT NULL 

alter table tblCARD_FACE 
 Add CONSTRAINT FK_Card_CardFace FOREIGN KEY (CardID) references tblCARD (CardID)


alter table tblCARD_FACE_SET 
 Add Constraint FK_CardFace_CardFaceSet FOREIGN KEY (CardFaceID) references tblCARD_FACE 

alter table tblCARD_FACE_TYPE 
 Add Constraint FK_CardType_CardFace FOREIGN KEY (CardFaceID) references tblCARD_FACE 
 
alter table tblCARD_FACE_SUBTYPE 
 Add Constraint FK_CardSubtype_CardFace FOREIGN KEY (CardFaceID) references tblCARD_FACE 
 

alter table tblCARD_FACE_SUPERTYPE 
 Add Constraint FK_CardSupertype_CardFace FOREIGN KEY (CardFaceID) references tblCARD_FACE 
 
alter table tblCARD_FACE_SET_PLATFORM
 Add Constraint FK_CardFaceSet_Platform FOREIGN KEY (CardFaceSetID) references tblCARD_FACE_SET 

exec dbo.ENV_VAR_UPD8_MASS