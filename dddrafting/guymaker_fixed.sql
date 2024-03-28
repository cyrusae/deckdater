--code to create a random username 
set NOCOUNT ON 
declare @UserExists int, @Wordles UserNameGenerator, @Stops UserNameGenerator, @NameString varchar(100), @nwordl int, @nstop int, @wspace int, @stspace int, @unstop int 
declare @StopOrderer as table (
 StopHere int
)
set @UserExists = 1 
while @UserExists > 0 
 BEGIN 
 declare @PK1 int, @PK2 int, @PK3 int, @W1 varchar(10), @W2 varchar(10), @W3 varchar(10)
 exec dbo.get_RandomWordleWord 
  @WordlePK = @PK1 OUT 
 exec dbo.get_RandomWordleWord 
  @WordlePK = @PK2 OUT 
 exec dbo.get_RandomWordleWord 
  @WordlePK = @PK3 OUT 
 set @W1 = Cast(dbo.fetch_WordleByPK(@PK1) as varchar(10))
 set @W2 = Cast(dbo.fetch_WordleByPK(@PK2) as varchar(10))
 set @W3 = Cast(dbo.fetch_WordleByPK(@PK3) as varchar(10))
 insert into @Wordles (WordOrder, Word) VALUES (2, @W1), (4, @W2), (6, @W3)
 set @nstop = Floor(Rand() * 5)
 declare @SK1 int, @SK2 int, @SK3 int, @SK4 int, @S1 varchar(10), @S2 varchar(10), @S3 varchar(10), @S4 varchar(10)
 exec dbo.get_RandomStopWord 
  @StopPK = @SK1 OUT 
 exec dbo.get_RandomStopWord 
  @StopPK = @SK2 OUT 
 exec dbo.get_RandomStopWord 
  @StopPK = @SK3 OUT 
 exec dbo.get_RandomStopWord 
  @StopPK = @SK4 OUT 
 set @S1 = dbo.fetch_StopByPK(@SK1)
 set @S2 = dbo.fetch_StopByPK(@SK2)
 set @S3 = dbo.fetch_StopByPK(@SK3)
 set @S4 = dbo.fetch_StopByPK(@SK4)
 insert into @Stops (WordOrder, Word)
  VALUES (1, @S1), (3, @S2), (5, @S3), (7, @S4)
 delete from @Stops 
  where WordOrder in (select WordOrder
   from @Stops 
   order by NewID()
   offset 0 rows
   fetch next @nstop rows only)
 insert into @Wordles (WordOrder, Word) 
  select WordOrder, Word from @Stops
 set @NameString = (select STRING_AGG(Word, '') from @Wordles)
 set @UserExists = (select Count(UserID) from tblUSER 
  where UserName = @NameString)
 END 
print @NameString 