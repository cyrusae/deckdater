

create OR alter proc UNSTAGE_SetsExisting 
 as BEGIN 
 set NOCOUNT ON 
 if exists (select SetID from STAGE_SETS)
  BEGIN 
  begin tran 
   begin tran addsets
   insert into SCRY_CANON_SETS (SetID, SetCode, SetName, SetReleaseDate, SetTypeName, SetCollectorCount, SetScryfallURI, SetScryfallAPI, BlockCode, SetIsDigital)
    select SetID, SetCode, SetName, SetReleaseDate, SetTypeName, SetCollectorCount, SetScryfallURI, SetScryfallAPI, BlockCode, SetIsDigital from STAGE_SETS 
   commit 
   truncate table STAGE_SETS 
  commit 
  END 
 END 
GO 
GO 

create OR alter proc UNSTAGE_CardsExisting 
 as BEGIN 
 set NOCOUNT ON 
 if exists (select CardID from STAGE_CARDS)
  BEGIN 
  begin tran 
   begin tran addcards 
   insert into SCRY_CANON_CARDS (CardID, CardFaceName, CardFaceSearchName, CardSetScryfallAPI, CardSetScryfallURI, LayoutName, FaceName, Supertypes, Types, Subtypes, SetID, RarityName, PlatformName, IsReprint)
    select CardID, CardFaceName, CardFaceSearchName, CardSetScryfallAPI, CardSetScryfallURI, LayoutName, FaceName, Supertypes, Types, Subtypes, SetID, RarityName, PlatformName, IsReprint from STAGE_CARDS
   commit 
   truncate table STAGE_CARDS 
  commit 
  END 
 END 
GO 

