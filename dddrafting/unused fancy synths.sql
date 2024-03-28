create OR alter proc SYNTH_decking
 as BEGIN 
 declare @PickUser int, @DeckName varchar(200), @HaveProcForThatFormat int, @InFormat varchar(25), @MakeInvalidDeck int 
 set @HaveProcForThatFormat = 1 
 while @HaveProcForThatFormat > 0 
  BEGIN 
  set @InFormat = dbo.getme_randomformatname()
  if @InFormat in ('standard', 'alchemy', 'commander', 'historic', 'historicbrawl')
   set @HaveProcForThatFormat = 0
  END 
 set @MakeInvalidDeck = Floor(Rand() * 69) --zero is invalid, tweak to taste, I'm not writing invalid deck creation yet though
 set @PickUser = dbo.getme_randomuser()
 set @DeckName = dbo.fillin_defaultdeckname(@PickUser)
 END 
GO 

create OR alter proc REPEAT_synth_decking 
 @iterate int 
 as BEGIN 
 while @iterate > 0 
  BEGIN 
   exec dbo.SYNTH_decking 
   set @iterate = @iterate - 1 
  END 
 END 
GO 