/*
create type Unlisted as table (
 PK int Identity(1,1) primary key NONCLUSTERED NOT NULL,
 Item varchar(500))
  with (MEMORY_OPTIMIZED = ON);

create OR alter function fn_UnList (@ListString varchar(8000), @sep char(1))
 returns @RET table (
  Item varchar(500)
 )
 as BEGIN 
 declare @filter table (Item varchar(500))
 insert into @filter (Item)
  select value as Item from STRING_SPLIT(@ListString, @sep)
 insert into @RET (Item)
  select Item from @filter
 return 
 END 
GO 

declare @thing table (Item varchar(500))
insert into @thing (Item)
 select Item from dbo.fn_UnList('Thing,Thing,Thing', ',')
select * from @thing