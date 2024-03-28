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

/* when confident:
create OR alter trigger t_onDECK_UpdateDeckDating on tblDECK 
 after UPDATE 
 as BEGIN 
 if @@ROWCOUNT < 1 RETURN ; 
 set NOCOUNT ON 
 declare @insDeckID int, @counter int 
 select DeckID into #affectdecks from inserted 
 set @counter = (select Count(DeckID) from #affectdecks)
 while @counter > 0 
  set @insDeckID = (select Top 1 DeckID from #affectdecks) 
  exec dbo.i_UPD8_KnownDeckDate 
   @DeckID = @insDeckID 
  delete from #affectdecks where DeckID = @insDeckID
  set @counter = @counter - 1
 END 
GO 

create OR alter trigger t_onDCARD_UpdateDeckDating on tblDECK_CARD 
 after INSERT 
 as BEGIN 
 if @@ROWCOUNT < 1 RETURN ;
 set NOCOUNT ON 
 declare @insDeckID int, @counter int 
 select distinct DeckID into #affectdecks from inserted 
 set @counter = (select Count(DeckID) from #affectdecks)
 while @counter > 0 
  set @insDeckID = (select Top 1 DeckID from #affectdecks) 
  exec dbo.i_UPD8_KnownDeckDate 
   @DeckID = @insDeckID 
  delete from #affectdecks where DeckID = @insDeckID
  set @counter = @counter - 1
 END 
GO 
*/

GO 

--hapax does appear to be slightly slower (~00.01s)! Go figure 
create OR alter function determine_hapaxdate(@DeckID int)
 returns date 
 as BEGIN 
 declare @RET date ;
 
 select @RET = MAX(BeginDate) from tblCARD_HAPAX CH 
  join tblCARD_FACE CF on CH.CardID = CF.CardID 
  join tblDECK_CARD DC on CF.CardFaceID = DC.CardFaceID 
  where DeckID = @DeckID 

 return @RET 
 END 
GO 
