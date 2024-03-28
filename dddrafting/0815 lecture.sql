--analytic functions last lap 
use UNIVERSITY 
GO


with CAE_CTE_CumeExample (CollegeName, StudentID, StudentFname, StudentLname, TotalFeesPaid, CumeDistFees, Tiles, VanillaRanked, DenseRanked)
 as (select CO.CollegeName, S.StudentID, S.StudentFname, S.StudentLname, Sum(RegistrationFee), CUME_DIST() over (partition by CO.CollegeName order by Sum(RegistrationFee)) as CumeDistFees, NTILE(100000) over (partition by CO.CollegeName order by Sum(RegistrationFee) asc), Rank() over (partition by CO.CollegeName order by Sum(RegistrationFee) desc) as VanillaRanked, Dense_Rank() over (partition by CO.CollegeName order by Sum(RegistrationFee) desc) as DenseRanked 
 from tblSTUDENT S 
  join tblCLASS_LIST CL on S.StudentID = CL.StudentID 
  join tblCLASS C on CL.ClassID = C.ClassID 
  join tblCOURSE CR on C.CourseID = CR.CourseID 
  join tblDEPARTMENT D on CR.DeptID = D.DeptID 
  join tblCOLLEGE CO on D.CollegeID = CO.CollegeID 
  where CO.CollegeName = 'Arts and Sciences'
   and YEAR(S.StudentBirth) > 1952
  group by CO.CollegeName, S.StudentID, S.StudentFname, S.StudentLname)

select Top 10 CollegeName, StudentFname, StudentLname, CumeDistFees, /* Cast((CumeDistFees * 100) as numeric(4,2)) as PercentileDist, */ Cast((CumeDistFees * 100) as numeric(5,2)) as FeesTimes100, Cast((Tiles/1000) as numeric(5,2)) as HundredthTiles, VanillaRanked, DenseRanked 
 from CAE_CTE_CumeExample
 where CumeDistFees > 0.75
  and DenseRanked <> VanillaRanked
  and Tiles/1000 <> 70000
 order by CumeDistFees asc  