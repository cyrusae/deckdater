use Info_430_deckdater
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
 set @RET = (select Wordle from UN_Wordle where PK = @PK)
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

create OR alter function fetch_DeckIDbyName (
 @UserName varchar(100),
 @DeckName varchar(350)
) returns INT 
 as BEGIN 
 declare @RET int 
 set @RET = (select DeckID from tblDECK D 
  join tblUSER U on D.UserID = U.UserID 
  where UserName = @UserName 
   and DeckName = @DeckName)
 return @RET 
 END 
GO 

create OR alter function fetch_FormatTypeIDbyName (
 @FormatTypeName varchar(25)
) returns INT 
 as BEGIN 
 declare @RET int 
 set @RET = (select FormatTypeID 
  from defFORMAT_TYPE
  where FormatTypeName = @FormatTypeName)
 return @RET 
 END 
GO 

create OR alter function fetch_FormatNameIDbyMachine (
 @FormatMachineName varchar(25)
) returns INT 
 as BEGIN 
 declare @RET int 
 set @RET = (select FormatNameID from defFORMAT_NAME 
  where FormatNameMachineReadable = @FormatMachineName)
 return @RET 
 END 
GO 

create OR alter function fetch_FormatIDbyMachineName(
 @FormatMachineName varchar(25)
) returns INT 
 as BEGIN 
 declare @RET int, @NameID int 
 set @NameID = dbo.fetch_FormatNameIDbyMachine(@FormatMachineName)
 set @RET = (select Top 1 FormatID from refFORMAT 
  where FormatNameID = @NameID
  order by FormatID desc) --the order by is to make this generic for later when subtyping of formats is implemented in a way I'm happy with, since there are cases where format subtyping doesn't matter to a lookup 
 return @RET 
 END 
GO 

create OR alter function fetch_ZoneIDbyName (
 @ZoneName char(4)
) returns INT 
 as BEGIN 
 declare @RET int 
 set @RET = (select ZoneID from defZONE 
  where ZoneName = @ZoneName)
 return @RET 
 END 
GO 

create OR alter function fetch_CardFaceIDbyName (
 @CardFaceSearchName varchar(100)
) returns INT 
 as BEGIN 
 declare @RET int 
 set @RET = (select CardFaceID from tblCARD_FACE 
  where CardFaceSearchName = @CardFaceSearchName)
 return @RET 
 END 
GO 

create OR alter function fetch_CardIDbyFaceName(
 @CardFaceSearchName varchar(100)
) returns varchar(36) 
 as BEGIN 
 declare @RET varchar(36), @CardFaceID int 
 set @CardFaceID = dbo.fetch_CardFaceIDbyName(@CardFaceSearchName)
 set @RET = (select CardID from tblCARD_FACE 
  where CardFaceID = @CardFaceID)
 return @RET 
 END 
GO 

