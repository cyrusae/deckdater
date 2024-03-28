--code to create a random username 
declare @UserExists int, @Wordles UserNameGenerator, @NameString varchar(100), @nwordl int, @nstop int, @wspace int, @stspace int, @S_PK int, @S varchar(10), @unstop int 
declare @StopOrderer as table (
 StopHere int
)
set @UserExists = 1 
while @UserExists > 0 
 BEGIN 
 set @nwordl = Floor(Rand() * 3) + 1
 set @wspace = 6
 print @nwordl 
 while @nwordl > 0 
  BEGIN 
   declare @W_PK int, @W char(5)
   exec dbo.get_RandomWordleWord 
    @WordlePK = @W_PK OUT 
   set @W = dbo.fetch_WordleByPK(@W_PK)
   insert into @Wordles (WordOrder, Word) VALUES (@wspace, @W)
   set @wspace = @wspace - 2
   set @nwordl = @nwordl - 1
  END 
 if (select Count(WordOrder) from @Wordles) < 3 
  BEGIN 
   while @wspace > 0 
    BEGIN 
     set @W = (select Top(1) Word from @Wordles)
     insert into @Wordles (WordOrder, Word) VALUES (@wspace, @W)
     set @wspace = @wspace - 2
    END 
  END
 set @nstop = Floor(Rand() * 5)
 print @nstop 
 insert into @StopOrderer(StopHere) VALUES(1), (3), (5), (7)
 if (@nstop between 1 and 3)
  BEGIN 
   set @unstop = 4 - @nstop 
   delete from @StopOrderer 
    where StopHere in (select StopHere from @StopOrderer
     order by NewID()
     offset 0 rows
     fetch next @unstop rows only)
  END 
 while @nstop > 0 
  BEGIN 
   set @stspace = (select Top(1) StopHere from @StopOrderer)
   exec dbo.get_RandomStopWord 
    @StopPK = @S_PK OUT
   set @S = dbo.fetch_StopByPK(@S_PK)
   insert into @Wordles (WordOrder, Word) VALUES (@stspace, @S)
   delete from @StopOrderer where StopHere = @stspace
   set @nstop = @nstop - 1 
  END 
 delete from @StopOrderer 
 set @NameString = (select STRING_AGG(Word, '') from @Wordles)
 set @UserExists = (select Count(UserID) from tblUSER 
  where UserName = @NameString)
 print @UserExists 
 END 
print @NameString 