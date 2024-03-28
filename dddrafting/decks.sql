create table tblDECK (
 DeckID int Identity(1,1) primary key NOT NULL,
 UserID int FOREIGN KEY references tblUSER ON DELETE CASCADE,
 DeckName varchar(300) NOT NULL,
 DateCreated datetime DEFAULT GetDate(),
 DateUpdated datetime NULL,
 IsPrivate char(1) SPARSE NULL,
 Constraint UsersMakeDecksOnce UNIQUE (UserID, DeckName))

create table tblDECK_CARD (
 DeckID int FOREIGN KEY references tblDECK_CARD ON DELETE CASCADE,
 CardFaceID int FOREIGN KEY references tblCARD_FACE NOT NULL,
 Constraint DecksContainCards PRIMARY KEY (DeckID, CardFaceID))

create table tblDECK_GENERAL (
 DeckID int FOREIGN KEY references tblDECK_CARD ON DELETE CASCADE,
 CardFaceID int FOREIGN KEY references tblDECK_CARD NOT NULL,
 FriendlyOnly char(1) SPARSE NULL, --e.g. listing Olivia and Edgar as "partnered" commanders despite it not being legal for them to be, so that the system can still process color ID et al appropriately; using a legend that isn't legal because it's Grand Calculotron or a non-"this card can be your commander" planeswalker; etc.
 Constraint CommandersArePartOfYourDeck PRIMARY KEY (DeckID, CardID))
GO 
/* don't need this.
create table tblDECK_BRAWL_GENERAL (
 DeckID int FOREIGN KEY references tblDECK_CARD ON DELETE CASCADE,
 CardFaceID int FOREIGN KEY references tblDECK_CARD NOT NULL,
 Constraint CommandersArePartOfYourBrawlDeck PRIMARY KEY (DeckID, CardFaceID))
GO */

create type DeckCardsUnlisted as table (
 PK int Identity(1,1) primary key NOT NULL,
 DeckID int,
 CardFaceID int UNIQUE,
 Quantity int)
GO 

create OR alter proc u_CHANGE_DeckCards 
 @ToDeckID int,
 @Decklist varchar(8000)
 as BEGIN 
 declare @NovelDecklist DeckCardsUnlisted, /* @OldVersion DeckCardsUnlisted, */ @AddCards DeckCardsUnlisted, /*@RemoveCards DeckCardsUnlisted, @ChangeCards DeckCardsUnlisted, @toAdd int, @toChange int, @counter int, @ActOnCardFace int, @NewAmount int, */ @now datetime

 insert into @NovelDecklist (CardFaceID, Quantity, DeckID)
  select distinct X.CFI, Count(*), @ToDeckID
   from (select Cast(value as int) as CFI from STRING_SPLIT(@Decklist, ',')) X 
   group by X.CFI

/*select distinct X.Thing, Count(*) 
 from (select value as Thing from STRING_SPLIT('A,A,A,B,B,A,C', ',')) X
 group by X.Thing
 insert into @OldVersion 
  select @ToDeckID, CardFaceID, Quantity 
  from tblDECK_CARD where DeckID = @ToDeckID 
 */
 begin tran ChangeDeck 
 insert into @AddCards (DeckID, CardFaceID, Quantity)
  select @ToDeckID, N.CardFaceID, N.Quantity 
  from @NovelDecklist N 
   where N.CardFaceID not in (select CardFaceID from tblDECK_CARD where DeckID = @ToDeckID)
   /*  let's see if I can do better than these loops.
 set @toAdd = (select Count(PK) from @AddCards)
 insert into @ChangeCards (DeckID, CardFaceID, Quantity)
  select @ToDeckID, N.CardFaceID, N.Quantity 
  from @NovelDecklist N 
  join @OldVersion O on N.CardFaceID = O.CardFaceID 
  where N.Quantity != O.Quantity 
 set @toChange = (select Count(PK) from @ChangeCards)

 insert into @RemoveCards (DeckID, CardFaceID, Quantity)
  select @ToDeckID, O.CardFaceID, O.Quantity 
  from @OldVersion O 
  where O.CardFaceID not in (select CardFaceID from @NovelDecklist)

 if (select Count(PK) from @RemoveCards) > 0 
  delete from tblDECK_CARD
  where DeckID = @ToDeckID 
   and CardFaceID in (select CardFaceID from @RemoveCards)
 
 if (select Count(PK) from @ChangeCards) > 0 
  BEGIN */
  begin tran UpdateContents
  update tblDECK_CARD 
   set DC.Quantity = CC.Quantity 
   from tblDECK_CARD DC 
    join @NovelDecklist CC on DC.CardFaceID = CC.CardFaceID 
    where DC.DeckID = CC.DeckID
     --and DC.Quantity != CC.Quantity --does this do what I want it to do. is there any meaningful improvemnet from it really
      --what's the difference in practice between this and using a join on two columns btw 

/* while @toChange > 0 
  BEGIN 
   set @counter = (select Min(PK) from @ChangeCards)
   select @ActOnCardFace = CardFaceID, 
    @NewAmount = Quantity 
    from @ChangeCards where PK = @counter 
   update tblDECK_CARD 
    set Quantity = @NewAmount 
    where DeckID = @ToDeckID 
     and CardFaceID = @ActOnCardFace 
   delete from @ChangeCards where PK = @counter 
   set @toChange = @toChange - 1
  END */
   begin tran AddNewCards 
   if (select Count(PK) from @AddCards) > 0 
    insert into tblDECK_CARD (DeckID, CardFaceID, Quantity)
     select @ToDeckID, CardFaceID, Quantity from @AddCards 
   commit tran AddNewCards 

   set @now = GetDate()
   update tblDECK 
    set DateUpdated = @now 
    where DeckID = @ToDeckID 
  commit tran UpdateContents 
 commit tran ChangeDeck --is this how I'm going to want things nested? Still working on getting that.
 END 
GO 

create OR alter proc u_CREATE_Deck 
 @ByUserID int,
 @WithDeckName varchar(300) NULL,
 @WithContents varchar(8000) NULL,
 @AsPrivateDeck char(1) NULL
 as BEGIN 

 if @WithDeckName is NULL 
  set @WithDeckName = dbo.fillin_defaultdeckname(@ByUserID)
 
 begin tran MakeDeck 
 insert into tblDECK(UserID, IsPrivate) VALUES(@ByUserID, @AsPrivateDeck) 
 if @WithDeckContents is NOT NULL 
  BEGIN 
   begin tran FillDeck
     declare @NewDeckID int 
     set @NewDeckID = scope_identity()
     exec dbo.u_CHANGE_DeckCards 
      @ToDeckID = @NewDeckID,
      @Decklist = @WithContents 
   commit tran FillDeck 
  END --does this go here or do the transaction and begin/end parts go the other way around?
 commit tran MakeDeck 
 END 
GO 

create OR alter function congruity_DeckCardFaceCount()
 returns int 
 as BEGIN 
  declare @RET int 
  set @RET = (select Max(Count(distinct Quantity)) --is this the right layering...
   from tblDECK_CARD DC 
    join tblCARD_FACE CF on DC.CardFaceID = CF.CardFaceID 
    group by CF.CardID)
  return @RET 
 END 
GO 

--implement iff sure this does what I want it to 
alter table tblDECK_CARD 
 add CONSTRAINT NoCardFaceCountMismatches 
  CHECK (dbo.congruity_DeckCardFaceCount() = 1)
GO 