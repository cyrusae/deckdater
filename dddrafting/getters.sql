create OR alter proc get_RandomUserID 
 @RandomUser int OUT 
 as BEGIN 
 declare @nrow int, @off int 
 set @nrow = (select Count(UserID) from tblUSER)
 while @RandomUser is NULL 
  BEGIN 
   set @off = Floor(Rand() * @nrow)
   set @RandomUser = (select UserID from tblUSER
    order by UserID
    offset @off rows 
    fetch next 1 rows only)
  END 
 END 
GO 

create OR alter function fetch_UserNamebyID (
 @UserID int
) returns int 
 as BEGIN 
 declare @RET varchar(100)
 set @RET = (select UserName from tblUSER 
  where UserID = @UserID)
 return @RET 
 END 
GO 

create OR alter proc get_RandomDeckID 
 @RandomDeck int OUT 
 as BEGIN 
 declare @nrow int, @off int 
 set @nrow = (select Count(DeckID) from tblDECK)
 while @RandomDeck is NULL 
  BEGIN 
   set @off = Floor(Rand() * @nrow)
   set @RandomDeck = (select DeckID from tblDECK
    order by DeckID
    offset @off rows 
    fetch next 1 rows only)
  END 
 END 
GO 

create OR alter proc get_RandomCardFaceID --make sure this works as intended (skips pulling two of the same card's faces)
 @RandomCardFace int OUT 
 as BEGIN 
 declare @nrow int, @off int 
 set @nrow = (select Count(CardID) from tblCARD_FACE)
 while @RandomCardFace is NULL 
  BEGIN 
   set @off = Floor(Rand() * @nrow)
   set @RandomCardFace = (select CardFaceID from tblCARD_FACE
    --group by CardID
    order by CardFaceID
    offset @off rows 
    fetch next 1 rows only)
  END 
 END 
GO 

create OR alter function fetch_CardIDbyFaceID (
 @CardFaceID int
) returns varchar(36)
 as BEGIN 
 declare @RET varchar(36)
 set @RET = (select CardID from tblCARD_FACE
  where CardFaceID = @CardFaceID)
 return @RET 
 END 
GO 

create OR alter proc get_RandomWordleWord 
 @WordlePK int OUT 
 as BEGIN 
 exec dbo.GET_RANDOM_ROW N'UN_Wordle', @WordlePK OUT 
 END 
GO 

create OR alter function fetch_WordleByPK (
 @PK int
) returns char(5)
 as BEGIN 
 declare @RET char(5)
 set @RET = (select Word from UN_Wordle where PK = @PK)
 return @RET 
 END 
GO 

create OR alter proc get_RandomStopWord 
 @StopPK int OUT 
 as BEGIN 
 exec dbo.GET_RANDOM_ROW N'UN_StopWord', @StopPK OUT 
 END 
GO 

create OR alter function fetch_StopByPK (
 @PK int
) returns varchar(10)
 as BEGIN 
 declare @RET varchar(10)
 set @RET = (select Word from UN_StopWord where PK = @PK)
 return @RET 
 END 
GO 
/*
create table UN_StopWord ( --data dump of stop words (no punctuation)
 PK int Identity(1,1) primary key NOT NULL,
 Word varchar(10) unique NOT NULL)

create table UN_Wordle ( --list of legal Wordle words lol
 PK int Identity(1,1) primary key NOT NULL,
 Word char(5) unique NOT NULL)
GO */

create OR alter proc get_RandomWordleWord 
 @WordlePK int OUT 
 as BEGIN 
 declare @nrow int, @off int 
 set @nrow = (select Count(PK) from UN_Wordle)
 while @WordlePK is NULL 
  BEGIN 
   set @off = Floor(Rand() * @nrow)
   set @WordlePK = (select PK from UN_Wordle
    order by PK 
    offset @off rows 
    fetch next 1 rows only)
  END 
 END 
GO 

create OR alter function fetch_WordleByPK (
 @PK int
) returns char(5)
 as BEGIN 
 declare @RET char(5)
 set @RET = (select Word from UN_Wordle where PK = @PK)
 return @RET 
 END 
GO 

create OR alter proc get_RandomStopWord 
 @StopPK int OUT 
 as BEGIN 
 declare @nrow int, @off int 
 set @nrow = (select Count(PK) from UN_StopWord)
 while @StopPK is NULL 
  BEGIN 
   set @off = Floor(Rand() * @nrow)
   set @StopPK = (select PK from UN_StopWord
    order by PK 
    offset @off rows 
    fetch next 1 rows only)
  END 
 END 
GO 

create OR alter function fetch_StopByPK (
 @PK int
) returns char(5)
 as BEGIN 
 declare @RET char(5)
 set @RET = (select Word from UN_StopWord where PK = @PK)
 return @RET 
 END 
GO 

create type UserNameGenerator as table (
 WordOrder int PRIMARY KEY NONCLUSTERED NOT NULL,
 Word varchar(10))
  with (MEMORY_OPTIMIZED = ON);
GO 

