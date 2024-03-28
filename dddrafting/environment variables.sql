
create table META_ENV_VAR (
 PK int Identity(1,1) primary key NOT NULL, 
 NameOfTable varchar(25) unique NOT NULL, 
 nrow int NULL,
 smallest int NULL, 
 biggest int NULL)
GO 

declare @wordles int, @wordles_min int, @wordles_max int, @stops int, @stops_min int, @stops_max int, @users int, @users_min int, @users_max int, @decks int, @decks_min int, @decks_max int, @cardfaces int, @cardfaces_min int, @cardfaces_max int 
set @wordles = (select Count(PK) from UN_Wordle)
set @wordles_min = (select Min(PK) from UN_Wordle)
set @wordles_max = (select Max(PK) from UN_Wordle)
set @stops = (select Count(PK) from UN_StopWord)
set @stops_min = (select Min(PK) from UN_StopWord)
set @stops_max = (select Max(PK) from UN_StopWord)

--set @decks = (select Count(DeckID) from tblDECK)
--set @decks_min = (select Min(DeckID) from tblDECK)
--set @decks_max = (select Max(DeckID) from tblDECK)
set @users = (select Count(UserID) from tblUSER)
set @users_min = (select Min(UserID) from tblUSER)
set @users_max = (select Max(UserID) from tblUSER)
--set @cardfaces = (select Count(CardFaceID) from tblCARD_FACE)
insert into META_ENV_VAR (NameOfTable, nrow, smallest, biggest)
 VALUES ('UN_Wordle', @wordles, @wordles_min, @wordles_max), ('UN_StopWord', @stops, @stops_min, @stops_max), ('tblUSER', @users, @users_min, @users_max)
GO 

insert into META_ENV_VAR (NameOfTable) VALUES ('tblDECK'), ('tblCARD'), ('tblCARD_FACE'), ('tblSET'), ('tblCARD_FACE_SET'), ('tblDECK_FORMAT')
GO 

create OR alter proc env_const_upd8 
as BEGIN 
 declare @wordles int, @wordles_min int, @wordles_max int, @stops int, @stops_min int, @stops_max int
 set @wordles = (select Count(PK) from UN_Wordle)
 set @wordles_min = (select Min(PK) from UN_Wordle)
 set @wordles_max = (select Max(PK) from UN_Wordle)
 update META_ENV_VAR 
  set nrow = @wordles,
    smallest = @wordles_min,
    biggest = @wordles_max
  where NameOfTable = 'UN_Wordle'
 set @stops = (select Count(PK) from UN_StopWord)
 set @stops_min = (select Min(PK) from UN_StopWord)
 set @stops_max = (select Max(PK) from UN_StopWord) 
 update META_ENV_VAR 
  set nrow = @stops, 
    smallest = @stops_min,
    biggest = @stops_max
  where NameOfTable = 'UN_StopWord'
END 
GO 

create OR alter proc env_var_upd8 
 as BEGIN 
 declare @users int, @decks int, @cardfaces int 
 set @decks = (select Count(DeckID) from tblDECK)
 update META_ENV_VAR 
  set nrow = @decks 
  where NameOfTable = 'tblDECK'
 set @users = (select Count(UserID) from tblUSER)
 update META_ENV_VAR 
  set nrow = @users 
  where NameOfTable = 'tblUSER'
 set @cardfaces = (select Count(CardFaceID) from tblCARD_FACE) 
 update META_ENV_VAR 
  set nrow = @cardfaces 
  where NameOfTable = 'tblCARD_FACE'
 END 
GO 

select * from META_ENV_VAR