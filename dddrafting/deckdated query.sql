
declare @DeckID int, @lastupd8 date, @recents varchar(8000), @recentstring varchar(8000)
set @lastupd8 = (select LastKnownDate from tblDECK 
 where DeckID = @DeckID)

with NewestThen (SetCode, SetName, ListFaces) as (select S.SetCode, S.SetName, STRING_AGG(CF.CardFaceName, ', ') as ListFaces --will want to use the regenerated full card name in future 
 from tblSET S 
 join tblCARD_FACE_SET CFS on S.SetID = CFS.SetID 
 join tblCARD_FACE CF on CFS.CardFaceID = CF.CardFaceID 
 join tblDECK_CARD DC on CF.CardFaceID = DC.CardFaceID 
 where SetReleaseDate = @lastupd8
  and IsReprint != 'Y') 

select @recents = STRING_AGG(Convert(varchar(8000), Concat(SetCode, ', ', SetName, ', added ', ListFaces)), '; ') from NewestThen ; 
set @recentstring = 'Last confirmed update: <b>' + Cast(@lastupd8 as varchar(25)) + '</b> (' + @recents + ')'

print @recentstring ;

select S.SetCode, S.SetName, S.SetReleaseDate, 
 CASE WHEN S.SetReleaseDate < GetDate()
  THEN 'Released'
 ELSE 'In previews' END as SetReleaseStatus, S.SetCollectorCount, Count(distinct CF.CardID) as NewCards, S.SetScryfallURI
 from tblSET S 
 join tblCARD_FACE_SET CFS on S.SetID = CFS.SetID 
 join defSET_TYPE DT on S.SetTypeID = DT.SetTypeID
 join tblCARD_FACE CF on CFS.CardFaceID = CF.CardFaceID
 join tblCARD_FACE_SUBTYPE CFT on CF.CardFaceID = CFT.CardFaceID 
 join defSUBTYPE ST on CFT.SubtypeID = ST.SubtypeID
 where DT.SetTypeName not in ('promo', 'masterpiece', 'funny', 'token', 'memorabilia', 'box') --this needs to be determined by format procedurally in future with a fallback list, for the record 
  and IsReprint != 'Y'
  and SetReleaseDate > @lastupd8
 group by S.SetCode, S.SetName, S.SetReleaseDate, S.SetScryfallURI
 having Count(distinct CF.CardID) > 0
 order by S.SetReleaseDate desc
GO 
