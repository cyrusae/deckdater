create OR alter function fn_CardFullName (@CardID varchar(36)) --e.g. "Wear // Tear"
 returns varchar(200)
 as BEGIN 
 declare @RET varchar(200)
 select CardFaceID, CardFaceName, FaceName
  into #lookatthiscard 
  from tblCARD_FACE CF 
   join refLAYOUT_FACE R on CF.LayoutFaceID = R.LayoutFaceID 
   join defLAYOUT L on R.LayoutID = L.LayoutID 
   join defFACE F on R.FaceID = F.FaceID 
   where CF.CardID = @CardID 
    and FaceName in ('default', 'naming')
 if (select Count(CardFaceID) from #lookatthiscard) = 1
  set @RET = (select CardFaceName from #lookatthiscard)
 ELSE
  BEGIN 
   declare @front varchar(200), @sep char(4), @other varchar(200)
   set @front = (select CardFaceName from #lookatthiscard where FaceName = 'default')
   set @sep = ' // '
   set @other = (select CardFaceName from #lookatthiscard where FaceName = 'naming')
   set @RET = @front + @sep + @other
  END 
 return @RET 
 END 
GO 

create OR alter function fn_CardAliasName (@CardID varchar(36)) --e.g. "Wear and Tear"
 returns varchar(200)
 as BEGIN 
 declare @RET varchar(200), @front varchar(200), @sep varchar(10), @other varchar(200)
 select CardFaceID, CardFaceName, FaceName, LayoutSep
  into #lookatthiscard 
  from tblCARD_FACE CF 
   join refLAYOUT_FACE R on CF.LayoutFaceID = R.LayoutFaceID 
   join defLAYOUT L on R.LayoutID = L.LayoutID 
   join defFACE F on R.FaceID = F.FaceID 
   where CF.CardID = @CardID 
    and FaceName in ('default', 'naming')
    and LayoutSep is NOT NULL 
 set @front = (select CardFaceName from #lookatthiscard 
  where FaceName = 'default')
 set @sep = (select Top(1) LayoutSep from #lookatthiscard)
 set @other = (select CardFaceName from #lookatthiscard
  where FaceName = 'naming')
 set @RET = @front + ' ' + @sep + ' ' + @other
 return @RET 
 END 
GO 

alter table tblCARD 
 ADD CardName as fn_CardFullName(CardID) persisted NOT NULL

alter table tblCARD
 ADD CardAlias as fn_CardAliasName(CardID) persisted --this one's nullable 
GO 