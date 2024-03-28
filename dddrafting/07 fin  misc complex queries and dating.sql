use Info_430_deckdater
GO

--examples of queries experimented with while I'm systematizing dating 

declare @lastupd8 date 

select DC.CardFaceID, S.SetCode, S.SetName, S.SetReleaseDate, DENSE_RANK() over (partition by DC.CardFaceID order by S.SetReleaseDate asc) as PrintOrder into #Edgar from tblDECK_CARD DC 
 join tblDECK D on DC.DeckID = D.DeckID 
 join tblUSER U on D.UserID = U.UserID 
 join tblCARD_FACE_SET CFS on DC.CardFaceID = CFS.CardFaceID
 join tblSET S on CFS.SetID = S.SetID 
 where UserName = 'Emperor'
  and DeckName = 'warmer than wine'

select Top 1 SetReleaseDate, SetCode, SetName from #Edgar where PrintOrder = 1 group by SetCode, SetName, SetReleaseDate order by SetReleaseDate desc 

select CF.CardFaceName, CFS.IsReprint, S.SetCode, S.SetName, S.SetReleaseDate from tblCARD_FACE CF 
 join #Edgar E on CF.CardFaceID = E.CardFaceID 
 join tblCARD_FACE_SET CFS on CF.CardFaceID = CFS.CardFaceID 
 join tblSET S on CFS.SetID = S.SetID 
 where S.SetCode = (select Top 1 SetCode from Edgar where PrintOrder = 1 order by SetReleaseDate desc)
 group by CF.CardFaceName, CFS.IsReprint, S.SetCode, S.SetName, S.SetReleaseDate

select @lastupd8 = Max(SetReleaseDate) from #Edgar 
 where PrintOrder = 1 ; 

select S.SetCode, S.SetName, S.SetReleaseDate, 
 CASE WHEN S.SetReleaseDate < GetDate()
  THEN 'Released'
 ELSE 'In previews' END as SetReleaseStatus, 
 Count(distinct CF.CardID) as NewCards, S.SetScryfallURI
 from tblSET S 
 join tblCARD_FACE_SET CFS on S.SetID = CFS.SetID 
 join defSET_TYPE DT on S.SetTypeID = DT.SetTypeID
 join tblCARD_FACE CF on CFS.CardFaceID = CF.CardFaceID
 join tblCARD_FACE_SUBTYPE CFT on CF.CardFaceID = CFT.CardFaceID 
 join defSUBTYPE ST on CFT.SubtypeID = ST.SubtypeID
 where DT.SetTypeName not in ('promo', 'masterpiece', 'funny', 'token', 'alchemy', 'box', 'memorabilia')
  and IsReprint != 'Y'
  and SetReleaseDate > @lastupd8
 group by S.SetCode, S.SetName, S.SetReleaseDate, S.SetScryfallURI
 having Count(distinct CF.CardID) > 0
 order by S.SetReleaseDate desc 

GO 

--generalized query: 

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

-- try using hapax trait:

select Max(CH.BeginDate) from tblSET S 
 join tblCARD_FACE_SET CFS on S.SetID = CFS.SetID 
 join tblCARD_FACE CF on CFS.CardFaceID = CF.CardFaceID 
 join tblCARD_HAPAX CH on CF.CardID = CH.CardID 
 join tblDECK_CARD DC on CF.CardFaceID = DC.CardFaceID 
 join tblDECK D on DC.DeckID = D.DeckID 
 join tblUSER U on D.UserID = U.UserID 
 where UserName = 'Emperor'
  and DeckName = 'warmer than wine'
  --time: 00.053s - 00.047s range 
  --00.082s to get the "which card and which set" version above with a temp table 
  --00.02s with function that uses the deck ID directly but similar speed 
  --go figure 