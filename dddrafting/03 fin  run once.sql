use Info_430_deckdater 
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

--manual insert for the small lookup tables:
insert into defSET_STATUS (SetStatusName, SetStatusDesc) 
 VALUES ('legal', 'Exceptions will be bans and restrictions, within applicable time'), ('not_legal', 'Exceptions will be... acorn stamp mostly')

insert into defFORMAT_TYPE (FormatTypeName, FormatTypeDesc)
 VALUES ('Eternal', 'Cards are legal by default'), ('Era', 'Cards are legal when printed in a timespan (usually based on a begin date only)'), ('Rotating', 'Cards are conditionally legal, based on date printed, for a fixed span of time')
 
insert into META_ENV_VAR (TableName, IndexedOn)
 VALUES (N'UN_Wordle', N'PK'), (N'UN_StopWords', N'PK'), (N'tblCARD', N'CardCount'), (N'tblSET', N'SetCount'), (N'tblCARD_FACE', N'CardFaceID'), (N'tblCARD_FACE_SET', N'CardFaceSetID'), ('refFORMAT', 'FormatID'), (N'tblUSER', N'UserID'), (N'tblDECK', N'DeckID')
GO 

insert into defFACE (FaceName, FaceDesc)
 VALUES ('default', 'Front face'), ('naming', 'Back, transformed, otherwise contributes to name with own name'), ('alternate', 'Melded, specialized, otherwise does not contribute to name and has own name')

insert into defTYPE (TypeName)
 VALUES ('Land'), ('Instant'), ('Sorcery'), ('Enchantment'), ('Artifact'), ('Creature'), ('Planeswalker'), ('Tribal'), ('Conspiracy'), ('Plane'), ('Phenomenon'), ('Scheme'), ('Vanguard'), ('Dungeon') 

insert into defSUPERTYPE (SupertypeName)
 VALUES ('Basic'), ('Legendary'), ('Snow'), ('World'), ('Ongoing'), ('Elite'), ('Host'), ('Token'), ('Emblem') --Token and Emblem aren't a "real" card supertype, it's another kind of object, but we're doing that here for now for reasons that will be apparent another day.

insert into defPLATFORM (PlatformName, PlatformDesc) 
 VALUES ('paper', 'Traditionally-printed Magic; the "canonical" default'), ('mtgo', 'Magic: the Gathering Online'), ('arena', 'Magic: the Gathering Arena (includes Rebalanced cards)')

insert into defRARITY (RarityName)
 VALUES ('common'), ('uncommon'), ('rare'), ('mythic')

insert into defZONE (ZoneName, ZoneDesc)
 VALUES ('CMDR', 'Command zone (Commander and Background)'), ('SIDE', 'Sideboard'), ('MAYB', 'Maybeboard'), ('WISH', 'Wishboard') --I still don't know if chosen companions are technically something else.

insert into defFORMAT_NAME (FormatNameMachineReadable, FormatAlias)
 VALUES ('standard', 'Standard'), ('explorer', 'Explorer'), ('pioneer', 'Pioneer'), ('gladiator', 'Gladiator'), ('alchemy', 'Alchemy'), ('historic', 'Historic'), ('commander', 'EDH'), ('paupercommander', 'Pauper EDH'), ('historicbrawl', 'Historic Brawl'), ('modern', 'Modern'), ('vintage', 'Vintage'), ('legacy', 'Legacy'), ('brawl', 'Brawl')
GO 

insert into refLAYOUT_FACE (LayoutID, FaceID)
 select LayoutID, FaceID from defLAYOUT 
  join defFACE on 1=1
GO 

create type Unlisted as table (
 PK int Identity(1,1) primary key NONCLUSTERED NOT NULL,
 Item varchar(500))
  with (MEMORY_OPTIMIZED = ON);
GO 

create type UnlistedInts as table (
 PK int Identity(1,1) primary key NONCLUSTERED NOT NULL,
 Item int)
  with (MEMORY_OPTIMIZED = ON);
GO 

exec dbo.a_ADD_NewFormats 
 @TypeName = 'Era',
 @FormatString = 'pioneer,explorer,modern'

exec dbo.a_ADD_NewFormats 
 @TypeName = 'Eternal',
 @FormatString = 'commander,paupercommander,vintage,legacy,historic,historicbrawl,gladiator'

exec dbo.a_ADD_NewFormats 
 @TypeName = 'Rotating',
 @FormatString = 'brawl,alchemy,standard'
GO 

