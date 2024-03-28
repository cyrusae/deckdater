use Info_430_deckdater
GO 

--update Hapax cards:
create OR alter proc UPD8_HapaxCards 
 as BEGIN 
 set NOCOUNT ON 
 select C.CardID, S.SetReleaseDate, Dense_Rank() over (partition by C.CardID order by S.SetReleaseDate asc) as OrderPrints into #AboutPrints
  from tblCARD C 
  join tblCARD_FACE CF on C.CardID = CF.CardID 
  join tblCARD_FACE_SET CFS on CF.CardFaceID = CFS.CardFaceID 
  join tblSET S on CFS.SetID = S.SetID ;

 with Firsts (CardID, BeginDate) as (select CardID, SetReleaseDate as BeginDate from #AboutPrints where OrderPrints = 1),
 Seconds (CardID, EndDate) as (select CardID, SetReleaseDate as EndDate from #AboutPrints where OrderPrints = 2)

 insert into tblCARD_HAPAX (CardID, BeginDate, EndDate)
 select A.CardID, A.BeginDate, B.EndDate 
  from Firsts A 
  LEFT join Seconds B on A.CardID = B.CardID 
  where A.CardID not in (select CardID from tblCARD_HAPAX);
 END 
GO 

create OR alter function dbo.CHECK_HapaxDurationToday(@CardID varchar(36))
 returns INT 
 as BEGIN 
 declare @BeginDate date, @EndDate date, @RET int 
 select @BeginDate = BeginDate,
  @EndDate = EndDate from tblCARD_HAPAX 
  where CardID = @CardID 
 
 if @EndDate is NULL 
  set @EndDate = Cast(GetDate() as date)

 set @RET = DateDiff(day, @BeginDate, @EndDate)
 return @RET 
 END 
GO 

--temp column only due to the GetDate(). the rest of these wouldn't persisted either, but especially this one 
alter table tblCARD_HAPAX 
 Add DaysAsHapaxCardToday as dbo.CHECK_HapaxDurationToday(CardID)
GO 

--alternately, 
alter table tblCARD_HAPAX 
 Add TotalHapaxDays int NULL 
GO 

create OR alter proc UPD8_HapaxCardsDuration 
 as BEGIN 
 set NOCOUNT ON 
 update tblCARD_HAPAX 
  set TotalHapaxDays = DateDiff(day, BeginDate, EndDate)
  where EndDate is NOT NULL 
   and TotalHapaxDays is NULL 
 END 
GO 

create OR alter function dbo.COUNT_SetsInBlock(@PK int)
 returns INT 
 with SCHEMABINDING 
 as BEGIN 
 declare @RET int 
 set @RET = (select Count(SetID) from dbo.tblSET 
   where BlockID = @PK)
 return @RET 
 END 
GO 

alter table tblBLOCK 
 Add SetsContained as dbo.COUNT_SetsInBlock(BlockID)  
GO 

create OR alter function dbo.COUNT_MainDeckCards(@PK int)
 returns INT 
 with SCHEMABINDING 
 as BEGIN 
 declare @RET int 
 set @RET = (select Sum(Quantity) from dbo.tblDECK_CARD 
  where DeckID = @PK)
 return @RET 
 END 
GO 

alter table tblDECK 
 Add MainDeckSize as dbo.COUNT_MainDeckCards(DeckID)  
GO 

create OR alter function dbo.COUNT_NewCardsInSet (@PK varchar(36)) 
 returns INT 
 with SCHEMABINDING 
 as BEGIN 
 declare @RET int 
 set @RET = (select Count(CardFaceSetID) from dbo.tblCARD_FACE_SET 
  where SetID = @PK 
   and IsReprint is NULL)
 return @RET 
 END 
GO 

alter table tblSET 
 Add NewCards as dbo.COUNT_NewCardsInSet(SetID)  
GO 

alter table tblDECK 
 Add LastKnownDate date NULL 
GO 

create OR alter function determine_deckdate(@DeckID int)
 returns date 
 as BEGIN 
 declare @RET date ;
 with Deck (CardFaceID, SetCode, SetName, SetReleaseDate, PrintOrder) as (select D.CardFaceID, S.SetCode, S.SetName, S.SetReleaseDate, Dense_Rank() over (partition by D.CardFaceID order by S.SetReleaseDate asc) as PrintOrder 
  from tblDECK_CARD D 
  join tblCARD_FACE_SET CFS on D.CardFaceID = CFS.CardFaceID 
  join tblSET S on CFS.SetID = S.SetID
  where D.DeckID = @DeckID)

 select @RET = Max(SetReleaseDate) 
  from Deck where PrintOrder = 1 ;
 return @RET 
 END 
GO 

create OR alter function determine_deckdate_forcezones(@DeckID int)
 returns date 
 as BEGIN 
 declare @RET date ;
 with Deck (CardFaceID, SetCode, SetName, SetReleaseDate, PrintOrder) as (select D.CardFaceID, S.SetCode, S.SetName, S.SetReleaseDate, Dense_Rank() over (partition by D.CardFaceID order by S.SetReleaseDate asc) as PrintOrder 
  from (select distinct X.CardFaceID 
   from (select CardFaceID from tblDECK_CARD
     where DeckID = @DeckID 
    UNION ALL 
    select CardFaceID from tblDECK_CARD_ZONE
     where DeckID = @DeckID) X ) D 
  join tblCARD_FACE_SET CFS on D.CardFaceID = CFS.CardFaceID 
  join tblSET S on CFS.SetID = S.SetID)

 select @RET = Max(SetReleaseDate) 
  from Deck where PrintOrder = 1 ;
 return @RET 
 END 
GO 

create OR alter proc i_UPD8_KnownDeckDate 
 @DeckID int 
 as BEGIN 
 set NOCOUNT ON 
 declare @lastupdate date
 /* Automatic update will only work off maindeck; forcing update from other zones is user-initiated. */
 set @lastupdate = dbo.determine_deckdate(@DeckID)
 update tblDECK 
  set LastKnownDate = @lastupdate
  where DeckID = @DeckID
   and LastKnownDate < @lastupdate
 END 
GO 

create OR alter proc i_FORCE_DeckDate 
 @DeckID int 
 as BEGIN 
 set NOCOUNT ON 
 declare @forcedate date 
 set @forcedate = dbo.determine_deckdate_forcezones(@DeckID)
 update tblDECK 
  set LastKnownDate = @forcedate 
  where DeckID = @DeckID 
 END 
GO 

create OR alter proc u_DeckDate_WithZones 
 @UserName varchar(100),
 @DeckName varchar(350)
 as BEGIN 
 declare @IsUserID int, @IsDeckID int 
 set @IsUserID = dbo.fetch_UserIDbyUserName(@UserName)
 if @IsUserID is NULL 
  BEGIN 
   print 'User not found!';
   throw 98451, 'User ID not found. Transaction terminated. Check your parameters', 13;
  END 
 set @IsDeckID = dbo.fetch_DeckIDbyName(@UserName, @DeckName) --this is doing duplicate labor from above in order to have a distinct error thrown on wrong user 
 if @IsDeckID is NULL 
  BEGIN 
   print 'Deck not found. Check spelling!';
   throw 98831, 'No matching DeckID found. Check deck name and ownership. Transaction terminated.', 13;
  END 
 exec dbo.i_FORCE_DeckDate 
  @DeckID = @IsDeckID 
 END 
GO 
