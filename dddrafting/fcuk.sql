select FormatID, FormatNameMachineReadable from refFORMAT F 
 join defFORMAT_NAME FN on F.FormatNameID = FN.FormatNameID

select UserID, UserName from tblUSER where UserName = 'Emperor'

select C.CardID, CF.CardFaceSearchName, CF.LayoutFaceID, Count(CF.CardFaceID) from tblCARD_FACE CF 
 join tblCARD C on CF.CardID = C.CardID 
 group by C.CardID, CF.CardFaceSearchName, CF.LayoutFaceID
 having Count(CardFaceID) > 1



exec dbo.ADD_NewDeck 
 @ForUserName = 'Emperor', 
 @InFormatID = 6,
 @DeckNameString = 'warmer than wine', 
 @WithMaindeck = 'Ancient Ziggurat|Anointed Procession|Arcane Signet|Black Market|Blood Artist|Bloodcrazed Paladin|Bloodline Keeper|Bojuka Bog|Boros Charm|Boros Garrison|Brightclimb Pathway|Captivating Vampire|Cathars Crusade|Chance for Glory|Coat of Arms|Command Tower|Cordial Vampire|Cruel Celebrant|Dark Impostor|Darksteel Ingot|Door of Destinies|Drana Liberator of Malakir|Drana the Last Bloodchief|Dusk|Dawn|Evolving Wilds|Exquisite Blood|Falkenrath Gorger|Feed the Swarm|Force of Despair|Go for the Throat|Guul Draz Assassin|Heralds Horn|Indulgent Aristocrat|Indulging Patrician|Isolated Chapel|Kalastria Highborn|Kindred Charge|Knight of the Ebon Legion|Legions Landing|Luxury Suite|Malakir Rebirth|Mathas Fiend Seeker|Merciless Eviction|Metallic Mimic|Mountain|Mountain|Mountain|New Blood|Nighthawk Scavenger|Nomad Outpost|Nullpriest of Oblivion|Obelisk of Urd|Olivia Mobilized for War|Opal Palace|Orzhov Basilica|Path of Ancestry|Pawn of Ulamog|Pillar of Origins|Plains|Plains|Plains|Rakdos Carnarium|Rakdos Signet|Reliquary Tower|Return to Dust|Savai Triome|Shadow Alley Denizen|Skullclamp|Slate of Ancestry|Smoldering Marsh|Smothering Tithe|Sol Ring|Sorin Lord of Innistrad|Sorin Solemn Visitor|Spark Harvest|Stensia Masquerade|Stromkirk Captain|Swamp|Swamp|Swamp|Swamp|Swamp|Swamp|Swords to Plowshares|Teferis Protection|Temple of the False God|Terramorphic Expanse|Thriving Bluff|Thriving Heath|Thriving Moor|Twilight Prophet|Unclaimed Territory|Valakut Awakening|Vampire Nocturnus|Vances Blasting Cannons|Vanquishers Banner|Vault of Champions|Vito Thorn of the Dusk Rose|Yahenni Undying Partisan',
 @WithCMDR = 'Edgar Markov', 
 @WithSIDE = NULL,
 @WithMAYB = NULL,
 @WithWISH = NULL,
 @IsPrivate = NULL 


/* create OR alter proc ADD_NewDeck 


 @ForUserName varchar(100),
 @InFormatID int NULL,
 @DeckNameString varchar(280) NULL,
 @WithMaindeck varchar(8000),
 @WithCMDR varchar(8000) NULL,
 @WithSIDE varchar(8000) NULL, 
 @WithMAYB varchar(8000) NULL,
 @WithWISH varchar(8000) NULL,
 @IsPrivate char(1) NULL */