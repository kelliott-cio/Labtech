SELECT 
   computers.computerid as `Computer Id`,
   computers.name as `Computer Name`,
   clients.name as `Client Name`,
   computers.domain as `Computer Domain`,
   computers.username as `Computer User`,
   Locations.Name as `Computer.Location.General.Name`,
   Clients.Name as `Computer.Client.General.Name`,
   Computers.Name as `Computer.General.Name`,
   IFNULL(ROUND(Computers.TotalMemory/1024,0),0) as `Computer.Hardware.MemoryTotal.GB`,
   inv_processor.Cores as `Computer.Processors.Cores`,
   IF((Computers.flags & 2048) <> 0, 1, 0) as `Computer.Hardware.IsVirtual`,
   inv_operatingsystem.name as `Computer.OS.Name`,
   inv_processor.Manufacturer as `Computer.Processors.Manufacturer`,
   IF(INSTR(computers.os, 'server')>0, 1, 0) as `Computer.OS.IsServer`,
   Computers.LastContact as `Computer.LabTech.LastContactDate`
FROM Computers 
LEFT JOIN inv_operatingsystem ON (Computers.ComputerId=inv_operatingsystem.ComputerId)
LEFT JOIN Clients ON (Computers.ClientId=Clients.ClientId)
LEFT JOIN Locations ON (Computers.LocationId=Locations.LocationID)
LEFT JOIN inv_processor ON (inv_processor.ComputerId = Computers.ComputerId AND inv_processor.Enabled = 1)
 WHERE 
((((((Instr(Locations.Name,'Peak 10') > 0) OR (Instr(Clients.Name,'Kablelink') > 0) OR (Instr(Clients.Name,'CIO Tech') > 0))) AND (NOT ((((Instr(Clients.Name,'Crisis Center') > 0) AND (Computers.Name = 'ARGTPAWN-DB-DWH') AND (Instr(Computers.Name,'00lab') > 0))))) AND (IFNULL(ROUND(Computers.TotalMemory/1024,0),0) > 0) AND (inv_processor.Cores > 0) AND (((IF((Computers.flags & 2048) <> 0, 1, 0)<>0) OR (IF((Computers.flags & 2048) <> 0, 1, 0)=0))) AND (((IF((Computers.flags & 2048) <> 0, 1, 0)<>0) OR (IF((Computers.flags & 2048) <> 0, 1, 0)=0))) AND (Instr(inv_operatingsystem.name,'Microsoft') > 0) AND (inv_processor.Manufacturer <> 'kmart') AND (IF(INSTR(computers.os, 'server')>0, 1, 0)<>0) AND (DATE(Computers.LastContact) > DATE('2012/12/03')))))
