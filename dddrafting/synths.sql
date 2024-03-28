create OR alter function getme_randomuser()
 returns INT 
 as BEGIN 
  declare @RET int, @among int, @find int 
  set @among = (select Count(UserID) from tblUSER)
  set @find = Floor(Rand() * @among)
  set @RET = (select UserID from tblUSER 
   order by UserID
   offset @find rows
   fetch next 1 rows only)
  return @RET 
 END 
GO 

create OR alter function getme_randomdeck()
 returns INT 
 as BEGIN 
  declare @RET int, @among int, @find int 
  set @among = (select Count(DeckID) from tblDECK)
  set @find = Floor(Rand() * @among)
  set @RET = (select DeckID from tblDECK
   order by DeckID
   offset @find rows
   fetch next 1 rows only)
  return @RET 
 END 
GO 

create OR alter function getme_randomformatname()
 returns VARCHAR(25)
 as BEGIN 
 declare @RET varchar(25), @among int, @find int 
  set @among = (select Count(FormatNameID) from defFORMAT_NAME)
  set @find = Floor(Rand() * @among)
  set @RET = (select FormatNameMachineReadable from defFORMAT_NAME 
   order by FormatNameID
   offset @find rows
   fetch next 1 rows only)
 return @RET
 END 
GO 

create OR alter function getme_randomcardID()
 returns VARCHAR(36)
 as BEGIN 
  declare @RET varchar(36), @among int, @find int 
  set @among = (select Count(CardID) from tblCARD)
  set @find = Floor(Rand() * @among)
  set @RET = (select CardID from tblCARD
   order by CardID
   offset @find rows
   fetch next 1 rows only)
  return @RET 
 END 
GO 

create OR alter function fillin_defaultdeckname(@ForUserID int) 
 returns VARCHAR(200)
 as BEGIN 
 declare @RET varchar(200), @prev int 
 set @prev = (select Count(DeckID) from tblDECK where UserID = @ForUserID) + 1
 set @RET = 'New Deck (' + @prev + ')'
 return @RET 
 END 
GO

create type DeckInput as table (
 PK int Identity(1,1) primary key NOT NULL,
 CardID varchar(36),
 Quantity int DEFAULT 1,
 General char(1) SPARSE NULL)
GO 

create type CardOutput as table (
 PK int Identity(1,1) primary key NOT NULL,
 CardID varchar(36),
 CardFaceID int,
 LayoutFaceID int NULL)
GO 

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

--random synths that will not support testing validity checks but WILL support being very funny 
create OR alter proc SPAGHETTI_decking 
 as BEGIN 
 declare @PickUser int, @SomeCards varchar(8000)
 set @PickUser = dbo.getme_randomuser()
 set @SomeCards = (select STRING_AGG(CardFaceID, ',')  
  from tblCARD_FACE
   where CardID in (select Top(60) CardID
    from tblCARD))
 exec dbo.u_CREATE_Deck 
  @ByUserID = @PickUser,
--  @WithDeckName = NULL, --if it's nullable anyway do I still need to hand-null this? I am not 100% on whether I can trust my dang defaults.
  @WithContents = @SomeCards
 END 
GO 

create OR alter proc REPEAT_spaghetti_decking 
 @iterate int 
 as BEGIN 
 while @iterate > 0 
  BEGIN 
   exec dbo.SPAGHETTI_decking 
   set @iterate = @iterate - 1
  END 
 END
GO 

create OR alter proc SPAGHETTI_edit_single
 as BEGIN 
 declare @PickDeck int, @PickCard varchar(36), @SendDeck varchar(200)
 set @PickDeck = dbo.getme_randomdeck()
 set @PickCard = dbo.getme_randomcardID()
 select CardFaceID into #ThisCard 
  from tblCARD_FACE 
  where CardID = @PickCard
 set @SendDeck = (select STRING_AGG(CardFaceID, ',') 
  from #ThisCard)
 exec dbo.u_CHANGE_DeckCards
  @ToDeckID = @PickDeck,
  @Decklist = @SendDeck
 END 
GO 

create OR alter proc SPAGHETTI_edit_several
 as BEGIN 
 declare @PickDeck int, @PickCard varchar(36), @Cards int, @Quant int, @Deckable CardOutput, @SendDeck varchar(2000)
 set @Cards = Floor(Rand() * 13) + 1 
 set @PickDeck = dbo.getme_randomdeck()

 while @Cards > 0 
  BEGIN 
   set @PickCard = dbo.getme_randomcardID()
   set @Quant = Floor(Rand() * 4) + 1 
   select CardFaceID into #ThisCard from tblCARD_FACE where CardID = @PickCard
   while @Quant > 0 
    BEGIN 
     insert into @Deckable (CardID, CardFaceID)
      select @PickCard, CardFaceID from #ThisCard
     set @Quant = @Quant - 1
    END 
   delete from #ThisCard 
   set @Cards = @Cards - 1
  END 

 set @SendDeck = (select STRING_AGG(CardFaceID, ',') 
  from @Deckable)
 exec dbo.u_CHANGE_DeckCards
  @ToDeckID = @PickDeck,
  @Decklist = @SendDeck 
 END 
GO 

create OR alter proc REPEAT_spaghetti_editone 
 @iterate int 
 as BEGIN 
 while @iterate > 0 
  BEGIN 
   exec dbo.SPAGHETTI_edit_single
   set @iterate = @iterate - 1
  END 
 END 
GO 

create OR alter proc REPEAT_spaghetti_editmany 
 @iterate int 
 as BEGIN 
 while @iterate > 0
  BEGIN 
   exec dbo.SPAGHETTI_edit_several 
   set @iterate = @iterate - 1
  END 
 END 
GO 

create OR alter proc REPEAT_spaghetti_FREEFORALL 
 @iterations int,
 @iterate int
 as BEGIN 
 declare @option int 
 while @iterations > 0 
  set @option = Floor(Rand() * 100)
  if @option = 69 
   BEGIN 
    exec dbo.REPEAT_spaghetti_decking @iterate 
    exec dbo.REPEAT_spaghetti_editmany @iterate 
    exec dbo.REPEAT_spaghetti_editone @iterate 
   END 
  else if @option = 13
   BEGIN 
    exec dbo.REPEAT_spaghetti_editmany @iterate 
    exec dbo.REPEAT_spaghetti_editone @iterate 
   END 
  else if @option = 42 
   BEGIN 
    exec dbo.REPEAT_spaghetti_decking @iterate 
    exec dbo.REPEAT_spaghetti_editone @iterate 
   END 
  else if @option > 69 
   exec dbo.REPEAT_spaghetti_editone @iterate 
  else if @option < 42 
   exec dbo.REPEAT_spaghetti_editmany @iterate 
  else exec dbo.REPEAT_spaghetti_decking @iterate
  set @iterations = @iterations - 1  
 END 
GO 