use deckdater_dev 
GO 

create OR alter trigger t_CanonCardTest on SCRY_CANON_CARDS 
after INSERT 
AS begin 
set NOCOUNT ON 
select * into #inserted from inserted 
create NONCLUSTERED INDEX ix_ins_CardID on #inserted(CardID)
 INCLUDE (CardFaceSearchName, LayoutName, FaceName, SetID)

select i.CardID as CardID, C.CardID as OldCardID, CF.CardFaceID as CardFaceID, i.CardFaceName as CardFaceName, i.CardFaceSearchName as CardFaceSearchName, LF.LayoutFaceID as LayoutFaceID, i.Supertypes as SupertypeList, i.Types as TypeList, i.Subtypes as SubtypeList, CFS.CardFaceSetID as CardFaceSetID, i.SetID as SetID, i.PlatformList as PlatformList, i.CardSetScryfallURI as ScryfallURI, i.CardSetScryfallAPI as ScryfallAPI, R.RarityID as RarityID, i.IsReprint as IsReprint into #processing 
 from #inserted i 
 join defRARITY R on i.RarityName = R.RarityName 
 join defLAYOUT L on i.LayoutName = L.LayoutName 
 join defFACE F on i.FaceName = F.FaceName
 join refLAYOUT_FACE LF 
  on (L.LayoutID = LF.LayoutID 
      AND F.FaceID = LF.FaceID)
 LEFT join tblCARD C on i.CardID = C.CardID 
 LEFT join tblCARD_FACE CF 
  on (i.CardID = CF.CardFaceID 
     AND i.CardFaceSearchName = CF.CardFaceSearchName 
     AND LF.LayoutFaceID = CF.LayoutFaceID)
 LEFT join tblCARD_FACE_SET CFS 
  on (i.SetID = CFS.SetID 
     AND CF.CardFaceID = CFS.CardFaceID) 

--drop table #inserted --when relevant 
create NONCLUSTERED index ix_process_CardID on #processing(CardID)
 INCLUDE (CardFaceID, CardFaceSearchName, CardFaceSetID, SetID)

insert into tblCARD (CardID)
 select CardID from #processing 
  where OldCardID is NULL 
--I wanted to use a merge statement but I think I'm not going to risk it for now just in case

insert into tblCARD_FACE 
 select CardFaceName, CardFaceSearchName, LayoutFaceID 
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
 where p.CardFaceName <> CF.CardFaceName 
  OR p.CardFaceSearchName <> CF.CardFaceSearchName 
  OR p.LayoutFaceID <> CF.LayoutFaceID 
 --pass down to type line processor (three times)

insert into tblCARD_FACE_SET (CardFaceID, SetID, CardSetScryfallURI, CardSetScryfallAPI)
 select CardFaceID, SetID, ScryfallURI, ScryfallAPI 
 from #processing 
  where CardFaceSetID is NULL 

update #processing 
 set CardFaceSetID = CFS.CardFaceSetID 
 from tblCARD_FACE_SET CFS 
  join #processing p on CFS.CardFaceID = p.CardFaceID 
   and CFS.SetID = p.SetID 
  where p.CardFaceSetID is NULL 
 update tblCARD_FACE_SET 
  set CardSetScryfallURI = p.ScryfallURI, 
   CardSetScryfallAPI = p.ScryfallAPI 
  from tblCARD_FACE_SET CFS 
   join #processing p on CFS.CardFaceSetID = p.CardFaceSetID 
   where CFS.CardSetScryfallURI <> p.ScryfallURI OR CFS.CardSetScryfallAPI <> p.ScryfallAPI
--pass down to platforms processor 
--or temps for now: 
select p.CardFaceSetID, DP.PlatformID into #pplatforms 
 from #processing p 
 join defPLATFORM DP on DP.PlatformName = (select Trim(value) from STRING_SPLIT(p.PlatformList, ','))
insert into tblCARD_FACE_SET_PLATFORM (CardFaceSetID, PlatformID)
 select p.CardFaceSetID, p.PlatformID from #pplatforms p
 join tblCARD_FACE_SET_PLATFORM CSP on p.CardFaceSetID = CSP.CardFaceSetID 
 where CSP.PlatformID <> p.PlatformID --additive-only for the time being 
