--first-batch/manual sets import 
select SCS.SetID, SCS.SetCode, SCS.SetName, SCS.SetScryfallAPI, SCS.SetScryfallURI, SCS.SetReleaseDate, ST.SetTypeID, SCS.CollectorCount as SetCollectorCount, SCS.SetIsDigital, B.BlockID into #setsimport from SCRY_CANON_SETS SCS 
 join defSET_TYPE ST on SCS.SetTypeName = ST.SetTypeName
 LEFT join tblBLOCK B on SCS.BlockCode = B.BlockCode 

insert into tblSET (SetID, SetCode, SetName, SetScryfallAPI, SetScryfallURI, SetReleaseDate, SetTypeID, SetCollectorCount, SetIsDigital, BlockID)
 select SetID, SetCode, SetName, SetScryfallAPI, SetScryfallURI, SetReleaseDate, SetTypeID, SetCollectorCount, SetIsDigital, BlockID from #setsimport 


truncate table SCRY_CANON_SETS 