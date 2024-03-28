use Info_430_deckdater 
GO 

--Run if they don't exist yet: 

select * into STAGE_CARDS from SCRY_CANON_CARDS where 1=0
alter table STAGE_CARDS 
 drop column PK 

select * into STAGE_SETS from SCRY_CANON_SETS where 1=0
alter table STAGE_SETS 
 drop column PK 
GO 

create OR alter proc UNSTAGE_SetsExisting 
 as BEGIN 
 set NOCOUNT ON 
 if exists (select SetID from STAGE_SETS)
  BEGIN 
   begin tran addsets
   insert into SCRY_CANON_SETS (SetID, SetCode, SetName, SetReleaseDate, SetTypeName, SetCollectorCount, SetScryfallURI, SetScryfallAPI, BlockCode, SetIsDigital)
    select SetID, SetCode, SetName, SetReleaseDate, SetTypeName, SetCollectorCount, SetScryfallURI, SetScryfallAPI, BlockCode, SetIsDigital from STAGE_SETS 
   commit 
   truncate table STAGE_SETS 
  END 
 END 
GO 

create OR alter proc UNSTAGE_CardsExisting 
 as BEGIN 
 set NOCOUNT ON 
 if exists (select CardID from STAGE_CARDS)
  BEGIN 
   begin tran addcards 
   insert into SCRY_CANON_CARDS (CardID, CardFaceName, CardFaceSearchName, CardSetScryfallAPI, CardSetScryfallURI, LayoutName, FaceName, Supertypes, Types, Subtypes, SetID, RarityName, PlatformName, IsReprint)
    select CardID, CardFaceName, CardFaceSearchName, CardSetScryfallAPI, CardSetScryfallURI, LayoutName, FaceName, Supertypes, Types, Subtypes, SetID, RarityName, PlatformName, IsReprint from STAGE_CARDS
   commit 
   truncate table STAGE_CARDS 
  END 
 END 
GO 

create OR alter proc GET_RANDOM_ROW
 @FromTable nvarchar(50),
 @randro int OUT 
 as BEGIN 
  declare @SQLstring nvarchar(1000), @ParmDefinition nvarchar(50), @pkol nvarchar(50), @nrow int, @smol int, @big int, @loop int, @coin int, @head int, @tail int, @try1 int, @try2 int 
  set @loop = 1 
  set @ParmDefinition = N'@trial int, @found int OUT'
  select @pkol = IndexedOn, 
   @nrow = nrow, 
   @smol = smallest,
   @big = biggest 
   from META_ENV_VAR 
    where TableName = @FromTable
  set @SQLstring = 'set @found = (select ' 
     + @pkol + ' from ' 
     + @FromTable + ' where ' 
     + @pkol + ' = @trial)'
  while @loop > 0 
  BEGIN 
   set @head = Ceiling(Rand() * @big)
   set @tail = @smol + Floor(Rand() * @nrow)
   set @coin = Floor(Rand() * 2)
   EXEC sp_executesql @SQLstring,
     @ParmDefinition,
     @trial = @head,
     @found = @try1 OUT 
   EXEC sp_executesql @SQLstring,
     @ParmDefinition,
     @trial = @tail,
     @found = @try2 OUT 
   if (@coin > 0) 
    BEGIN 
     if (@try1 is NULL) set @randro = @try2
      ELSE set @randro = @try1 
    END 
   ELSE 
    BEGIN 
     if (@try2 is NULL) set @randro = @try1 
      ELSE set @randro = @try2 
    END 
   if @randro is NULL 
    set @loop = @loop + 1
   if @loop > 100 --give up eventually 
    BREAK 
   ELSE set @loop = 0
  END 
 END 
GO

create OR alter proc get_RandomWordleWord 
 @WordlePK int OUT 
 as BEGIN 
 exec dbo.GET_RANDOM_ROW N'UN_Wordle', @WordlePK OUT 
 END 
GO 

create OR alter function fetch_WordleByPK (
 @PK int
) returns char(5)
 as BEGIN 
 declare @RET char(5)
 set @RET = (select Wordle from UN_Wordle where PK = @PK)
 return @RET 
 END 
