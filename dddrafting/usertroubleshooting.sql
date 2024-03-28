 declare @nrow int, @off int 
 set @nrow = (select Count(PK) from UN_Wordle)
   set @off = Floor(Rand() * @nrow)
   select PK from UN_Wordle
    order by PK 
    offset @off rows 
    fetch next 1 rows only


select * from GUYTRYER 

select Count(UserID) as Users, Count(Email) as Emails, Count(distinct Email) as DistinctEmails from tblUSER 


select * from GUYTRYER 

select Email, Count(UserID) from tblUSER 
 group by Email 
 having Count(UserID) > 1

with TwoNames (FirstName, LastName, Dudes) as (select FirstName, LastName, Count(UserID) as Dudes from tblUSER 
 group by FirstName, LastName
 having Count(UserID) > 1 )

select Email into #manymail from tblUSER U 
 join TwoNames T on U.FirstName = T.FirstName 
   and U.LastName = T.LastName 
 group by Email 
 having Count(UserID) > 1 ;

select * from tblUSER where Email in (select Email from #manymail)
 order by Email, UserDOB 

select * into #dupes from tblUSER where IsInactive is NOT NULL 

select * from tblUSER 
 where IsInactive IS NULL 
  and Email in (select Email from #dupes)

select * from tblUSER where Email = 'NULL' 


select * from tblUSER U 
 join #dupes D on U.FirstName = D.FirstName 
   and U.LastName = D.LastName 
  

update tblUSER 
 set Email = NULL, 
   IsInactive = NULL 
   where Email = 'NULL'


select * from tblUSER where Email is NULL and DateUpdated is NULL  

select Top 15 * from tblUSER order by DateCreated desc 