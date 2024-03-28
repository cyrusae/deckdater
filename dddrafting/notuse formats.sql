use deckdater_dev
GO 


create OR alter proc CRE8_Formats 
 @name varchar(25),
 @type varchar(25),
 @mediums int 
 as BEGIN 
 declare @nameID int, @typeID int
 declare @mediumList as table (
  FormatMediumID int 
 )
 set @typeID = (select FormatTypeID from defFORMAT_TYPE where FormatTypeName = @type)
 set @nameID = (select FormatNameID from defFORMAT_NAME where FormatNameMachineReadable = @name)
 if @mediums = 2
  BEGIN 
   insert into @mediumList (FormatMediumID) 
    select FormatMediumID from defFORMAT_MEDIUM
  END 
 ELSE if @mediums = 1 
  BEGIN 
   insert into @mediumList (FormatMediumID) 
    select FormatMediumID from defFORMAT_MEDIUM where FormatMediumAbbrev = 'BO1'
  END 
 ELSE if @mediums = 3 
  BEGIN 
   insert into @mediumList (FormatMediumID)
    select FormatMediumID from defFORMAT_MEDIUM 
     where FormatMediumAbbrev = 'BO3'
  END 
 insert into refFORMAT (FormatNameID, FormatTypeID, FormatMediumID)
  select @nameID, @typeID, FormatMediumID from @mediumList
 END 
GO 