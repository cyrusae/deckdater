--drop-in error handling 

--Deck ID by name 
 if @RET is NULL 
  BEGIN 
   print 'Deck ID not found. Check spelling and uniqueness';
   throw 93845, 'DeckID lookup requires unique username and deck name. Check inputs', 14;
  END 

--User ID by name 
 if @RET is null 
  BEGIN 
   print 'User ID not found. Check spelling and uniqueness';
   throw 93846, 'UserID lookup requires unique username and deck name. Check inputs', 14;
  END 