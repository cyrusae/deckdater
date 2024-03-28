--note to self: change column name in cardface to searhcnamem

--things that happen in cards 
----platforms (list, string, comma-separated with spaces)
----type/subtype/supertype (list, space-separated)

create type ProcessCanonCards as table (
 PK int Identity(1,1) primary key NOT NULL,
 CardID varchar(36) NOT NULL,
 CardFaceName varchar(200) NOT NULL,
 CardFaceSearchName varchar(200) NOT NULL, 
 LayoutFaceID int,
 SetID varchar(36) NOT NULL,
 CardSetScryfallURI varchar(300),
 CardSetScryfallAPI varchar(300),
 RarityID int,
 IsReprint char(1) NULL,
 Supertypes varchar(100) NULL, 
 Types varchar(100) NOT NULL,
 Subtypes varchar(100) NOT NULL)
GO 

create type ProcessKnownFaces as table (
 PK int Identity(1,1) primary key NOT NULL,
 CardID varchar(36) NOT NULL,
 CardFaceID int,
 CardFaceName varchar(200) NOT NULL,
 CardFaceSearchName varchar(200) NOT NULL, 
 LayoutFaceID int,
 SetID varchar(36) NOT NULL,
 CardSetScryfallURI varchar(300),
 CardSetScryfallAPI varchar(300),
 RarityID int,
 IsReprint char(1) NULL,
 Supertypes varchar(100) NULL, 
 Types varchar(100) NOT NULL,
 Subtypes varchar(100) NOT NULL)
GO 

create type ProcessCardPrintings as table (
 PK int Identity(1,1) primary key NOT NULL,
 CardID varchar(36) NOT NULL,
 CardFaceSearchName varchar(200) NOT NULL,
 SetID varchar(36) NOT NULL,
 CardSetScryfallURI varchar(300),
 CardSetScryfallAPI varchar(300),
 RarityID int,
 IsReprint char(1) NULL,
 PlatformID int)
GO 

create type ProcessTypeLine as table (
 PK int Identity(1,1) primary key NOT NULL,
 CardID varchar(36) NOT NULL,
 CardFaceSearchName varchar(200) NOT NULL,
 ID int)
GO 

declare @newcards ProcessCanonCards, @prints ProcessCardPrintings, @supertypes ProcessTypeLine, @types ProcessTypeLine, @subtypes ProcessTypeLine, @newfaces ProcessCanonCards, @oldfaces ProcessKnownCards, @thisface ProcessCanonCards, @thisprint ProcessCardPrintings, @thisline ProcessTypeLine, @loop int, @this int, @updort int, @novel int 

insert into @newcards (CardID, CardFaceName, CardFaceSearchName, SetID, CardSetScryfallURI, CardSetScryfallAPI, IsReprint, RarityID, Supertypes, Types, Subtypes)
 select CardID, CardFaceName, CardFaceSearchName, SetID, CardSetScryfallURI, CardSetScryfallAPI, IsReprint, RarityID, Supertypes, Types, Subtypes
  from inserted i 
  join defLAYOUT L on i.LayoutName = L.LayoutName 
  join defFACE F on i.FaceName = F.Facename 
  join refLAYOUT_FACE LF on (L.LayoutID = LF.LayoutID 
     and F.FaceID = LF.FaceID)
  join defRARITY R on i.RarityName = R.RarityName 

--is it a new card?
--always do this top-level 
insert into tblCARD (CardID)
 select CardID
 from @newcards 
 except (select CardID from tblCARD)

--is it a new face?
insert into @oldfaces (CardID, CardFaceID, CardFaceName, CardFaceSearchName, SetID, CardSetScryfallURI, CardSetScryfallAPI, RarityID, Supertypes, Types, Subtypes)
 select ncf.CardID, CF.CardFaceID, ncf.CardFaceName, ncf.CardFaceSearchName, ncf.SetID, CardSetScryfallURI, CardSetScryfallAPI, RarityID, Supertypes, Types, Subtypes
  from @cardfaces ncf 
  join tblCARD_FACE CF on ncf.CardID = CF.CardID 
       and ncf.CardFaceSearchName = CF.CardFaceSearchName 

--this is the one that will need to scope_identity()
insert into @newfaces (CardID, CardFaceName, CardFaceSearchName, SetID, CardSetScryfallURI, CardSetScryfallAPI, RarityID, Supertypes, Types, Subtypes)
 select CardID, CardFaceName, CardFaceSearchName, SetID, CardSetScryfallURI, CardSetScryfallAPI, RarityID, Supertypes, Types, Subtypes
  from @cardfaces ncf 
  except (select CardID, CardFaceSearchName from @oldfaces)

--is it a new printing?
--is it an update?

select CardID, SetID, value as PlatformName 
 into #platforms 
 from @newcards 
 CROSS APPLY STRING_SPLIT(PlatformList, ', ')

insert into @prints (CardID, CardFaceSearchName, SetID, CardSetScryfallURI, CardSetScryfallAPI, RarityID, IsReprint, PlatformID)
 select N.CardID, CardFaceSearchName, N.SetID, CardSetScryfallURI, CardSetScryfallAPI, RarityID, IsReprint, PlatformID 
 from @newcards N 
 join #platforms tmp on N.CardID = tmp.CardID 
   and N.SetID = tmp.SetID 
 join defPLATFORM P on tmp.PlatformName = P.PlatformName

drop table #platforms 

select CardID, CardFaceSearchName, value as SupertypeName 
 into #supertypes
 from @newcards 
  CROSS APPLY STRING_SPLIT (Supertypes, ' ')

insert into @supertypes (CardID, CardFaceSearchName, ID) 
 select CardID, CardFaceSearchName, SupertypeID 
 from #supertypes tmp 
 join defSUPERTYPE S on tmp.SupertypeName = S.SupertypeName

drop table #supertypes 
  
select CardID, CardFaceSearchName, value as TypeName 
 into #types
 from @newcards 
  CROSS APPLY STRING_SPLIT (Types, ' ')
 
insert into @types (CardID, CardFaceSearchName, ID) 
 select CardID, CardFaceSearchName, TypeID 
 from #types tmp 
 join defTYPE T on tmp.TypeName = T.TypeName

drop table #types 

select CardID, CardFaceSearchName, value as SubtypeName 
 into #subtypes 
 from @newcards 
  CROSS APPLY STRING_SPLIT (Subtypes, ' ')

insert into @subtypes (CardID, CardFaceSearchName, ID) 
 select CardID, CardFaceSearchName, SubtypeID 
 from #subtypes tmp 
 join defSUBTYPE S on tmp.SubtypeName = S.SubtypeName

drop table #subtypes 

