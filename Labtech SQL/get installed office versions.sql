SELECT 
   computers.computerid AS `Computer Id`,
   computers.name AS `Computer Name`,
   clients.name AS `Client Name`,
   computers.domain AS `Computer Domain`,
   computers.username AS `Computer User`,
   Locations.Name AS `Computer.Location.General.Name`,
   Clients.Name AS `Computer.Client.General.Name`,
   Computers.Name AS `Computer.General.Name`,
   IFNULL(ROUND(Computers.TotalMemory/1024,0),0) AS `Computer.Hardware.MemoryTotal.GB`,
   SUM(inv_processor.Cores) AS `Computer.Processors.Cores.Total`,
   COUNT(inv_processor.cores) AS `Computer.Processors.Sockets`,
   IF((Computers.flags & 2048) <> 0, 1, 0) AS `Computer.Hardware.IsVirtual`,
   inv_operatingsystem.name AS `Computer.OS.Name`,
   inv_processor.Manufacturer AS `Computer.Processors.Manufacturer`,
   IF(INSTR(computers.os, 'server')>0, 1, 0) AS `Computer.OS.IsServer`,
   Computers.LastContact AS `Computer.LabTech.LastContactDate`,
   Software.Name AS `Computer.Applications.Name`
FROM Computers 
LEFT JOIN inv_operatingsystem ON (Computers.ComputerId=inv_operatingsystem.ComputerId)
LEFT JOIN Clients ON (Computers.ClientId=Clients.ClientId)
LEFT JOIN Locations ON (Computers.LocationId=Locations.LocationID)
LEFT JOIN inv_processor ON (inv_processor.ComputerId = Computers.ComputerId AND inv_processor.Enabled = 1)
LEFT JOIN Software ON (Software.ComputerId = Computers.ComputerId)
 WHERE 
(((((
(INSTR(Locations.Name,'Peak 10') > 0) 
OR (INSTR(Clients.Name,'Kablelink') > 0) 
OR (INSTR(Clients.Name,'CIO Tech') > 0))) 
AND 
(NOT ((((INSTR(Clients.Name,'Crisis Center') > 0) 
OR (Computers.Name = 'ARGTPAWN-DB-DWH'))))) 
AND (IFNULL(ROUND(Computers.TotalMemory/1024,0),0) > 0) 
AND (inv_processor.Cores > 0) 
AND (((IF((Computers.flags & 2048) <> 0, 1, 0)<>0) 
OR (IF((Computers.flags & 2048) <> 0, 1, 0)=0))) 
AND (((IF((Computers.flags & 2048) <> 0, 1, 0)<>0) 
OR (IF((Computers.flags & 2048) <> 0, 1, 0)=0))) 
AND (INSTR(inv_operatingsystem.name,'Microsoft') > 0) 
AND (inv_processor.Manufacturer <> 'kmart') 
AND (IF(INSTR(computers.os, 'server')>0, 1, 0)<>0) 
AND (DATE(Computers.LastContact) > DATE('2012/12/03')) 
AND (((((SELECT COUNT(*) FROM Software WHERE Software.ComputerId = Computers.ComputerId  
AND INSTR(Software.Name,'Microsoft Office Standard') > 0)>0)) 
OR (((SELECT COUNT(*) FROM Software WHERE Software.ComputerId = Computers.ComputerId  
AND INSTR(Software.Name,'Microsoft Office 365') > 0)>0)) 
OR (((SELECT COUNT(*) FROM Software WHERE Software.ComputerId = Computers.ComputerId  
AND INSTR(Software.Name,'Microsoft Office Pro') > 0)>0)) 
OR (((SELECT COUNT(*) FROM Software WHERE Software.ComputerId = Computers.ComputerId  
AND INSTR(Software.Name,'Microsoft Office XP') > 0)>0)) 
OR (((SELECT COUNT(*) FROM Software WHERE Software.ComputerId = Computers.ComputerId  
AND INSTR(Software.Name,'Microsoft Office Home') > 0)>0)))) 
AND (((INSTR(Software.Name,'Microsoft Office Standard') > 0) 
OR (INSTR(Software.Name,'Microsoft Office 365') > 0) 
OR (INSTR(Software.Name,'Microsoft Office Pro') > 0) 
OR (INSTR(Software.Name,'Microsoft Office XP') > 0)
OR (INSTR(Software.Name,'Microsoft Office Home') > 0))))))
GROUP BY computers.computerid
ORDER BY `client name`