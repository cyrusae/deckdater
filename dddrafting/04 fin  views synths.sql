use Info_430_deckdater 
GO 

create OR alter view SEE_HumanReadableSets as 
 select S.SetID, S.SetCode, S.SetName, S.SetReleaseDate, ST.SetTypeName, S.SetCollectorCount, S.SetScryfallAPI, S.SetScryfallURI, B.BlockCode, S.SetIsDigital from tblSET S 
 join defSET_TYPE ST on S.SetTypeID = ST.SetTypeID 
 join tblBLOCK B on S.BlockID = B.BlockID 
GO 

create OR alter view SEE_HumanReadableCards as 
 select CF.CardID, CF.CardFaceName, CF.CardFaceSearchName, CFSP.CardSetPlatformScryfallAPI as CardSetScryfallAPI, CFSP.CardSetPlatformScryfallURI as CardSetScryfallURI, L.LayoutName, F.FaceName, Subtypes, Types, Supertypes, CFS.SetID, R.RarityName, P.PlatformName, CFS.IsReprint 
  from tblCARD_FACE_SET CFS 
   join tblCARD_FACE CF on CFS.CardFaceID = CF.CardFaceID 
   join tblCARD_FACE_SET_PLATFORM CFSP on CFS.CardFaceSetID = CFSP.CardFaceSetID 
   join defPLATFORM P on CFSP.PlatformID = P.PlatformID 
   join defRARITY R on CFS.RarityID = R.RarityID 
   join refLAYOUT_FACE LF on CF.LayoutFaceID = LF.LayoutFaceID 
   join defLAYOUT L on LF.LayoutID = L.LayoutID 
   join defFACE F on LF.FaceID = F.FaceID
   LEFT join 
    (select CFS.CardFaceID, STRING_AGG(S.SupertypeName, ' ') as Supertypes 
     from tblCARD_FACE_SUPERTYPE CFS 
     join defSUPERTYPE S on CFS.SupertypeID = S.SupertypeID
     group by CFS.CardFaceID) 
    Super on CF.CardFaceID = Super.CardFaceID 
  LEFT join 
   (select CFT.CardFaceID, STRING_AGG(T.TypeName, ' ') as Types 
    from tblCARD_FACE_TYPE CFT
    join defTYPE T on CFT.TypeID = T.TypeID
    group by CFT.CardFaceID) 
   Types on CF.CardFaceID = Types.CardFaceID 
  LEFT join 
   (select CFB.CardFaceID, STRING_AGG(B.SubtypeName, ' ') as Subtypes 
    from tblCARD_FACE_SUBTYPE CFB 
    join defSUBTYPE B on CFB.SubtypeID = B.SubtypeID 
    group by CFB.CardFaceID) 
   Sub on CF.CardFaceID = Sub.CardFaceID 
GO 

--some maintenance/QOL coding: 
create OR alter proc ENV_VAR_UPD8_MASS 
 @UseAll varchar(5) NULL 
 as BEGIN 
 set NOCOUNT ON 
 if @UseAll is NOT NULL --are you sure you want to update the ones that should be static...? okay...
  BEGIN 
   exec dbo.ENV_VAR_UPD8 N'UN_Wordle'
   exec dbo.ENV_VAR_UPD8 N'UN_StopWords'
   exec dbo.ENV_VAR_UPD8 N'refFORMAT'
  END 
 exec dbo.ENV_VAR_UPD8 N'tblCARD'
 exec dbo.ENV_VAR_UPD8 N'tblSET'
 exec dbo.ENV_VAR_UPD8 N'tblCARD_FACE'
 exec dbo.ENV_VAR_UPD8 N'tblCARD_FACE_SET'
 exec dbo.ENV_VAR_UPD8 N'tblUSER'
 exec dbo.ENV_VAR_UPD8 N'tblDECK'
 END 
GO 

