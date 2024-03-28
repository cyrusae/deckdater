create table GUYTESTER (
 PK int Identity(1,1) primary key NOT NULL,
 UserDOB date NULL,
 Email varchar(200) NULL,
 FirstName varchar(25) NULL,
 LastName varchar(25) NULL,
 UserName varchar(100) NULL,
 DisplayName varchar(140) NULL)
GO 

create trigger t_Tester on GUYTESTER
 after insert 
 as BEGIN 
 set NOCOUNT ON 
 declare @guys int, @thisguy int, @guyDOB date, @guymail varchar(200), @guyFname varchar(25), @guyLname varchar(25), @guyUser varchar(100), @guyDN varchar(140)
 set @guys = (select Count(PK) from inserted)
 while @guys > 0 
 BEGIN 
 set @thisguy = (select Min(PK) from inserted)
 select @guyDOB = UserDOB, 
   @guymail = Email, 
   @guyFname = FirstName, 
   @guyLname = LastName, 
   @guyUser = UserName, 
   @guyDN = DisplayName 
   from inserted 
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