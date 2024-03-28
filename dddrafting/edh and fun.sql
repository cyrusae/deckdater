create table defCOMMANDER_TYPE (
 CommanderTypeID int Identity(1,1) primary key NOT NULL,
 CommanderTypeName varchar(25) unique,
 CommanderTypeDesc varchar(500) NULL)

--run once:
/* --gonna leave this until I have more sure of how to process it.
insert into defCOMMANDER_TYPE(CommanderTypeName, CommanderTypeDesc)
 VALUES('Partner with', 'Can be used as a commander iff it is paired with a specific card'), ('Choose a Background', 'Can be used alongside a Background card'), ('Background', 'Is a Background card'), ('Partner', 'Just straight up has Partner') 
 */

create table tblCARD_COMMANDER (
 CardID varchar(36) FOREIGN KEY references tblCARD,
 --CommanderTypeID int SPARSE FOREIGN KEY references defCOMMANDER_TYPE NULL, --this is to think on.
 Constraint CommandersAreCards PRIMARY KEY (CardID))
GO 

create view SEE_FormatFacts as 
 select F.FormatID, FN.FormatName, FN.FormatNameMachineReadable, FT.FormatTypeID, FT.FormatTypeName, FM.FormatMediumID, FM.FormatMediumName, FE.BeginDate, FE.EndDate 
  from refFORMAT F 
  join defFORMAT_NAME FN on F.FormatNameID = FN.FormatNameID 
  join defFORMAT_TYPE FT on F.FormatTypeID = FT.FormatTypeID 
  join defFORMAT_MEDIUM FM on F.FormatMediumID = FM.FormatMediumID 
  LEFT join refFORMAT_EPOCH FE on F.FormatID = FE.FormatID 
GO 

create OR alter view SEE_CardStatusExceptions as 
 select CF.CardID, CF.CardFaceID, CFS.PlatformID, NSS.FormatID, NSS.CardStatusID, DCS.CardStatusName, NSS.BeginDate, NSS.EndDate from tblCARD_FACE CF 
  join tblCARD_FACE_SET CFS on CF.CardFaceID = CFS.CardFaceID 
  join tblCARD_NOT_SET_STATUS NSS on CFS.CardFaceSetID = NSS.CardFaceSetID 
  join defCARD_STATUS DCS on NSS.CardStatusID = DCS.CardStatusID 
GO 

--sweep intial... (run only once)
insert into tblCARD_COMMANDER 
 select CF.CardID from tblCARD_FACE CF 
  join tblCARD_FACE_TYPE CT on CF.CardFaceID = CT.CardFaceID 
  join tblCARD_FACE_SUPERTYPE CS on CF.CardFaceID = CS.CardFaceID 
  join defTYPE T on CT.TypeID = T.TypeID 
  join defSUPERTYPE S on CS.SupertypeID = S.SupertypeID 
  join tblCARD_FACE_SET CFS on CF.CardFaceID = CFS.CardFaceID 
  LEFT join tblSET S on CFS.SetID = S.SetID 
  LEFT join refSET_TYPE_STATUS RST on S.SetTypeID = RST.SetTypeID 
  LEFT join defSET_STATUS DSS on RST.SetStatusID = DSS.SetStatusID 
  LEFT join SEE_FormatFacts SFF on RST.FormatID = SFF.FormatID 
  LEFT join tblCARD_NOT_SET_STATUS CNS on CFS.CardFaceSetID = CNS.CardFaceSetID 
  LEFT join defCARD_STATUS DCS on CNS.CardStatusID = DCS.CardStatusID
  LEFT join SEE_FormatFacts CFF on CNS.FormatID = CFF.FormatID 
  where SupertypeName = 'Legendary'
   and TypeName = 'Creature'
   and ((SFF.FormatName = 'commander'
     and DSS.SetStatusName = 'legal'
     and CNS.BeginDate is NULL)
    or (CFF.FormatName = 'commander'
     and DCS.CardStatusName = 'legal'
     and CNS.EndDate is NULL))
   and CF.CardID not in (select CardID from tblCARD_COMMANDER)
  group by CF.CardID 
 GO 

create table tblDECK_EDH_GENERAL (
 DeckID int FOREIGN KEY references tblDECK_CARD NOT NULL,
 CardFaceID int FOREIGN KEY references tblDECK_CARD NOT NULL,
 FriendlyOnly char(1) SPARSE NULL, --e.g. listing Olivia and Edgar as "partnered" commanders despite it not being legal for them to be, so that the system can still process color ID et al appropriately; using a legend that isn't legal because it's Grand Calculotron or a non-"this card can be your commander" planeswalker; etc.
 Constraint CommandersArePartOfYourEDHDeck PRIMARY KEY (DeckID, CardID))
GO 

create table tblDECK_BRAWL_GENERAL (
 DeckID int FOREIGN KEY references tblDECK_CARD NOT NULL,
 CardFaceID int FOREIGN KEY references tblDECK_CARD NOT NULL,
 Constraint CommandersArePartOfYourBrawlDeck PRIMARY KEY (DeckID, CardFaceID))
GO 

