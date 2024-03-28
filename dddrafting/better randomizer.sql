--drop table #tmp 

create table #tmp (
 PK int Identity(1,1) primary key NOT NULL,
 Word varchar(10),
 LoopsTaken int,
 MiniUsed int, 
 MaxiUsed int)


truncate table #tmp 
--drop table #repeats 

declare @nrow int, @maxi int, @mini int, @spacey1 int, @spacey2 int, @loopy int, @loopsed int, @testloops int 
set @testloops = 3
select @nrow = nrow, 
  @mini = smallest, 
  @maxi = biggest 
  from META_ENV_VAR where NameOfTable = 'UN_Wordle'

--drop table #tmp 

set NOCOUNT ON 
while @testloops > 0 
BEGIN 
set @loopy = 1
set @loopsed = 1 
while @loopy > 0 
BEGIN 
--set @spacey1 = @mini + Floor(Rand() * @nrow)
set @spacey2 = Floor(Rand() * @maxi) + 1
/*if (@spacey1 - @spacey2) > 1 
 BEGIN 
  set @spacey1 = @nrow - @spacey2 
 END */
if @loopsed = 1 and exists (select PK from #tmp where MaxiUsed = @spacey2)
 BEGIN 
 set @loopsed = 2
 END 
ELSE if exists (select Word from UN_Wordle where PK = /*between @spacey1 and */ @spacey2) 
 BEGIN 
 insert into #tmp (Word, LoopsTaken, MiniUsed, MaxiUsed)
  select Word, @loopsed as LoopsTaken, @mini as MiniUsed, @spacey2 as MaxiUsed from UN_Wordle where PK = @spacey2
 set @loopy = 0 
 END
ELSE 
 BEGIN 
 set @loopsed = @loopsed + 1
 END
END 
set @testloops = @testloops - 1
END 
select * from #tmp 

--select * from #tmp order by LoopsTaken desc 

select Count(Word), Count(distinct Word) from #tmp 

select Word into #repeats from #tmp group by Word having Count(PK) > 1

select * from #tmp where Word in (select Word from #repeats)

select Top 5 * from #tmp order by MaxiUsed desc 

select Top 5 * from #tmp order by MiniUsed asc 

select * from UN_Wordle where Word not in (select Word from #tmp)

GO 


declare @nrow int, @maxi int, @mini int, @spacey1 int, @spacey2 int, @loopy int, @loopsed int, @testloops int 
set @testloops = 3
select @nrow = nrow, 
  @mini = smallest, 
  @maxi = biggest 
  from META_ENV_VAR where NameOfTable = 'UN_Wordle'
set @spacey1 = Floor(Rand() * @maxi)
print @spacey1 
set @spacey2 = @mini + Floor(Rand() * @nrow)
print @spacey2
GO 

