--new legal vampires for Edgar with CMC 3 or under 
select Top 1 S.SetID, S.SetCode, S.SetName, S.SetReleaseDate from tblSET S 
 join defSET_TYPE DST on S.SetTypeID = DST.SetTypeID 
 join refSET_TYPE_STATUS RSTS on DST.SetTypeID = RSTS.SetTypeID 
 join defSET_STATUS DSS on RSTS.SetStatusID = DSS.SetStatusID 
 join refFORMAT RF on RSTS.FormatID = RF.FormatID 
 join defFORMAT_NAME DFN on RF.FormatNameID = DFN.FormatNameID 
 join defFORMAT_MEDIUM DFM on RF.FormatMediumID = DFM.FormatMediumID 
 where DFM.FormatMediumName = 'Traditional'
  and DFN.FormatName = 'Commander'
  and DSS.SetStatusName = 'legal'
 order by SetReleaseDate desc 

--in that set (one week before release)
select CFS.CardFaceSetID, C.CardName, CFS.CardSetScryfallURI from tblCARD_FACE_SET CSF
 join tblCARD_FACE CF on CFS.CardFaceID = CF.CardFaceID 
 join tblCARD C on CF.CardID = C.CardID 
 LEFT join tblCARD_FACE_COLOR CFC on CF.CardFaceID = CFC.CardFaceID 
 join defCOLOR DC on CFC.ColorID = DC.ColorID 
 join tblCARD_FACE_TYPE CFT on CF.CardFaceID = CFT.CardFaceID 
 join defTYPE DT on CFT.TypeID = DT.TypeID 
 join tblCARD_FACE_SET_COST CFST on CFS.CardFaceSetID = CFST.CardFaceSetID 
 join refCOST RC on CFST.CostID = RC.CostID 
 join defPLATFORM DP on CFS.PlatformID = DP.PlatformID
 where DT.TypeName = 'Vampire'
  and (DC.ColorName not in ('Blue', 'Green')
   or CFC.ColorID is NULL)
  and CFS.IsReprint is NULL 
  and DP.PlatformName = 'Paper'
  --and S.SetID = @NewestSet
 group by CFS.CardFaceSetID, CFS.CardSetScryfallURI, C.CardName 
 having Sum(RC.CostCMC) >= 3

--check for mill theme
select Count(CSF.CardFaceSetID) from tblCARD_FACE_SET CFS
 join tblCARD_FACE_KEYWORD CFK on CFS.CardFaceID = CFK.CardFaceID 
 join defKEYWORD K on CFK.KeywordID = K.KeywordID
 where K.KeywordName = 'Mill'
  --and CFS.SetID = @NewestSet
 --threshold handled in function

--new mill cards for Mirko in sets with a Mill subtheme 
select CSF.CardFaceSetID, C.CardName, CSF.CardSetScryfallURI from tblCARD_FACE_SET CFS
 join tblCARD_FACE CF on CFS.CardFaceID = CF.CardFaceID 
 join tblCARD C on CF.CardID = C.CardID 
 LEFT join tblCARD_FACE_COLOR CFC on CF.CardFaceID = CFC.CardFaceID 
 join defCOLOR DC on CFC.ColorID = DC.ColorID 
 join defPLATFORM DP on CFS.PlatformID = DP.PlatformID
 join tblCARD_FACE_KEYWORD CFK on CFS.CardFaceID = CFK.CardFaceID 
 join defKEYWORD K on CFK.KeywordID = K.KeywordID
 where K.KeywordName = 'Mill'
  --and CFS.SetID = @NewestSet
  and (DC.ColorName in ('Blue', 'Black')
   or CFC.ColorID is NULL)
  and CFS.IsReprint is NULL 
  and DP.PlatformName = 'Paper'
 group by CFS.CardSetFaceID, CFS.CardSetScryfallURI, C.CardName 
