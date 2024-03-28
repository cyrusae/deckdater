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

exec dbo.UNSTAGE_CardsExisting

select * from STAGE_CARDS

delete from STAGE_CARDS where CardID in (select CardID from tblCARD)
delete from STAGE_CARDS where CardFaceSearchName in (select CardFaceSearchName from tblCARD_FACE)

select * from tblCARD


select * from tblSET  

exec dbo.UNSTAGE_SetsExisting