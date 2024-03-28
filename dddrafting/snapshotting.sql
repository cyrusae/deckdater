sp_who2

alter database deckdater_dev SET SINGLE_USER 


alter database deckdater_dev set ALLOW_SNAPSHOT_ISOLATION ON 

alter database deckdater_dev set READ_COMMITTED_SNAPSHOT ON 

SELECT is_read_committed_snapshot_on FROM sys.databases WHERE name= 'deckdater_dev'

alter database deckdater_dev set MULTI_USER 