use deckdater_dev 

create table defRARITY (
 RarityID int Identity(1,1) primary key NOT NULL,
 RarityName varchar(25) unique NOT NULL,
 RarityDesc varchar(500) NULL)