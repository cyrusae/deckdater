use Info_430_deckdater
GO 

select CardID, BeginDate,  
 CASE when EndDate is NOT NULL then EndDate 
  ELSE Cast(GetDate() as date) END as LastMeasureDate, CASE 
 when EndDate is NULL 
  then DateDiff(day, BeginDate, Cast(GetDate() as date))
  ELSE DateDiff(day, BeginDate, EndDate) END 
  as ElapsedDaysTotal,
 CASE 
  when (DateDiff(day, BeginDate, GetDate()) < 0) then 'Future' 
  when EndDate is NULL then 'Current' 
  ELSE 'Past' END as HapaxStatus
 into #HapaxAudit
 from tblCARD_HAPAX 
 order by BeginDate desc 
