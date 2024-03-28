use deckdater_dev
GO 

create OR alter trigger t_AddCanonCards on SCRY_CANON_CARDS 
 after INSERT 
 as BEGIN 
 
 if @@ROWCOUNT < 1 RETURN ;
 set NOCOUNT ON 
 select * into #inserted from inserted 

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

 create NONCLUSTERED index ix_process_CardID on #processing(CardID)
  INCLUDE (CardFaceID, CardFaceSearchName, CardFaceSetID, SetID)

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

 insert into tblCARD_FACE_SET (CardFaceID, SetID, CardSetScryfallURI, CardSetScryfallAPI, IsReprint)
  select CardFaceID, SetID, ScryfallURI, ScryfallAPI, IsReprint
  from #processing 
   where CardFaceSetID is NULL 
  group by CardFaceID, SetID, ScryfallURI, ScryfallAPI, IsReprint

 update #processing 
  set CardFaceSetID = CFS.CardFaceSetID 
  from tblCARD_FACE_SET CFS 
   join #processing p on CFS.CardFaceID = p.CardFaceID 
    and CFS.SetID = p.SetID 
   where p.CardFaceSetID is NULL 
 
 update tblCARD_FACE_SET 
  set CardSetScryfallURI = p.ScryfallURI, 
   CardSetScryfallAPI = p.ScryfallAPI,
   RarityID = p.RarityID, 
   IsReprint = p.IsReprint
  from tblCARD_FACE_SET CFS 
   join #processing p on CFS.CardFaceSetID = p.CardFaceSetID 
   where CFS.CardSetScryfallURI != p.ScryfallURI 
    OR CFS.CardSetScryfallAPI != p.ScryfallAPI
    OR CFS.RarityID != p.RarityID 
    OR CFS.IsReprint != p.IsReprint ;

 with MatchPlatforms (CardFaceSetID, PlatformName) as (
 select CardFaceSetID, Trim(value) as PlatformName 
  from #processing 
  cross apply string_split(PlatformList, ',')
  group by CardFaceSetID)

 insert into tblCARD_FACE_SET_PLATFORM (CardFaceSetID, PlatformID)
  select p.CardFaceSetID, DP.PlatformID 
   from MatchPlatforms p 
   join defPLATFORM DP on DP.PlatformName = p.PlatformName 
   group by p.CardFaceSetID, DP.PlatformID 
   except (select CardFaceSetID, PlatformID from tblCARD_FACE_SET_PLATFORM) ;

 delete from SCRY_CANON_CARDS where PK in (select PK from #inserted)
 drop table #inserted 
 drop table #processing 
 END 
GO 