GO 

create OR alter proc get_RandomStopWord 
 @StopPK int OUT 
 as BEGIN 
 exec dbo.GET_RANDOM_ROW N'UN_StopWords', @StopPK OUT 
 END 
GO 

create OR alter function fetch_StopByPK (
 @PK int
) returns varchar(10)
 as BEGIN 
 declare @RET varchar(10)
 set @RET = (select StopWord from UN_StopWords where PK = @PK)
 return @RET 
 END 
GO 

create OR alter function fetch_UserIDbyUserName (
 @UserName varchar(100)
) returns INT 
 as BEGIN 
 declare @RET int 
 set @RET = (select UserID from tblUSER 
  where UserName = @UserName)
 return @RET 
 END 
GO 

create OR alter function fetch_UserNamebyID (
 @UserID int
) returns int 
 as BEGIN 
 declare @RET varchar(100)
 set @RET = (select UserName from tblUSER 
  where UserID = @UserID)
 return @RET 
 END 
GO 

create OR alter function fetch_DeckIDbyName (
 @UserName varchar(100),
 @DeckName varchar(350)
) returns INT 
 as BEGIN 
 declare @RET int 
 set @RET = (select DeckID from tblDECK D 
  join tblUSER U on D.UserID = U.UserID 
  where UserName = @UserName 
   and DeckName = @DeckName)
 return @RET 
 END 
GO 

create OR alter function fetch_FormatTypeIDbyName (
 @FormatTypeName varchar(25)
) returns INT 
 as BEGIN 
 declare @RET int 
 set @RET = (select FormatTypeID 
  from defFORMAT_TYPE
  where FormatTypeName = @FormatTypeName)
 return @RET 
 END 
GO 

create OR alter function fetch_FormatNameIDbyMachine (
 @FormatMachineName varchar(25)
) returns INT 
 as BEGIN 
 declare @RET int 
 set @RET = (select FormatNameID from defFORMAT_NAME 
  where FormatNameMachineReadable = @FormatMachineName)
 return @RET 
 END 
GO 

create OR alter function fetch_FormatIDbyMachineName(
 @FormatMachineName varchar(25)
) returns INT 
 as BEGIN 
 declare @RET int, @NameID int 
 set @NameID = dbo.fetch_FormatNameIDbyMachine(@FormatMachineName)
 set @RET = (select Top 1 FormatID from refFORMAT 
  where FormatNameID = @NameID
  order by FormatID desc) --the order by is to make this generic for later when subtyping of formats is implemented in a way I'm happy with, since there are cases where format subtyping doesn't matter to a lookup 
 return @RET 
 END 
GO 

create OR alter function fetch_ZoneIDbyName (
 @ZoneName char(4)
) returns INT 
 as BEGIN 
 declare @RET int 
 set @RET = (select ZoneID from defZONE 
  where ZoneName = @ZoneName)
 return @RET 
 END 
GO 

create OR alter function fetch_CardFaceIDbyName (
 @CardFaceSearchName varchar(100)
) returns INT 
 as BEGIN 
 declare @RET int 
 set @RET = (select CardFaceID from tblCARD_FACE 
  where CardFaceSearchName = @CardFaceSearchName)
 return @RET 
 END 
GO 

create OR alter function fetch_CardIDbyFaceName(
 @CardFaceSearchName varchar(100)
) returns varchar(36) 
 as BEGIN 
 declare @RET varchar(36), @CardFaceID int 
 set @CardFaceID = dbo.fetch_CardFaceIDbyName(@CardFaceSearchName)
 set @RET = (select CardID from tblCARD_FACE 
  where CardFaceID = @CardFaceID)
 return @RET 
 END 
GO 

