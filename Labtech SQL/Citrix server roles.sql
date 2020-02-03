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
   IFNULL(crd1.RoleDefinitionId,0) AS `Windows Citrix Metaframe Server-1`,
   IFNULL(crd2.RoleDefinitionId,0) AS `Windows Citrix XenApp Server-2`
FROM Computers 
LEFT JOIN inv_operatingsystem ON (Computers.ComputerId=inv_operatingsystem.ComputerId)
LEFT JOIN Clients ON (Computers.ClientId=Clients.ClientId)
LEFT JOIN Locations ON (Computers.LocationId=Locations.LocationID)
LEFT JOIN inv_processor ON (inv_processor.ComputerId = Computers.ComputerId AND inv_processor.Enabled = 1)
LEFT JOIN ComputerRoleDefinitions crd1 ON (crd1.ComputerId=Computers.ComputerId AND crd1.RoleDefinitionId=(SELECT RoleDefinitionId FROM RoleDefinitions WHERE RoleDetectionGuid='3806b182-3282-11e3-9392-08002788414b') AND (crd1.Type=1 OR (crd1.CurrentlyDetected=1 AND crd1.Type<>2)))
LEFT JOIN ComputerRoleDefinitions crd2 ON (crd2.ComputerId=Computers.ComputerId AND crd2.RoleDefinitionId=(SELECT RoleDefinitionId FROM RoleDefinitions WHERE RoleDetectionGuid='74b6e541-32a9-11e3-9392-08002788414b') AND (crd2.Type=1 OR (crd2.CurrentlyDetected=1 AND crd2.Type<>2)))
 WHERE 
((((((INSTR(Locations.Name,'Peak 10') > 0) OR (INSTR(Clients.Name,'Kablelink') > 0) OR (INSTR(Clients.Name,'CIO Tech') > 0))) AND (NOT ((((INSTR(Clients.Name,'Crisis Center') > 0) OR (Computers.Name = 'ARGTPAWN-DB-DWH'))))) AND (IFNULL(ROUND(Computers.TotalMemory/1024,0),0) > 0) AND (inv_processor.Cores > 0) AND (((IF((Computers.flags & 2048) <> 0, 1, 0)<>0) OR (IF((Computers.flags & 2048) <> 0, 1, 0)=0))) AND (INSTR(inv_operatingsystem.name,'Microsoft') > 0) AND (inv_processor.Manufacturer <> 'kmart') AND (IF(INSTR(computers.os, 'server')>0, 1, 0)<>0) AND (DATE(Computers.LastContact) > DATE('2012/12/03')) AND (((IFNULL(crd1.RoleDefinitionId,0) >0 ) OR (IFNULL(crd2.RoleDefinitionId,0) >0 ))))))
GROUP BY computers.computerid
ORDER BY `client name`