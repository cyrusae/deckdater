use deckdater_dev
GO 

create table META_ENV_VAR (
 PK int Identity(1,1) primary key NOT NULL,
 NameOfTable nvarchar(50) unique NOT NULL, 
 IndexedOn nvarchar(50) NOT NULL,
 nrow int,
 smallest int, 
 biggest int)
GO 

create OR alter proc GET_RANDOM_ROW 
 @FromTable nvarchar(50),
 @randro int OUT 
 as BEGIN 
  declare @SQLstring nvarchar(1000), @ParmDefinition nvarchar(50), @pkol nvarchar(50), @nrow int, @smol int, @big int, @loop int, @attempt int, @coin int, @head int, @tail int 
  set @loop = 1 
  set @ParmDefinition = N'@trial int, @found int OUT'
  select @pkol = IndexedOn, 
   @nrow = nrow, 
   @smol = smallest,
   @big = biggest 
   from META_ENV_VAR 
    where NameOfTable = @FromTable
  set @SQLstring = 'set @found = (select ' 
     + @pkol + ' from ' 
     + @FromTable + ' where ' 
     + @pkol + ' = @trial)'
  while @loop > 0 
  BEGIN 
   set @head = Ceiling(Rand() * @big)
   set @tail = @smol + Floor(Rand() * @nrow)
   set @coin = Floor(Rand() * 2)
   if @coin > 0 
    set @attempt = @head 
   ELSE set @attempt = @tail 
   EXEC sp_executesql @SQLstring,
     @ParmDefinition,
     @trial = @attempt,
     @found = @randro OUT 
   if @randro is NULL 
    set @loop = @loop + 1
    if @loop > 100 
     BREAK 
   ELSE set @loop = 0
  END 
 END 
GO 

create OR alter proc ENV_VAR_ColFunctions 
 @UseTable nvarchar(50),
 @UseColumn nvarchar(50),
 @UseFunction nvarchar(10),
 @res int OUT 
 as BEGIN 
 declare @SQLstring nvarchar(1000), @ParmString nvarchar(100)
 set @SQLstring = 'set @checked = (select '
   + @UseFunction + '(' + @UseColumn + ') from ' + @UseTable + ')'
 set @ParmString = N'@checked int OUT'
 EXEC sp_executesql @SQLstring, 
   @ParmString, @checked = @res OUT 
 END 
GO 

create OR alter proc ENV_VAR_UPD8 
 @ForTable nvarchar(50)
 as BEGIN 
 declare @pkol nvarchar(50), @nrow int, @minrow int, @maxrow int, @SQLcheck nvarchar(1000), @ParmCheck nvarchar(100)
 set @pkol = (select IndexedOn from META_ENV_VAR where NameOfTable = @ForTable)
 exec dbo.ENV_VAR_ColFunctions 
  @UseTable = @ForTable,
  @UseColumn = @pkol,
  @UseFunction = N'Count',
  @res = @nrow OUT 
 exec dbo.ENV_VAR_ColFunctions
  @UseTable = @ForTable,
  @UseColumn = @pkol, 
  @UseFunction = N'Max',
  @res = @maxrow OUT 
 exec dbo.ENV_VAR_ColFunctions 
  @UseTable = @ForTable, 
  @UseColumn = @pkol, 
  @UseFunction = N'Min',
  @res = @minrow OUT 
 if (@nrow is NOT NULL) and (@minrow is NOT NULL) and (@maxrow is NOT NULL)
  update META_ENV_VAR 
   set nrow = @nrow,
     biggest = @maxrow,
     smallest = @minrow
    where NameOfTable = @ForTable
 END 
GO 

/*
insert into META_ENV_VAR (NameOfTable, IndexedOn, nrow, smallest, biggest)
 VALUES(N'UN_StopWord', N'PK', 0, 0, 0), (N'UN_Wordle', N'PK', 0, 0, 0), (N'tblUSER', N'UserID', 0, 0, 0)
GO 

select * from META_ENV_VAR

declare @stoppy nvarchar(50)
set @stoppy = N'UN_StopWord'
exec dbo.ENV_VAR_UPD8 N'tblUSER'

GO 

declare @pkol nvarchar(50), @nrow int, @minrow int, @maxrow int, @SQLcheck nvarchar(1000), @ParmCheck nvarchar(100), @ForTable nvarchar(50)
 set @ForTable = 'UN_StopWord'
 set @pkol = (select IndexedOn from META_ENV_VAR where NameOfTable = 'UN_StopWord')
 exec dbo.ENV_VAR_ColFunctions 
  @UseTable = @ForTable,
  @UseColumn = @pkol,
  @UseFunction = N'Count',
  @res = @nrow OUT 
 exec dbo.ENV_VAR_ColFunctions
  @UseTable = @ForTable,
  @UseColumn = @pkol, 
  @UseFunction = N'Max',
  @res = @maxrow OUT 
 exec dbo.ENV_VAR_ColFunctions 
  @UseTable = @ForTable, 
  @UseColumn = @pkol, 
  @UseFunction = N'Min',
  @res = @minrow OUT 
 if (@nrow is NOT NULL) and (@minrow is NOT NULL) and (@maxrow is NOT NULL)
  update META_ENV_VAR 
   set nrow = @nrow,
     biggest = @maxrow,
     smallest = @minrow
    where NameOfTable = @ForTable

select * from META_ENV_VAR

/*
insert into META_ENV_VAR (NameOfTable, IndexedOn, nrow, smallest, biggest)
 VALUES(N'tblDECK', N'DeckID', 0, 0, 0), (N'tblDECK_FORMAT', N'DeckID', 0, 0, 0), (N'tblCARD', N'CardCount', 0, 0, 0), (N'tblCARD_FACE', N'CardFaceID', 0, 0, 0), (N'tblCARD_FACE_SET', N'CardFaceSetID', 0, 0, 0), (N'tblSET', N'SetCount', 0, 0, 0) */

create OR alter proc ENV_VAR_UPD8_MASS 
 as BEGIN 
 declare @Tab nvarchar(50), @rowboat int, @oar int 
 set @rowboat = (select Count(PK) from META_ENV_VAR)
 while @rowboat > 0
  BEGIN
   set @oar = (select Min(PK) from META_ENV_VAR)
   set @Tab = (select NameOfTable from META_ENV_VAR where PK = @oar)
   exec dbo.ENV_VAR_UPD8 @Tab 
   set @rowboat = @rowboat - 1 
  END 
 END 
GO 

declare @wordy int 
exec dbo.GET_RANDOM_ROW N'UN_Wordle', @wordy OUT 
select Word from UN_Wordle where PK = @wordy 

exec dbo.ENV_VAR_UPD8_MASS