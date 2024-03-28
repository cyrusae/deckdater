create OR alter proc TRY_guyer 
@guys int NULL 
as BEGIN 
SET NOCOUNT ON 

declare @thisguy int, @guyDOB date, @guymail varchar(200), @guyFname varchar(25), @guyLname varchar(25), @guyUser varchar(100), @guyDN varchar(140)
if @guys is NULL 
 set @guys = 1000 --(select Count(PK) from GUYTESTER)
while @guys > 0 
 BEGIN 
 set @thisguy = (select Min(PK) from GUYTESTER)
 select @guyDOB = UserDOB, 
   @guymail = Email, 
   @guyFname = FirstName, 
   @guyLname = LastName, 
   @guyUser = UserName, 
   @guyDN = DisplayName 
   from GUYTESTER 
   where PK = @thisguy 
 exec dbo.u_NewUser 
  @UserDOB = @guyDOB,
  @Email = @guymail, 
  @FirstName = @guyFname,
  @LastName = @guyLname,
  @UserName = @guyUser,
  @DisplayName = @guyDN 
 delete from GUYTESTER where PK = @thisguy
 set @guys = @guys - 1 
END 
END 
GO 