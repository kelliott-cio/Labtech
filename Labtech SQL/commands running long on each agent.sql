SELECT commands.computerid, computers.`LastContact`, commands.command, commands.`DateUpdated` FROM commands JOIN computers ON commands.`ComputerID` = computers.computerid WHERE computers.`LastContact`< DATE_SUB(NOW(),INTERVAL -10 MINUTE)AND commands.status=2;
