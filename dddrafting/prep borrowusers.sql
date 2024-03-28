select * into #holdusers from deckdater_dev.dbo.tblUSER 

select * from #holdusers  

insert into tblUSER (UserDOB, Email, FirstName, LastName, UserName, DisplayName, DateCreated, DateUpdated, IsInactive)
 select UserDOB, Email, FirstName, LastName, UserName, DisplayName, DateCreated, DateUpdated, IsInactive from #holdusers
  where UserName not in ('Emperor', 'Magician')

exec dbo.ENV_VAR_UPD8 N'tblUSER'
exec dbo.ENV_VAR_UPD8 N'tblSET'
exec dbo.ENV_VAR_UPD8 N'tblCARD'
exec dbo.ENV_VAR_UPD8 N'tblCARD_FACE'

select * from META_ENV_VAR
