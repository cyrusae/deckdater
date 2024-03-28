select Top(500) * into #tempguys from LOAD_OF_GUYS 

select Top(50) * into #temperguys from #tempguys 

select * into #tempestguys 
 from #tempguys 
 except select * from #temperguys 

drop table #temperguys 
drop table #tempguys 
select * into #tempguys from #tempestguys 
drop table #tempestguys 

drop table #tempguys 