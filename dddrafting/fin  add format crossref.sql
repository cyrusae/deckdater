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

exec dbo.a_ADD_NewFormats 
 @TypeName = 'Era',
 @FormatString = 'pioneer,explorer,modern'

exec dbo.a_ADD_NewFormats 
 @TypeName = 'Eternal',
 @FormatString = 'commander,paupercommander,vintage,legacy,historic,historicbrawl,gladiator'

exec dbo.a_ADD_NewFormats 
 @TypeName = 'Rotating',
 @FormatString = 'brawl,alchemy,standard'

/* make sure that worked: 
select F.FormatID, FormatNameMachineReadable, FormatTypeName 
 from refFORMAT F 
 join defFORMAT_NAME N on F.FormatNameID = N.FormatNameID
 join defFORMAT_TYPE T on F.FormatTypeID = T.FormatTypeID */