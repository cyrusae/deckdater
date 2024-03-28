create type BasicLandOutput as table (
 PK int Identity(1,1) primary key NOT NULL,
 CardFaceID int,
 SubtypeID int,
 SubtypeName varchar(25),
 SnowLand int DEFAULT 0) 
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

create type WrangleDecklist as table (
 PK int Identity(1,1) primary key NOT NULL,
 CardFaceID int NOT NULL,
 Quantity int DEFAULT 1,
 ContentID char(4) NULL)
GO 

create OR alter function fetch_DeckByID (@DeckID int)
 returns WrangleDecklist 
 as BEGIN 
 declare @RET WrangleDecklist 
 set @RET = (select CardFaceID, Quantity, ContentID from tblDECK_CARD where DeckID = @DeckID)
 return @RET 
 END 
GO 

create OR alter proc DRAFTPLACEHOLDERlookatdeck 
 @DeckID int 
 as BEGIN 
 declare @ListedDeck WrangleDeck, @BasicLands BasicLandOutput, @mainboard int, @sideboard int, @IsSingleton int, @oneset int, @uniquecards int, @FormatID int, @generals int 
 set @BasicLands = dbo.getme_basiclands()
 set @ListedDeck = dbo.fetch_DeckByID(@DeckID)
 select CardID, D.CardFaceID, Quantity, ContentName
  into #Deck from @ListedDeck D 
  join tblCARD_FACE CF on D.CardFaceID = CF.CardFaceID
  LEFT join defCONTENT C on D.ContentID = C.ContentID
 set @uniquecards = (select Count(distinct CardID) from #Deck where CardFaceID not in (select CardFaceID from @BasicLands))
 set @oneset = (select Top 1 Floor(Count(distinct CardID)/@uniquecards) from tblCARD_FACE_SET CFS
  join #Deck D on D.CardFaceID = CFS.CardFaceID
  group by SetID) --if greatest number of distinct cards in a set that are in this deck divided by total distinct cards is 1 then it's a one-set deck 
 select D.CardFaceID, E.BeginDate, E.EndDate, S.CardStatusName, E.FormatID into #DeckOutliers from #Deck D 
  join tblCARD_FACE_SET CFS on D.CardFaceID = CFS.CardFaceID 
  join tblCARD_NOT_SET_STATUS E on CFS.CardFaceSetID = E.CardFaceSetID 
  join defCARD_STATUS S on E.CardStatusID = S.CardStatusID 
  where CardStatusName != 'not_legal'
 select S.SetID, S.SetReleaseDate, F.FormatID into #DeckSets from #Deck D 
  join tblCARD_FACE_SET CFS on D.CardFaceID = CFS.CardFaceID
  join tblSET S on CFS.SetID = S.SetID 
  join defSET_TYPE T on S.SetTypeID = T.SetTypeID 
  join refSET_TYPE_STATUS R on T.SetTypeID = R.SetTypeID 
  join defSET_STATUS ST on R.SetStatusID = ST.SetStatusID
  where SetStatusName = 'legal'
   and D.CardFaceID not in (select CardFaceID from @BasicLands)
  group by S.SetID, S.SetReleaseDate, F.FormatID
 select F.FormatID, FT.FormatTypeName, FN.FormatNameMachineReadable, FE.BeginDate, FE.EndDate, FM.FormatMediumName into #FormatContenders from refFORMAT F 
  join defFORMAT_TYPE FT on F.FormatTypeID = FT.FormatTypeID 
  join defFORMAT_MEDIUM FM on F.FormatMediumID = FM.FormatMediumID 
  join defFORMAT_NAME FN on F.FormatNameID = FN.FormatNameID 
  LEFT join refFORMAT_EPOCH FE on F.FormatID = FE.FormatID
  where F.FormatID in (select FormatID from #DeckSets) 
   or F.FormatID in (select FormatID from #DeckOutliers 
    where CardStatusName = 'legal')
 set @IsSingleton = (select Max(Quantity) from #Deck
  where CardFaceID not in (select CardFaceID from @BasicLands))
 set @mainboard = (select Sum(Quantity) from #Deck 
  where ContentName IS NULL
  group by CardID)
 set @sideboard = (select Sum(Quantity) from #Deck
  where ContentName = 'SIDE'
  group by CardID)
 if ((@mainboard < 60) or (@sideboard > 15)) and @oneset = 1
  BEGIN 
   set @FormatID = (select FormatID from refFORMAT F
    join defFORMAT_NAME N on F.FormatNameID = N.FormatNameID
    where FormatNameMachineReadable = 'limited') 
  END
 set @generals = (select Count(CardID) from #Deck where ContentName = 'CMDR')
 if @generals > 0 and @IsSingleton = 1
  BEGIN 
   --do commander-format things
   if (@generals + @mainboard) = 60
    set @FormatID = (select F.FormatID from refFORMAT F
     join defFORMAT_NAME N on F.FormatNameID = N.FormatNameID 
     where FormatNameMachineReadable = 'brawl')
   ELSE if (@generals + @mainboard) = 100 
    BEGIN 
     if (select Count(CardID) from #Deck D 
      join tblCARD_FACE_SET CFS on D.CardFaceID = CFS.CardFaceID
      join defPLATFORM P on CFS.PlatformID = P.PlatformID
      where PlatformName = 'paper'
      group by CardID) < 100
      set @FormatID = (select FormatID from refFORMAT F
       join defFORMAT_NAME N on F.FormatNameID = N.FormatNameID 
       where FormatNameMachineReadable = 'historicbrawl')


    END 
  END 
 
 END 
GO 