delete from SCRY_CANON_CARDS where PK = (select PK from #inserted)
END 
GO 

--drop table #processing 
/* merge tblCARD_FACE as TARGET
 using #processing as SOURCE 
 on (TARGET.CardFaceID = SOURCE.CardFaceID)
 when NOT MATCHED by TARGET 
  then INSERT (CardID, CardFaceName, CardFaceSearchName, LayoutFaceID) VALUES (SOURCE.CardID, SOURCE.CardFaceName, SOURCE.CardFaceSearchName, SOURCE.LayoutFaceID)
 when MATCHED and 
  (TARGET.CardFaceName <> SOURCE.CardFaceName) 
  or (TARGET.CardFaceSearchName <> SOURCE.CardFaceSearchName)
  then UPDATE SET TARGET.CardFaceName = SOURCE.CardFaceName,
   TARGET.CardFaceSearchName = SOURCE.CardFaceSearchName; 

insert into tblCARD_FACE_SET (CardFaceID, SetID, CardSetScryfallURI, CardSetScryfallAPI)
 select CardFaceID, SetID, ScryfallURI, ScryfallAPI from #processing where CardFaceSetID is NULL 
update #processing 
 set CardFaceSetID = CFS.CardFaceSetID 
 where CardFaceSetID is NULL 
  and CardFaceID = (select CardFaceID from tblCARD_FACE_SET)
  and SetID = (select SetID from tblCARD_FACE_SET)

insert into refLAYOUT_FACE (LayoutID, FaceID)
select LayoutID, FaceID from defLAYOUT 
 LEFT join defFACE on 1=1 


truncate table SCRY_CANON_CARDS*/
select * into SCRY_CANON_CARDS_TEST from SCRY_CANON_CARDS where 0=1
alter table SCRY_CANON_CARDS_TEST 
 ADD IsReprint char(1) NULL 
select * from SCRY_CANON_CARDS_TEST
alter table SCRY_CANON_CARDS_TEST drop column PK 
GO 
create OR alter trigger t_CanonCardTestTest on SCRY_CANON_CARDS_TEST 
after INSERT 
AS begin 
set NOCOUNT ON 
select * into #inserted from inserted 

create NONCLUSTERED INDEX ix_ins_CardID on #inserted(CardID)
 INCLUDE (CardFaceSearchName, LayoutName, FaceName, SetID)

select i.CardID as CardID, C.CardID as OldCardID, CF.CardFaceID as CardFaceID, i.CardFaceName as CardFaceName, i.CardFaceSearchName as CardFaceSearchName, LF.LayoutFaceID as LayoutFaceID, i.Supertypes as SupertypeList, i.Types as TypeList, i.Subtypes as SubtypeList, CFS.CardFaceSetID as CardFaceSetID, i.SetID as SetID, i.PlatformList as PlatformList, i.CardSetScryfallURI as ScryfallURI, i.CardSetScryfallAPI as ScryfallAPI, R.RarityID as RarityID, i.IsReprint as IsReprint into #processing 
 from #inserted i 
 join defRARITY R on i.RarityName = R.RarityName 
 join defLAYOUT L on i.LayoutName = L.LayoutName 
 join defFACE F on i.FaceName = F.FaceName
 join refLAYOUT_FACE LF 
  on (L.LayoutID = LF.LayoutID 
      AND F.FaceID = LF.FaceID)
 LEFT join tblCARD C on i.CardID = C.CardID 
 LEFT join tblCARD_FACE CF 
  on (i.CardID = CF.CardFaceID 
     AND i.CardFaceSearchName = CF.CardFaceSearchName 
     AND LF.LayoutFaceID = CF.LayoutFaceID)
 LEFT join tblCARD_FACE_SET CFS 
  on (i.SetID = CFS.SetID 
     AND CF.CardFaceID = CFS.CardFaceID) 

--drop table #inserted --when relevant 
create NONCLUSTERED index ix_process_CardID on #processing(CardID)
 INCLUDE (CardFaceID, CardFaceSearchName, CardFaceSetID, SetID)

insert into tblCARD (CardID)
 select CardID from #processing 
  where OldCardID is NULL 
--I wanted to use a merge statement but I think I'm not going to risk it for now just in case

insert into tblCARD_FACE 
 select CardFaceName, CardFaceSearchName, LayoutFaceID 
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
 where p.CardFaceName <> CF.CardFaceName 
  OR p.CardFaceSearchName <> CF.CardFaceSearchName 
  OR p.LayoutFaceID <> CF.LayoutFaceID 
 --pass down to type line processor (three times)

insert into tblCARD_FACE_SET (CardFaceID, SetID, CardSetScryfallURI, CardSetScryfallAPI)
 select CardFaceID, SetID, ScryfallURI, ScryfallAPI 
 from #processing 
  where CardFaceSetID is NULL 

update #processing 
 set CardFaceSetID = CFS.CardFaceSetID 
 from tblCARD_FACE_SET CFS 
  join #processing p on CFS.CardFaceID = p.CardFaceID 
   and CFS.SetID = p.SetID 
  where p.CardFaceSetID is NULL 
 update tblCARD_FACE_SET 
  set CardSetScryfallURI = p.ScryfallURI, 
   CardSetScryfallAPI = p.ScryfallAPI 
  from tblCARD_FACE_SET CFS 
   join #processing p on CFS.CardFaceSetID = p.CardFaceSetID 
   where CFS.CardSetScryfallURI <> p.ScryfallURI OR CFS.CardSetScryfallAPI <> p.ScryfallAPI
--pass down to platforms processor 
--or temps for now: 
select p.CardFaceSetID, DP.PlatformID into #pplatforms 
 from #processing p 
 join defPLATFORM DP on DP.PlatformName = (select Trim(value) from STRING_SPLIT(p.PlatformList, ','))
insert into tblCARD_FACE_SET_PLATFORM (CardFaceSetID, PlatformID)
 select p.CardFaceSetID, p.PlatformID from #pplatforms p
 join tblCARD_FACE_SET_PLATFORM CSP on p.CardFaceSetID = CSP.CardFaceSetID 
 where CSP.PlatformID <> p.PlatformID --additive-only for the time being 
END 
GO 