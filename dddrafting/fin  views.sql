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

