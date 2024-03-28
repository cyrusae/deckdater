use Info_430_deckdater 
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
/* make sure that worked: 
select F.FormatID, FormatNameMachineReadable, FormatTypeName 
 from refFORMAT F 
 join defFORMAT_NAME N on F.FormatNameID = N.FormatNameID
 join defFORMAT_TYPE T on F.FormatTypeID = T.FormatTypeID */
