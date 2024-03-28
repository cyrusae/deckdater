use deckdater_dev 
GO 

select Count(PK) from GUYTESTER

select Count(UserID) from TEST_USER 

select Top 50 * from TEST_USER order by NewID()

select * into GUYTRYER from GUYTESTER where 1 = 0 
GO 

alter table GUYTRYER  
 Add constraint cx_GUY_PK PRIMARY KEY (PK)
GO 



select DOB, UT.Email as Email, Fname, Lname into #existing 
 from tblUSER UT 
 join LOAD_OF_GUYS L on UT.UserDOB = L.DOB 
   and UT.Email = L.Email 
   and UT.FirstName = L.Fname 
   and UT.LastName = L.Lname 

select DOB, Email, Fname, Lname into #nonexisting 
 from LOAD_OF_GUYS 
 except (select * from #existing)

insert into GUYTESTER (UserDOB, Email, FirstName, LastName)
 select DOB, Email, Fname, Lname from #nonexisting 

GO 


create trigger try_trytry on GUYTRYER 
 after INSERT 
 as BEGIN 
 set NOCOUNT ON
 declare @affected int, @aguy int, @guyDOB date, @guymail varchar(200), @guyFname varchar(25), @guyLname varchar(25)
 select * into #newsies from inserted 
 set @affected = (select Count(PK) from inserted)
 while @affected > 0 
 BEGIN 
 set @aguy = (select Min(PK) from #newsies)
 select @guyDOB = UserDOB, 
   @guyFname = FirstName, 
   @guyLname = LastName, 
   @guymail = Email 
   from inserted where PK = @aguy
 exec dbo.u_NewUser 
  @UserDOB = @guyDOB,
  @Email = @guymail, 
  @FirstName = @guyFname,
  @LastName = @guyLname,
  @UserName = NULL,
  @DisplayName = NULL 
 set @affected = @affected - 1 
 delete from #newsies where PK = @aguy 
 delete from GUYTRYER where PK = @aguy 
 END 
 END 
GO 


select Top(1000) PK into #GuysToTest from GUYTESTER 

insert into GUYTRYER (UserDOB, Email, FirstName, LastName)
 select UserDOB, Email, FirstName, LastName from GUYTESTER 
 where PK in (select PK from #GuysToTest)

delete from GUYTESTER where PK in (select PK from #GuysToTest)

truncate table #GuysToTest 

select Count(PK) from GUYTESTER 

select * from GUYTRYER  
select * from TEST_USER 

