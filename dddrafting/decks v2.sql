--note: come back to this and break out insertions into tblDECK_CARD and tblDECK_FORMAT so they're procedures that can be used by updates to either too.

create table defCONTENT (
 ContentID int Identity(1,1) primary key NOT NULL,
 ContentName char(4) unique NOT NULL)
GO 

create table tblDECK_CARD_FACE (
 DeckID int FOREIGN KEY references tblDECK NOT NULL,
 CardFaceID int FOREIGN KEY references tblCARD_FACE NOT NULL,
 Quantity int DEFAULT 1,
 ContentID int FOREIGN KEY references defCONTENT NULL,
 Constraint DecksContainCards PRIMARY KEY (DeckID))
GO 

create type Unlisted as table (
 PK int Identity(1,1) primary key NOT NULL,
 Item varchar(500))
  with (MEMORY_OPTIMIZED = ON);

create type IngestDecklist as table (
 PK int Identity(1,1) primary key NOT NULL,
 CardFaceName varchar(200) NOT NULL,
 Quantity int DEFAULT 1,
 ContentName char(4) NULL)
  with (MEMORY_OPTIMIZED = ON);

create type WrangleDecklist as table (
 PK int Identity(1,1) primary key NOT NULL,
 CardFaceID int NOT NULL,
 Quantity int DEFAULT 1,
 ContentID char(4) NULL)
  with (MEMORY_OPTIMIZED = ON);
GO 

create OR alter function fetch_FormatIDbyMachineName (@FormatName varchar(25))
 returns int 
 as BEGIN 
 declare @RET int 
 set @RET = (select F.FormatID from refFORMAT F 
  join defFORMAT_NAME FN on F.FormatNameID = FN.FormatNameID 
  where FormatNameMachineReadable = @FormatName)
 return @RET 
 END 
GO 

create OR alter function ingest_DecklistFromString (
 @ingest varchar(8000))
 returns IngestDecklist 
 as BEGIN 
 declare @RET IngestDecklist, @ticktock int, @ticker int, @Unstring Unlisted 
 insert into @Unstring (Item)
  select value as Item, ordinal as ticker from STRING_SPLIT(@ingest, ',')
 set @ticktock = (select Count(PK) from @Unstring)/3 
 while @ticktock > 0 
  BEGIN 
   declare @CardFaceName varchar(200), @Quantity int, @ContentName char(4)
   set @ticker = (select Min(PK) from @Unstring)
   set @CardFaceName = (select Trim(Item) from @Unstring where PK = @ticker)
   delete from @Unstring where PK = @ticker 
   set @ticker = (select Min(PK) from @Unstring)
   set @Quantity = (select Cast(Trim(Item) as int) from @Unstring where PK = @ticker)
   delete from @Unstring where PK = @ticker 
   set @ticker = (select Min(PK) from @Unstring)
   set @ContentName = (select Cast(Trim(Item) as char(4)) from @Unstring where PK = @ticker)
   if @ContentName = 'ISNA'
    set @ContentName = NULL 
   delete from @Unstring where PK = @ticker 
   insert into @RET (CardFaceName, Quantity, ContentName)
    VALUES (@CardFaceName, @Quantity, @ContentName) 
   set @ticktock = @ticktock - 1
  END 
 return @RET 
 END 
GO 

create OR alter function produce_DecklistFromString (@ingest varchar(8000)) 
 returns WrangleDecklist
 as BEGIN 
 declare @RET WrangleDecklist, @work IngestDecklist 
 set @work = dbo.ingest_DecklistFromString(@ingest)
 insert into @RET (CardFaceID, Quantity, ContentID)
  select CF.CardFaceID, W.Quantity, DC.ContentID 
   from @work W 
   join tblCARD_FACE CF on W.CardFaceName = CF.CardFaceName 
   LEFT join defCONTENT DC on W.ContentName = DC.ContentName
 return @RET 
 END 
GO 

create OR alter function makeupaguy_deckname(@UserID int, @DeckName varchar(280)) 
 returns varchar(350)
 as BEGIN 
 declare @RET varchar(350), @repeats int 
 if @DeckName IS NULL 
  set @DeckName = 'New Deck'
 set @repeats = (select Count(DeckID) from tblDECK where @DeckName = @DeckName and UserID = @UserID)
 if @repeats > 0 
  BEGIN 
   declare @GenericizedDeckName varchar(350)
   set @GenericizedDeckName = @DeckName + ' %'
   set @repeats = @repeats + (select Count(DeckID) from tblDECK where UserID = @UserID and DeckName like @GenericizedDeckName)
   set @RET = @DeckName + @repeats
  END 
  ELSE set @RET = @DeckName
 return @RET 
 END 
GO 

create OR alter proc u_CREATE_NewDeck 
 @UserID int,
 @WithDeckName varchar(280),
 @InFormat varchar(25) NULL,
 @FromDecklist varchar(8000) NULL
 as BEGIN 
 declare @RealDeckName varchar(350)
 set @RealDeckName = dbo.makeupaguy_deckname(@UserID, @WithDeckName)

 begin tran MakeDeck 
  insert into tblDECK (UserID, DeckName)
   VALUES (@UserID, @RealDeckName)

  if (@FromDecklist is NOT NULL) or (@InFormat is NOT NULL)
   BEGIN 
    declare @DeckID int 
    set @DeckID = scope_identity()
    if @FromDecklist is NOT NULL 
     BEGIN 
     declare @Decklist WrangleDecklist
     set @Decklist = dbo.produce_DecklistFromString(@FromDecklist)
     if (@Decklist is NOT NULL) and ((select Count(PK) from @Decklist) > 0) --no sneaking in malformed deck lists!!
      BEGIN --reformat this to use the update proc later, this is a proof of concept 
       begin tran AddCardsOfNewDeck 
       insert into tblDECK_CARD (DeckID, CardFaceID, Quantity, ContentID)
        select @DeckID, CardFaceID, Quantity, ContentID from @Decklist 
       commit tran AddCardsOfNewDeck
      END 
     END 
     if @InFormat is NOT NULL     --add guessing format and change this accordingly once that's implemented (actually, do that and break out result into proc to add or update format? we'll see)
     BEGIN 
      declare @FormatID int 
      set @FormatID = dbo.fetch_FormatIDbyMachineName(@InFormat)
      if @FormatID is NOT NULL --sucks to be you if you somehow manually entered a malformed format name lmao 
       BEGIN 
        begin tran AddFormatOfDeck 
        insert into tblDECK_FORMAT(DeckID, FormatID)
         VALUES (@DeckID, @FormatID)
        commit AddFormatOfDeck 
       END 
     END 
   END 
 commit MakeDeck
 END 
GO 