--manual-ish format load 
create OR alter proc a_ADD_NewFormats
 @TypeName varchar(25),
 @FormatString varchar(500)
 as BEGIN 
 declare @TypeID int 
 set @TypeID = dbo.fetch_FormatTypeIDbyName(@TypeName)
 if @TypeID is NULL 
  BEGIN 
   print 'Type not found!';
   throw 89356, 'Type ID not found. Check spelling, and remember Type input is one at a time here.', 14;
  END ;
 
 with FormatsInvolved (FormatTypeID, FormatNameID) as (
  select @TypeID as FormatTypeID, FormatNameID 
   from defFORMAT_NAME FN 
   join STRING_SPLIT(@FormatString, ',')
    on value = FormatNameMachineReadable)
 
 insert into refFORMAT (FormatTypeID, FormatNameID) 
  select FormatTypeID, FormatNameID 
   from FormatsInvolved 
   except (select F.FormatTypeID, F.FormatNameID 
    from refFORMAT F 
    join FormatsInvolved FI on (F.FormatTypeID = FI.FormatTypeID 
     and F.FormatNameID = FI.FormatNameID)) ;
 END 
GO 

create OR alter proc ENV_VAR_ColFunctions 
 @UseTable nvarchar(50),
 @UseColumn nvarchar(50),
 @UseFunction nvarchar(10),
 @res int OUT 
 as BEGIN 
 declare @SQLstring nvarchar(1000), @ParmString nvarchar(100)
 set @SQLstring = 'set @checked = (select '
   + @UseFunction + '(' + @UseColumn + ') from ' + @UseTable + ')'
 set @ParmString = N'@checked int OUT'
 EXEC sp_executesql @SQLstring, 
   @ParmString, @checked = @res OUT 
 END 
GO 

create OR alter proc ENV_VAR_UPD8 
 @ForTable nvarchar(50)
 as BEGIN 
 declare @pkol nvarchar(50), @nrow int, @minrow int, @maxrow int, @SQLcheck nvarchar(1000), @ParmCheck nvarchar(100)
 set @pkol = (select IndexedOn from META_ENV_VAR where TableName = @ForTable)
 exec dbo.ENV_VAR_ColFunctions 
  @UseTable = @ForTable,
  @UseColumn = @pkol,
  @UseFunction = N'Count',
  @res = @nrow OUT 
 exec dbo.ENV_VAR_ColFunctions
  @UseTable = @ForTable,
  @UseColumn = @pkol, 
  @UseFunction = N'Max',
  @res = @maxrow OUT 
 exec dbo.ENV_VAR_ColFunctions 
  @UseTable = @ForTable, 
  @UseColumn = @pkol, 
  @UseFunction = N'Min',
  @res = @minrow OUT 
 if (@nrow is NOT NULL) and (@minrow is NOT NULL) and (@maxrow is NOT NULL)
  update META_ENV_VAR 
   set nrow = @nrow,
     biggest = @maxrow,
     smallest = @minrow
    where TableName = @ForTable
 END 
GO 

create OR alter function makeupaguy_deckname(@UserID int, @DeckName varchar(280)) 
 returns varchar(350)
 as BEGIN 
 declare @RET varchar(350), @repeats int 
 if @DeckName IS NULL 
  set @DeckName = 'New Deck'
 set @repeats = (select Count(DeckID) from tblDECK where DeckName = @DeckName and UserID = @UserID)
 if @repeats > 0 
  BEGIN 
   declare @GenericizedDeckName varchar(350)
   set @GenericizedDeckName = @DeckName + ' %'
   set @repeats = @repeats + (select Count(DeckID) from tblDECK where UserID = @UserID and DeckName like @DeckName)
   set @RET = @DeckName + ' ' + Cast(@repeats as varchar)
  END 
  ELSE set @RET = @DeckName
 return @RET 
 END 
GO 