create OR alter proc u_ADD_NewDeck 
 @ForUserName varchar(100),
 @FormatMachineName varchar(25) NULL,
 @DeckNameString varchar(280) NULL,
 @WithMAIN varchar(8000),
 @WithCMDR varchar(8000) NULL,
 @WithSIDE varchar(8000) NULL, 
 @WithMAYB varchar(8000) NULL,
 @WithWISH varchar(8000) NULL,
 @IsPrivate char(1) NULL
 as BEGIN 
 set NOCOUNT ON 
 declare @CommandZoneID int, @SideZoneID int, @MaybeZoneID int, @WishZoneID int, @DeckName varchar(350), @DeckID int, @side Unlisted, @maybe Unlisted, @cmdr Unlisted, @wish Unlisted, @main Unlisted, @UserID int, @InFormatID int 
 set @InFormatID = dbo.fetch_FormatIDbyMachineName(@FormatMachineName)
 set @UserID = dbo.fetch_UserIDbyUsername(@ForUserName)
 if @UserID is NULL 
  BEGIN 
   print 'User ID not found. Check spelling and uniqueness';
   throw 93846, 'UserID lookup requires unique username and deck name. Check inputs', 14;
  END 
 insert into @main (Item)
  select value as Item from STRING_SPLIT(@WithMAIN, '|')
 select U.Item as CardFace, Count(U.PK) as Quantity 
  into #deck from @main U group by U.Item
 set @DeckName = dbo.makeupaguy_deckname(@UserID, @DeckNameString)
 set @CommandZoneID = (select ZoneID from defZONE where ZoneName = 'CMDR')
 set @SideZoneID = (select ZoneID from defZONE where ZoneName = 'SIDE')
 set @MaybeZoneID = (select ZoneID from defZONE where ZoneName = 'MAYB')
 set @WishZoneID = (select ZoneID from defZONE where ZoneName = 'WISH')
 begin tran NewDeck 
  insert into tblDECK (UserID, DeckName, IsPrivate)
   VALUES (@UserID, @DeckName, @IsPrivate)
  set @DeckID = scope_identity()
  
  begin tran NewDeckDetails 
   if @InFormatID is NOT NULL 
    BEGIN 
     insert into tblDECK_FORMAT (DeckID, FormatID)
      VALUES (@DeckID, @InFormatID)
    END 
   insert into tblDECK_CARD (DeckID, CardFaceID, Quantity)
    select @DeckID, CF.CardFaceID, Quantity
     from #deck U 
     join tblCARD_FACE CF on U.CardFace = CF.CardFaceSearchName 
  --   where CFS.IsReprint is NULL 
   if (@WithCMDR is NOT NULL) or (@WithSIDE is NOT NULL) or (@WithMAYB is NOT NULL) or (@WithWISH is NOT NULL) 
   BEGIN 
    if @WithMAYB is NOT NULL 
     insert into @maybe (Item) 
      select value as Item from STRING_SPLIT(@WithMAYB, '|')
    if @WithWISH is NOT NULL 
     insert into @wish (Item) 
      select value as Item from STRING_SPLIT(@WithWISH, '|')
    if @WithCMDR is NOT NULL 
     insert into @cmdr (Item)
      select value as Item from STRING_SPLIT(@WithCMDR, '|')
    if @WithSIDE is NOT NULL 
     insert into @side (Item)
      select value as Item from STRING_SPLIT(@WithSIDE, '|')
    insert into tblDECK_CARD_ZONE (DeckID, CardFaceID, Quantity, ZoneID)
    select @DeckID, X.CardFaceID, X.Quantity, X.ZoneID from (
     select CF.CardFaceID, Count(U.PK) as Quantity, @CommandZoneID as ZoneID 
      from @cmdr U 
      join tblCARD_FACE CF on U.Item = CF.CardFaceSearchName 
      group by CF.CardFaceID 
     UNION ALL 
     select CF.CardFaceID, Count(U.PK) as Quantity, @SideZoneID as ZoneID 
      from @side U 
      join tblCARD_FACE CF on U.Item = CF.CardFaceSearchName 
      group by CF.CardFaceID 
     UNION ALL 
     select CF.CardFaceID, Count(U.PK) as Quantity, @MaybeZoneID as ZoneID 
      from @maybe U 
      join tblCARD_FACE CF on U.Item = CF.CardFaceSearchName 
      group by CF.CardFaceID 
     UNION ALL 
     select CF.CardFaceID, Count(U.PK) as Quantity, @WishZoneID as ZoneID
      from @wish U 
      join tblCARD_FACE CF on U.Item = CF.CardFaceSearchName 
      group by CF.CardFaceID 
    ) as X 
   END 
  commit tran NewDeckDetails 
 commit tran NewDeck 
 END 
GO 

exec dbo.ENV_VAR_UPD8 N'tblUSER'
GO 

create OR alter proc SPAGHETTI_decking --run with up-to-date environment variables!
 as BEGIN 
 declare @pickuser int, @UserName varchar(100), @UserID int, @deckcount int, @deck Unlisted, @deckids UnlistedInts, @dupes int, @pickcard int, @priv char(1), @decklist varchar(8000)
 set NOCOUNT ON 
 exec dbo.GET_RANDOM_ROW 
  @FromTable = N'tblUSER',
  @randro = @pickuser OUT 
 set @UserName = dbo.fetch_UsernameByID(@pickuser)
 if @UserName is NULL 
  BEGIN 
   exec dbo.GET_RANDOM_ROW 
    @FromTable = N'tblUSER',
    @randro = @pickuser OUT 
   set @UserName = dbo.fetch_UsernameByID(@pickuser)
  END 
 set @deckcount = CEILING(Rand() * 50)
 if (@deckcount % 5 = 0) set @priv = 'Y'
 while @deckcount > 0 
  BEGIN 
  exec dbo.GET_RANDOM_ROW 
   @FromTable = N'tblCARD_FACE',
   @randro = @pickcard OUT 
  insert into @deckids (Item) VALUES (@pickcard)
  if (@deckcount % 17 = 0)
   BEGIN 
    set @dupes = CEILING(Rand() * 3)
    while @dupes > 0 
     BEGIN 
      insert into @deckids (Item) VALUES (@pickcard)
      set @dupes = @dupes - 1 
     END 
   END 
  set @deckcount = @deckcount - 1 
  END 
 insert into @deck (Item)
  select CF.CardFaceSearchName from tblCARD_FACE CF
   join @deckids D on CF.CardFaceID = D.Item 
 set @decklist = (select STRING_AGG(Item, '|') from @deck)
 exec dbo.u_ADD_NewDeck 
  @ForUserName = @UserName,
  @FormatMachineName = NULL, 
  @DeckNameString = NULL,
  @WithMAIN = @decklist,
  @WithSIDE = NULL,
  @WithMAYB = NULL,
  @WithCMDR = NULL,
  @WithWISH = NULL,
  @IsPrivate = @priv 
 END 
GO 

create OR alter proc SPAGHETTI_decking_AUTO 
 @times int
 as BEGIN 
 set NOCOUNT ON 
 while @times > 0 
  BEGIN 
  exec dbo.SPAGHETTI_decking 
  set @times = @times - 1 
  END 
 END 
GO 

exec dbo.ENV_VAR_UPD8 N'tblDECK'
GO 