create OR alter function check_hapaxstatus(@OfCard varchar(36)) returns int 
 as BEGIN 
 declare @RET int
  -- with one ping:
 set @RET = (select Count(distinct SetID) from tblCARD_FACE CF 
  join tblCARD_FACE_SET CFS on CF.CardFaceID = CFS.CardFaceID 
  join defPLATFORM P on CFS.PlatformID = P.PlatformID
  where CardID = @OfCard
   and PlatformName = 'paper')
 return @RET 
 END 
GO --iff @RET = 1 then a card is hapax-legal 

create table tblCARD_HAPAX (
 CardID varchar(36) FOREIGN KEY references tblCARD NOT NULL,
 BeginDate date,
 EndDate date NULL,
 Constraint HapaxCardsAreStillCards PRIMARY KEY (CardID))
GO 

create OR alter proc CONFER_HapaxCard 
 @ToCardID varchar(36)
 as BEGIN 
 declare @Since date, @Fluke date
 if not exists (select CardID from tblCARD_HAPAX where CardID = @ToCardID)
 BEGIN 
 set @Since = (select Top 1 SetReleaseDate from tblSET S 
  join tblCARD_FACE_SET CFS on S.SetID = CFS.SetID 
  join tblCARD_FACE CF on CFS.CardFaceID = CF.CardFaceID
  join defPLATFORM P on CFS.PlatformID = P.PlatformID
  where CF.CardID = @ToCardID
   and P.PlatformName = 'paper'
  group by CF.CardID, SetReleaseDate
  order by SetReleaseDate asc)
 set @Fluke = (select Top 1 CardReleaseDate from tblCARD_NOT_SET_DATE ND 
  join tblCARD_FACE_SET CFS on ND.CardFaceSetID = CFS.CardFaceSetID 
  join defPLATFORM P on CFS.PlatformID = P.PlatformID
  where CF.CardID = @ToCardID
   and P.PlatformName = 'paper')

 if @Fluke is NOT NULL 
  if @Fluke < @Since set @Since = @Fluke

  insert into tblCARD_HAPAX (CardID, BeginDate)
   VALUES (@ToCardID, @Since)
  END 
 END 
GO 

create OR alter proc REVOKE_HapaxCard 
 @FromCardID varchar(36)
 as BEGIN 
 declare @OnDate date, @Doppel int, @Began date, @IsBasic int 

 set @IsBasic = (select Count(CardID) from tblCARD_FACE CF
  join tblCARD_FACE_SUPERTYPE CS on CF.CardFaceID = CS.CardFaceID 
  join defSUPERTYPE S on CS.SupertypeID = S.SupertypeID 
  join tblCARD_FACE_TYPE CT on CF.CardFaceID = CT.CardFaceID 
  join defTYPE T on CT.TypeID = T.TypeID
  where CardID = @FromCardID 
   and SupertypeName = 'Basic'
   and TypeName = 'Land')
 
 begin tran 
  begin tran MakeHapax
  if not exists (select CardID from tblCARD_HAPAX where CardID = @CardID) --every card was hapax at some point
    exec dbo.CONFER_HapaxCard 
     @ToCardID = @FromCardID 
   commit tran MakeHapax

 if (@IsBasic = 0) and (dbo.check_hapaxstatus(@CardID) > 1)
  BEGIN 
   begin tran UnmakeHapax
   set @Began = (select BeginDate from tblCARD_HAPAX where CardID = @FromCardID)
   select Top 1 @Doppel = CardFaceSetID, 
    @OnDate = SetReleaseDate 
    from tblCARD_FACE_SET CFS 
     join tblSET S on CFS.SetID = S.SetID 
     join tblCARD_FACE CF on CFS.CardFaceID = CF.CardFaceID
     join defPLATFORM P on CFS.PlatformID = P.PlatformID  
    where CF.CardID = @FromCardID 
     and SetReleaseDate > @Began 
     and PlatformName = 'paper'
    order by SetReleaseDate asc 
   
    update tblCARD_HAPAX 
     set EndDate = @OnDate 
     where CardID = @FromCardID 
      and EndDate is NULL 
   commit tran UnmakeHapax
  END 
  commit 
 END 
GO 

create OR alter proc CONFER_CommanderCard 
 @ToCardID varchar(36)
 as BEGIN 
 if 
  (not exists (select CardID from tblCARD_COMMANDER 
   where CardID = @ToCardID)) 
  and (exists (select CardID from tblCARD_FACE CF 
   join tblCARD_FACE_SET CFS on CF.CardFaceID = CFS.CardFaceID 
   join tblSET S on CFS.SetID = S.SetID 
   join refSET_TYPE_STATUS RSTS on S.SetTypeID = RSTS.SetTypeID 
   join defSET_STATUS DSS on RSTS.SetStatusID = DSS.SetStatusID
   join SEE_FormatFacts SFF on RSTS.FormatID = SFF.FormatID
   where CF.CardID = @ToCardID
    and DSS.SetStatusName = 'legal'
    and SFF.FormatNameMachineReadable = 'commander'
   group by CF.CardID))
  and (not exists (select E.CardID from SEE_CardStatusExceptions E 
   join refFORMAT F on E.FormatID = F.FormatID 
   join defFORMAT_NAME FN on F.FormatNameID = FN.FormatNameID
   where E.CardID = @ToCardID 
    and FN.FormatNameMachineReadable = 'commander'
    and E.CardStatusName != 'legal'
    and E.EndDate is NOT NULL
   group by CF.CardID))
   BEGIN 
    insert into tblCARD_COMMANDER
     VALUES(@ToCardID)
   END 
 END 
