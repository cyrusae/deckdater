use Info_430_deckdater
GO 

create OR alter function dbo.COUNT_SetsInBlock(@PK int)
 returns INT 
 with SCHEMABINDING 
 as BEGIN 
 declare @RET int 
 set @RET = (select Count(SetID) from dbo.tblSET 
   where BlockID = @PK)
 return @RET 
 END 
GO 

alter table tblBLOCK 
 Add SetsContained as dbo.COUNT_SetsInBlock(BlockID)  
GO 

create OR alter function dbo.COUNT_MainDeckCards(@PK int)
 returns INT 
 with SCHEMABINDING 
 as BEGIN 
 declare @RET int 
 set @RET = (select Sum(Quantity) from dbo.tblDECK_CARD 
  where DeckID = @PK)
 return @RET 
 END 
GO 

alter table tblDECK 
 Add MainDeckSize as dbo.COUNT_MainDeckCards(DeckID)  
GO 

create OR alter function dbo.COUNT_NewCardsInSet (@PK varchar(36)) 
 returns INT 
 with SCHEMABINDING 
 as BEGIN 
 declare @RET int 
 set @RET = (select Count(CardFaceSetID) from dbo.tblCARD_FACE_SET 
  where SetID = @PK 
   and IsReprint is NULL)
 return @RET 
 END 
GO 

alter table tblSET 
 Add NewCards as dbo.COUNT_NewCardsInSet(SetID)  
GO 
