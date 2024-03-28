select * from FLEETING_formats

select N.FormatNameID, T.FormatTypeID, M.FormatMediumID into #formatting 
 from FLEETING_formats FF 
 join defFORMAT_MEDIUM M on FF.Meds = M.FormatMediumAbbrev
 join defFORMAT_NAME N on FF.MachineName = N.FormatNameMachineReadable 
 join defFORMAT_TYPE T on FF.TypeName = T.FormatTypeName

select * from #formatting 


insert into refFORMAT (FormatNameID, FormatTypeID, FormatMediumID)
 select FormatNameID, FormatTypeID, FormatMediumID from #formatting 

drop table FLEETING_formats