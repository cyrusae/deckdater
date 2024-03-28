create type DateableDecklist as table (
 PK int Identity(1,1) primary key NOT NULL,
 CardFaceID int,
 FirstCardFaceSetID int NULL,
 FirstPrintDate date NULL,
 LastCardFaceSetID int NULL,
 LastPrintDate date NULL) 
  with (MEMORY_OPTIMIZED = ON);
GO 

create type CardList as table (
 CardID varchar(36) NULL,
 CardFaceID int)
GO 

create type DeckDated as table (
 SetCode char(3),
 SetName varchar(200),
 SetReleaseDate date,
 SetScryfallURI varchar(500))
  with (MEMORY_OPTIMIZED = ON);
GO 

create type BasicLandOutput as table (
 PK int Identity(1,1) primary key NOT NULL,
 CardFaceID int,
 SubtypeID int,
 SubtypeName varchar(25),
 SnowLand int DEFAULT 0) 
  with (MEMORY_OPTIMIZED = ON);
GO 

create OR alter function getme_basiclands()
 returns BasicLandOutput 
 as BEGIN 
 declare @RET BasicLandOutput 
 with Basics (CardFaceID) as (select CardFaceID from tblCARD_FACE_SUPERTYPE CFS
  join defSUPERTYPE S on CFS.SupertypeID = S.SupertypeID 
  where SupertypeName = 'Basic')

 insert into @RET (CardFaceID, SubtypeID, SubtypeName, SnowLand)
  select CF.CardFaceID, Sub.SubtypeID, Sub.SubtypeName, (Count(Csup.SupertypeID) - 1) as SnowLand --Basic snow lands have the supertypes "Basic" and "Snow" instead of just "Basic"
   from tblCARD_FACE CF 
    join tblCARD_FACE_TYPE CTyp on CF.CardFaceID = CTyp.CardFaceID 
    join defTYPE T on CTyp.TypeID = T.TypeID 
    join tblCARD_FACE_SUPERTYPE CSup on CF.CardFaceID = CSup.CardFaceID 
    join tblCARD_FACE_SUBTYPE CSub on CF.CardFaceID = CSub.CardFaceID 
    join defSUBTYPE Sub on CSub.SubtypeID = Sub.SubtypeID 
    where T.TypeName = 'Land'
     and CF.CardFaceID in (select CardFaceID from Basics)
    group by CF.CardFaceID, Sub.SubtypeID, Sub.SubtypeName
 return @RET 
 END 
GO 


create OR alter function fetch_Cardlist(@DeckID int)
 returns CardList 
 as BEGIN 
 declare @RET CardList
 insert into @RET 
  select CardFaceID from tblDECK_CARD
  where DeckID = @DeckID 
 insert into @RET 
  select CardFaceID from tblDECK_CARD_ZONE 
  where DeckID = @DeckID 
   and CardFaceID not in (select CardFaceID from @RET)
  group by CardFaceID 
 return @RET 
 END
GO 

create OR alter function o_DateThisDeck(@DeckID int)
 returns DeckDated 
 as BEGIN 
 declare @RET DeckDated, @Inspect CardList, @CutBasics BasicLandOutput, @Match DateableDecklist, @LastSeen date 
 set @CutBasics = dbo.getme_basiclands()
 set @Inspect = dbo.fetch_Cardlist(@DeckID)
 delete from @Inspect where CardFaceID in (select CardFaceID from @CutBasics)
 insert into @Match (CardFaceID, LastCardFaceSetID, LastPrintDate)
  select I.CardFaceID, CFS.CardFaceSetID, Max(S.SetReleaseDate)
   from @Inspect I 
   join tblCARD_FACE_SET CFS on I.CardFaceID = CFS.CardFaceID 
   join tblSET S on CFS.SetID = S.SetID 
   group by I.CardFaceID 
 set @LastSeen = (select Max(LastPrintDate) from @Match)
 insert into @RET (SetCode, SetName, SetReleaseDate, SetScryfallURI)
  select SetCode, SetName, SetReleaseDate, SetScryfallURI 
   from tblSET 
   where SetReleaseDate > @LastSeen 
  order by SetReleaseDate asc 
 return @RET 
 END 
GO 

create OR alter proc DEMO_DateTestDeck 
 as BEGIN 
 declare @DeckToDate int, @results DeckDated, @DFrows int, @DFoffset int 
 set @DFrows = (select Count(DeckID) from tblDECK_FORMAT)
 set @DFoffset = Floor(Rand() * @DFrows)
 set @DeckToDate = (select DeckID from tblDECK_FORMAT
  order by DeckID 
  offset @DFoffset rows 
  fetch next 1 rows only)
 set @results = dbo.o_DateThisDeck(@DeckToDate)
 select * from @results --will this successfully, like, bootleg-print it...?
 END 
GO 