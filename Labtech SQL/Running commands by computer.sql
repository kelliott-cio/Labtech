SELECT commands.computerid,
v_computers.computer_name,
v_computers.client_name,
COUNT(*) AS NumOfCommands
FROM   commands
LEFT JOIN v_computers
ON commands.computerid = v_computers.computerid
WHERE  STATUS = 2
GROUP  BY computerid
ORDER  BY numofcommands DESC
