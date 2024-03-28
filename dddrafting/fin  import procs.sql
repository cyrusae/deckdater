use Info_430_deckdater 
GO 

create OR alter trigger t_AddCanonSets on SCRY_CANON_SETS 
 after INSERT 
 as BEGIN 

 if @@ROWCOUNT < 1 RETURN ; 
 set NOCOUNT ON 
 select i.SetID, i.SetCode, i.SetName, i.SetReleaseDate, T.SetTypeID, i.SetCollectorCount, i.SetScryfallURI, i.SetScryfallAPI, B.BlockID, i.SetIsDigital into #inserted  
  from inserted i 
  join defSET_TYPE T on i.SetTypeName = T.SetTypeName 
  LEFT join tblBLOCK B on i.BlockCode = B.BlockCode 
 
 create NONCLUSTERED index ix_ins_SetID on #inserted (SetID)
 
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

 insert into tblSET (SetID, SetCode, SetName, SetReleaseDate, SetTypeID, SetCollectorCount, SetScryfallURI, SetScryfallAPI, BlockID, SetIsDigital)
  select SetID, SetCode, SetName, SetReleaseDate, SetTypeID, SetCollectorCount, SetScryfallURI, SetScryfallAPI, BlockID, SetIsDigital from #inserted 
  where not exists (select SetID from tblSET) 
 
 delete from SCRY_CANON_SETS where SetID in (select SetID from #inserted)
 drop table #inserted 
 END 
GO 


create OR alter trigger t_AddCanonCards on SCRY_CANON_CARDS 
 after INSERT 
 as BEGIN 
 
 if @@ROWCOUNT < 1 RETURN ;
 set NOCOUNT ON 
 select * into #inserted from inserted 

 alter table #inserted 
  Add Constraint temp_ins_PK PRIMARY KEY (PK)

 create NONCLUSTERED INDEX ix_ins_CardID on #inserted(CardID)
 INCLUDE (CardFaceSearchName, LayoutName, FaceName, SetID)

 select i.PK as PK, i.CardID as CardID, C.CardID as OldCardID, CF.CardFaceID as CardFaceID, i.CardFaceName as CardFaceName, i.CardFaceSearchName as CardFaceSearchName, LF.LayoutFaceID as LayoutFaceID, i.Supertypes as SupertypeList, i.Types as TypeList, i.Subtypes as SubtypeList, CFS.CardFaceSetID as CardFaceSetID, i.SetID as SetID, P.PlatformID as PlatformID, i.CardSetScryfallURI as ScryfallURI, i.CardSetScryfallAPI as ScryfallAPI, R.RarityID as RarityID, i.IsReprint as IsReprint into #processing
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
  Add Constraint temp_procss_PK PRIMARY KEY (PK)

 create NONCLUSTERED index ix_process_CardID on #processing(CardID)
  INCLUDE (CardFaceID, CardFaceSearchName, CardFaceSetID, SetID, PlatformID)

 insert into tblCARD (CardID)
  select CardID from #processing 
   where OldCardID is NULL 
  group by CardID 

 insert into tblCARD_FACE (CardID, LayoutFaceID, CardFaceName, CardFaceSearchName)
  select CardID, LayoutFaceID, CardFaceName, CardFaceSearchName 
   from #processing p
   where p.CardFaceID is NULL 
   group by CardID, LayoutFaceID, CardFaceName, CardFaceSearchName
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
 
 with SupertypeLine (CardFaceID, SupertypeName) as (
 select CardFaceID, Trim(value) as SupertypeName 
  from #processing 
  CROSS APPLY String_Split(SupertypeList, ' ')
  where SupertypeList is NOT NULL
  group by CardFaceID)

 insert into tblCARD_FACE_SUPERTYPE (CardFaceID, SupertypeID)
  select p.CardFaceID, S.SupertypeID 
  from SupertypeLine p 
   join defSUPERTYPE S on p.SupertypeName = S.SupertypeName
   except (select CardFaceID, SupertypeID from tblCARD_FACE_SUPERTYPE) ;

 with TypeLine (CardFaceID, TypeName) as (
  select CardFaceID, Trim(value) as TypeName 
  from #processing 
  CROSS APPLY String_Split(TypeList, ' ')
  group by CardFaceID)

 insert into tblCARD_FACE_TYPE (CardFaceID, TypeID) 
  select p.CardFaceID, T.TypeID 
  from TypeLine p 
  join defTYPE T on p.TypeName = T.TypeName 
  except (select CardFaceID, TypeID from tblCARD_FACE_TYPE) ;

 with SubtypeLine (CardFaceID, SubtypeName) as (
  select CardFaceID, Trim(value) as SubtypeName 
  from #processing 
  CROSS APPLY String_Split(SubtypeList, ' ')
  where SubtypeList is NOT NULL 
  group by CardFaceID)

 insert into tblCARD_FACE_SUBTYPE (CardFaceID, SubtypeID)
  select p.CardFaceID, S.SubtypeID 
  from SubtypeLine p 
  join defSUBTYPE S on p.SubtypeName = S.SubtypeName 
  except (select CardFaceID, SubtypeID from tblCARD_FACE_SUBTYPE) ;

 insert into tblCARD_FACE_SET (CardFaceID, SetID, RarityID, IsReprint)
  select CardFaceID, SetID, RarityID, IsReprint
  from #processing 
   where CardFaceSetID is NULL 
  group by CardFaceID, SetID, RarityID, IsReprint

 update #processing 
  set CardFaceSetID = CFS.CardFaceSetID 
  from tblCARD_FACE_SET CFS 
   join #processing p on CFS.CardFaceID = p.CardFaceID 
    and CFS.SetID = p.SetID 
   where p.CardFaceSetID is NULL 
 
 update tblCARD_FACE_SET 
  set 
   RarityID = p.RarityID, 
   IsReprint = p.IsReprint
  from tblCARD_FACE_SET CFS 
   join #processing p on CFS.CardFaceSetID = p.CardFaceSetID 
   where CFS.RarityID != p.RarityID 
    OR CFS.IsReprint != p.IsReprint ;

 insert into tblCARD_FACE_SET_PLATFORM (CardFaceSetID, PlatformID, CardSetPlatformScryfallURI, CardSetPlatformScryfallAPI)
  select p.CardFaceSetID, p.PlatformID, p.ScryfallURI, p.ScryfallAPI
   from #processing p 
   group by p.CardFaceSetID, p.PlatformID, p.ScryfallURI, p.ScryfallAPI
   except (select CardFaceSetID, PlatformID from tblCARD_FACE_SET_PLATFORM) 
  
 update tblCARD_FACE_SET_PLATFORM 
  set CardSetPlatformScryfallURI = p.ScryfallURI, 
    CardSetPlatformScryfallAPI = p.ScryfallAPI 
  from #processing p 
    join tblCARD_FACE_SET_PLATFORM CFSP 
     on (p.CardFaceSetID = CFSP.CardFaceSetID 
      and p.PlatformID = p.PlatformID)
    where p.ScryfallURI != CFSP.CardSetPlatformScryfallURI 
     OR p.ScryfallAPI != CFSP.CardSetPlatformScryfallAPI ;

 delete from SCRY_CANON_CARDS where PK in (select PK from #inserted)
 drop table #inserted 
 drop table #processing 
 END 
GO 