create OR alter trigger t_AddCanonSets on SCRY_CANON_SETS 
 after INSERT 
 as BEGIN 

 if @@ROWCOUNT < 1 RETURN ; 
 set NOCOUNT ON 
 begin tran ImportSets 
 begin tran SetData 
 select i.SetID, S.SetID as OldSetID, i.SetCode, i.SetName, i.SetReleaseDate, T.SetTypeID, i.SetCollectorCount, i.SetScryfallURI, i.SetScryfallAPI, B.BlockID, i.SetIsDigital into #inserted  
  from inserted i 
  join defSET_TYPE T on i.SetTypeName = T.SetTypeName 
  LEFT join tblBLOCK B on Cast(i.BlockCode as char(3)) = B.BlockCode 
  LEFT join tblSET S on i.SetID = S.SetID 
 commit 
 begin tran InsertionBatch 
 create NONCLUSTERED index ix_ins_SetID on #inserted (SetID)
 
 insert into tblSET (SetID, SetCode, SetName, SetReleaseDate, SetTypeID, SetCollectorCount, SetScryfallURI, SetScryfallAPI, BlockID, SetIsDigital)
  select SetID, SetCode, SetName, SetReleaseDate, SetTypeID, SetCollectorCount, SetScryfallURI, SetScryfallAPI, BlockID, SetIsDigital from #inserted 
  where OldSetID is NULL 
 commit 
 begin tran UpdateBatch 
 update tblSET 
  set SetReleaseDate = i.SetReleaseDate, 
   SetTypeID = i.SetTypeID,
   SetCollectorCount = i.SetCollectorCount,
   SetScryfallURI = i.SetScryfallURI,
   SetScryfallAPI = i.SetScryfallAPI,
   BlockID = i.BlockID,
   SetIsDigital = i.SetIsDigital 
  from #inserted i 
   join tblSET S on i.SetID = S.SetID 
    where (i.SetReleaseDate != S.SetReleaseDate 
      and i.SetReleaseDate is NOT NULL)
     or (i.SetTypeID != S.SetTypeID 
      and i.SetTypeID is NOT NULL)
     or (i.SetCollectorCount > S.SetCollectorCount 
      or S.SetCollectorCount is NULL)
     or (i.SetScryfallURI != S.SetScryfallURI 
      and i.SetScryfallURI is NOT NULL)
     or (i.SetScryfallAPI != S.SetScryfallAPI 
      and i.SetScryfallAPI is NOT NULL) 
     or (i.BlockID != S.BlockID 
      and S.BlockID is NULL)
  commit 
 delete from SCRY_CANON_SETS 
  where SetID in (select SetID from #inserted)
 drop index ix_ins_SetID on #inserted 
 drop table #inserted 
 commit 
 END 
GO 

create OR alter trigger t_AddCanonCards on SCRY_CANON_CARDS 
 after INSERT 
 as BEGIN 
 
 if @@ROWCOUNT < 1 RETURN ;
 set NOCOUNT ON 
 begin tran prep  

 begin tran CheckPrecursors 
 if exists (select SetID from STAGE_SETS) 
  BEGIN 
   print 'WARNING: Cannot load cards without unstaging sets first. Executing sets loader.';
   exec dbo.UNSTAGE_SetsExisting 
   print 'Set unstaging attempted. wARNING: This card insertion should be considered high-risk; reevaluate pipeline.';
  END 
 commit 

 select * into #inserted from inserted 

 alter table #inserted 
  Add Constraint temp_ins_PK PRIMARY KEY NONCLUSTERED (PK)

 create NONCLUSTERED INDEX ix_ins_CardID on #inserted(CardID)
 INCLUDE (CardFaceSearchName, LayoutName, FaceName, SetID)

 begin tran CheckNewSets 
  if (select Count(i.SetID) from #inserted i 
   where i.SetID not in (select SetID from tblSET S)) > 0
   BEGIN 
    print 'WARNING: Attempted card import with a nonexisting set! Cards in that set will be deleted at join with no remaining records. Check pipeline integrity.';
   END 
 commit 

 select i.PK as PK, i.CardID as CardID, C.CardID as OldCardID, CF.CardFaceID as CardFaceID, i.CardFaceName as CardFaceName, i.CardFaceSearchName as CardFaceSearchName, LF.LayoutFaceID as LayoutFaceID, i.Supertypes as SupertypeList, i.Types as TypeList, i.Subtypes as SubtypeList, CFS.CardFaceSetID as CardFaceSetID, i.SetID as SetID, P.PlatformID as PlatformID, i.CardSetScryfallURI as ScryfallURI, i.CardSetScryfallAPI as ScryfallAPI, R.RarityID as RarityID, Cast(i.IsReprint as char(1)) as IsReprint into #processing
  from #inserted i 
  join defPLATFORM P on i.PlatformName = P.PlatformName 
  join defRARITY R on i.RarityName = R.RarityName 
  join defLAYOUT L on i.LayoutName = L.LayoutName 
  join defFACE F on i.FaceName = F.FaceName
  join refLAYOUT_FACE LF 
   on (L.LayoutID = LF.LayoutID 
       AND F.FaceID = LF.FaceID)
  LEFT join tblCARD C on i.CardID = C.CardID 
  LEFT join tblCARD_FACE CF 
   on (i.CardID = CF.CardID 
      AND i.CardFaceSearchName = CF.CardFaceSearchName 
      AND LF.LayoutFaceID = CF.LayoutFaceID)
  LEFT join tblCARD_FACE_SET CFS 
   on (i.SetID = CFS.SetID 
      AND CF.CardFaceID = CFS.CardFaceID) 
  group by i.PK, i.CardID, C.CardID, CF.CardFaceID, i.CardFaceName, i.CardFaceSearchName, LF.LayoutFaceID, i.Supertypes, i.Types, i.Subtypes, CFS.CardFaceSetID, i.SetID, P.PlatformID, i.CardSetScryfallURI, i.CardSetScryfallAPI, R.RarityID, i.IsReprint
 
 alter table #processing 
  Add Constraint temp_procss_PK PRIMARY KEY NONCLUSTERED (PK)

 create NONCLUSTERED index ix_process_CardID on #processing(CardID)
  INCLUDE (CardFaceID, CardFaceSearchName, CardFaceSetID, SetID, PlatformID)
 commit 

 begin tran CardImport 
 begin tran DoCards 
 insert into tblCARD (CardID)
  select distinct CardID from #processing 
   where OldCardID is NULL 
  group by CardID 
 commit 
 
 begin tran DoFaces 
 select CF.CardID, CF.CardFaceID, P.LayoutFaceID, P.CardFaceName, P.CardFaceSearchName into #oldcards 
  from #processing p 
  join tblCARD_FACE CF on (p.CardID = CF.CardID 
   and p.CardFaceSearchName = CF.CardFaceSearchName 
   and p.LayoutFaceID = CF.LayoutFaceID)
  group by CF.CardID, CF.CardFaceID, P.LayoutFaceID, P.CardFaceName, P.CardFaceSearchName
 
 select CardID, LayoutFaceID, CardFaceName, CardFaceSearchName into #newfaces 
  from #processing p 
  except (select CardID, LayoutFaceID, CardFaceName, CardFaceSearchName from #oldcards)

 insert into tblCARD_FACE (CardID, LayoutFaceID, CardFaceName, CardFaceSearchName)
  select CardID, LayoutFaceID, CardFaceName, CardFaceSearchName 
   from #newfaces p
 commit 

 begin tran ReDoFaces 
 update #processing 
  set CardFaceID = CF.CardFaceID 
   from tblCARD_FACE CF 
    join #processing p
     on (CF.CardFaceSearchName = p.CardFaceSearchName 
      and CF.CardID = p.CardID)
    where p.CardFaceID is NULL 
   commit ;
 
 begin tran DoTypeLine 
 select CardFaceID, SupertypeList, TypeList, SubtypeList into #typelineprocessing 
  from #processing 
  group by CardFaceID, SupertypeList, TypeList, SubtypeList ; 

 with SupertypeLine (CardFaceID, SupertypeName) as (
 select CardFaceID, Trim(value) as SupertypeName 
  from #typelineprocessing 
  CROSS APPLY String_Split(SupertypeList, ' ')
  where SupertypeList is NOT NULL)

 insert into tblCARD_FACE_SUPERTYPE (CardFaceID, SupertypeID)
  select p.CardFaceID, S.SupertypeID 
  from SupertypeLine p 
   join defSUPERTYPE S on p.SupertypeName = S.SupertypeName
   except (select CardFaceID, SupertypeID from tblCARD_FACE_SUPERTYPE) ;

 with TypeLine (CardFaceID, TypeName) as (
  select CardFaceID, Trim(value) as TypeName 
  from #typelineprocessing 
  CROSS APPLY String_Split(TypeList, ' '))

 insert into tblCARD_FACE_TYPE (CardFaceID, TypeID) 
  select p.CardFaceID, T.TypeID 
  from TypeLine p 
  join defTYPE T on p.TypeName = T.TypeName 
  except (select CardFaceID, TypeID from tblCARD_FACE_TYPE) ;

 with SubtypeLine (CardFaceID, SubtypeName) as (
  select CardFaceID, Trim(value) as SubtypeName 
  from #typelineprocessing 
  CROSS APPLY String_Split(SubtypeList, ' ')
  where SubtypeList is NOT NULL)

 insert into tblCARD_FACE_SUBTYPE (CardFaceID, SubtypeID)
  select p.CardFaceID, S.SubtypeID 
  from SubtypeLine p 
  join defSUBTYPE S on p.SubtypeName = S.SubtypeName 
  except (select CardFaceID, SubtypeID from tblCARD_FACE_SUBTYPE) ;
 commit 

 begin tran DoPrintings 
 insert into tblCARD_FACE_SET (CardFaceID, SetID, RarityID, IsReprint)
  select CardFaceID, SetID, RarityID, IsReprint
  from #processing 
   where CardFaceSetID is NULL 
  group by CardFaceID, SetID, RarityID, IsReprint
 commit 

 begin tran ReDoPrintings 
 update #processing 
  set CardFaceSetID = CFS.CardFaceSetID 
  from tblCARD_FACE_SET CFS 
   join #processing p on (CFS.CardFaceID = p.CardFaceID 
    and CFS.SetID = p.SetID )
   where p.CardFaceSetID is NULL 

 update tblCARD_FACE_SET 
  set 
   RarityID = p.RarityID, 
   IsReprint = p.IsReprint
  from tblCARD_FACE_SET CFS 
   join #processing p on CFS.CardFaceSetID = p.CardFaceSetID 
   where CFS.RarityID != p.RarityID 
    OR CFS.IsReprint != p.IsReprint 
    
    commit ;

 begin tran DoPlatformInclusion 
 select CardFaceSetID, PlatformID, ScryfallURI, ScryfallAPI into #processplatform 
  from #processing p 
 
 MERGE tblCARD_FACE_SET_PLATFORM as TARGET 
  using #processplatform as SOURCE 
  on (TARGET.CardFaceSetID = SOURCE.CardFaceSetID 
    and TARGET.PlatformID = SOURCE.PlatformID)
  when MATCHED and (TARGET.CardSetPlatformScryfallURI != SOURCE.ScryfallURI or TARGET.CardSetPlatformScryfallAPI != SOURCE.ScryfallAPI) 
   THEN update set TARGET.CardSetPlatformScryfallURI = SOURCE.ScryfallURI, TARGET.CardSetPlatformScryfallAPI = SOURCE.ScryfallAPI 
  when NOT MATCHED by TARGET 
   THEN insert (CardFaceSetID, PlatformID, CardSetPlatformScryfallURI, CardSetPlatformScryfallAPI) VALUES (SOURCE.CardFaceSetID, SOURCE.PlatformID, SOURCE.ScryfallURI, SOURCE.ScryfallAPI) ; 
 commit 

 delete from SCRY_CANON_CARDS where PK in (select PK from #inserted)
 alter table #inserted 
  drop constraint temp_ins_PK
 alter table #processing 
  drop constraint temp_procss_PK
 drop index ix_ins_CardID on #inserted 
 drop table #inserted 
 drop index ix_process_CardID on #processing 
 drop table #processing 
 drop table #typelineprocessing 
 drop table #processplatform 
 commit 
 END 
GO 
