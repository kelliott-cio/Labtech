UPDATE Dataviews SET columnlist=IF(LOCATE('Ticket External ID',columnlist)>0,columnlist,REPLACE(columnlist,',Ticket ID,',',Ticket ID,Ticket External ID,')), fieldlist=REPLACE(fieldlist,'tickets.TicketID as ','tickets.externalid as `Ticket External ID`,tickets.TicketID as ') WHERE fieldlist LIKE '%tickets.TicketID as %' AND NOT fieldlist LIKE '%tickets.\`externalid\`%';