GO 

create OR alter proc REVOKE_CommanderCard 
 @FromCardID varchar(36)
 as BEGIN 

 if (exists (select CardID from tblCARD_COMMANDER where CardID = @FromCardID))
  and (exists (select E.CardID from SEE_CardStatusExceptions E 
   join refFORMAT F on E.FormatID = F.FormatID 
   join defFORMAT_NAME FN on F.FormatNameID = FN.FormatNameID 
   where E.CardID = @CardID 
    and FN.FormatNameMachineReadable = 'commander'
    and E.CardStatusName != 'legal'
    and E.EndDate is NULL))
  delete from tblCARD_COMMANDER 
   where CardID = @FromCardID 
 END 
GO 

create OR alter proc RESTORE_CommanderCard 
 @ForCardID varchar(36)
 as BEGIN 

 if not exists (select E.CardID from SEE_CardStatusExceptions E 
   join SEE_FormatFacts F on E.FormatID = F.FormatID 
   where E.CardID = @CardID 
    and F.FormatNameMachineReadable = 'commander'
    and E.CardStatusName != 'legal'
    and E.EndDate is NULL)
  exec dbo.CONFER_CommanderCard 
   @ToCardID = @ForCardID 
 END 
GO 

create OR alter function lookup_FormatNameID(@MachineName varchar(25)) returns int 
 as BEGIN 
 declare @RET int 
 set @RET = (select FormatNameID from defFORMAT_NAME where FormatNameMachineReadable = @MachineName)
 return @RET 
 END 
GO 

create OR alter function lookup_CardStatusID(@StatusName varchar(25)) returns int 
 as BEGIN 
 declare @RET int 
 set @RET = (select CardStatusID from defCARD_STATUS where CardStatusName = @StatusName)
 return @RET 
 END 
GO 

create OR alter function lookup_SetStatusID(@StatusName varchar(25)) returns int 
 as BEGIN 
 declare @RET int 
 set @RET = (select CardStatusID from defSET_STATUS where SetStatusName = @StatusName)
 return @RET 
 END 
GO 

create trigger CHECK_NewlyBannedCommander 
 on tblCARD_NOT_SET_STATUS 
 after INSERT 
 as BEGIN 
 declare @legalID int, @isEDH int, @ticker int, @checkingCard varchar(36)
 set @isEDH = dbo.lookup_FormatNameID('commander')
 set @legalID = dbo.lookup_CardStatusID('legal')
 select CF.CardID into #changed 
  from inserted i 
  join tblCARD_FACE_SET CFS on i.CardFaceSetID = CFS.CardFaceSetID 
  join tblCARD_FACE CF on CFS.CardFaceID = CF.CardFaceID 
  where i.FormatID = @isEDH 
   and i.CardStatusID != @legalID 
   and i.EndDate is NULL 
 set @ticker = (select Count(distinct CardID) from #changed)
 while @ticker > 0 
  BEGIN
  set @checkingCard = (select Top 1 CardID from #changed order by BeginDate asc)
  exec dbo.REVOKE_CommanderCard @checkingCard --update the list of valid commanders 
  delete from #changed where CardID = @checkingCard 
  set @ticker = @ticker - 1 
  END 
 END 
GO 

create trigger CHECK_StatusUpdateCommander 
 on tblCARD_NOT_SET_STATUS 
 after UPDATE 
 as BEGIN 
 declare @legalID int, @isEDH int, @ticker int, @checkingCard varchar(36), @formerStatus int, @ended date 
 set @isEDH = dbo.lookup_FormatNameID('commander')
 set @legalID = dbo.lookup_CardStatusID('legal')

 select CF.CardID, u.CardStatusID, u.EndDate into #changed from updated u 
  join tblCARD_FACE_SET CFS on u.CardFaceSetID = CFS.CardFaceSetID 
  join tblCARD_FACE CF on CFS.CardFaceID = CF.CardFaceID 
  where u.FormatID = @isEDH
  group by CF.CardID, u.CardStatusID, u.EndDate 
  
 set @ticker = (select Count(distinct CardID) from #changed)
 while @ticker > 0 
  BEGIN 
  select Top 1 @checkingCard = CardID,
   @formerStatus = CardStatusID, 
   @ended = EndDate
   from #changed
   order by EndDate asc
  if (@formerStatus = @legalID) and (@ended is NOT NULL) --remove its legal status if it used to be "legal" and no longer is
   exec dbo.REVOKE_CommanderCard @checkingCard 
   ELSE exec dbo.RESTORE_CommanderCard @checkingCard --otherwise, check if it should be marked legal in the index of commanders 
  delete from #changed where CardID = @checkingCard 
  set @ticker = @ticker - 1 
  END 
 END 
GO 