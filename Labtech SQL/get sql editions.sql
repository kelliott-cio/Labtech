SELECT 		
   computers.computerid AS `Computer Id`,		
   computers.name AS `Computer Name`,		
   clients.name AS `Client Name`,		
   computers.domain AS `Computer Domain`,		
   IFNULL(IFNULL(edfAssigned1.Value,edfDefault1.value),'') AS `Computer - Extra Data Field - SQL - SQL Editions found`,		
   Locations.Name AS `Computer.Location.General.Name`,		
   IFNULL(ROUND(Computers.TotalMemory/1024,0),0) AS `Computer.Hardware.MemoryTotal.GB`,		
   SUM(inv_processor.Cores) AS `Computer.Processors.Cores.Total`,		
   COUNT(inv_processor.cores) AS `Computer.Processors.Sockets`,		
   IF((Computers.flags & 2048) <> 0, 1, 0) AS `Computer.Hardware.IsVirtual`,		
   inv_operatingsystem.name AS `Computer.OS.Name`,		
   inv_processor.Manufacturer AS `Computer.Processors.Manufacturer`		
FROM Computers 		
LEFT JOIN inv_operatingsystem ON (Computers.ComputerId=inv_operatingsystem.ComputerId)		
LEFT JOIN Clients ON (Computers.ClientId=Clients.ClientId)		
LEFT JOIN Locations ON (Computers.LocationId=Locations.LocationID)		
LEFT JOIN ExtraFieldData edfAssigned1 ON (edfAssigned1.id=Computers.ComputerId AND edfAssigned1.ExtraFieldId =(SELECT ExtraField.id FROM ExtraField WHERE LTGuid='99e011f7-4e75-4033-b1fe-84633ff095eb'))		
LEFT JOIN ExtraFieldData edfDefault1 ON (edfDefault1.id=0 AND edfDefault1.ExtraFieldId =(SELECT ExtraField.id FROM ExtraField WHERE LTGuid='99e011f7-4e75-4033-b1fe-84633ff095eb'))		
LEFT JOIN inv_processor ON (inv_processor.ComputerId = Computers.ComputerId AND inv_processor.Enabled = 1)		
 WHERE 		
((((NOT 		
	((((INSTR(IFNULL(IFNULL(	
		edfAssigned1.Value,edfDefault1.value),''),'cannot find path') > 0) 
		OR (INSTR(IFNULL(IFNULL(edfAssigned1.Value,edfDefault1.value),''),'is not recognized as') > 0) 
		OR (INSTR(IFNULL(IFNULL(edfAssigned1.Value,edfDefault1.value),''),'cannot find path') > 0))))) 
		AND (NOT ((INSTR(IFNULL(IFNULL(edfAssigned1.Value,edfDefault1.value),''),'OK') > 0))) 
		AND (IFNULL(IFNULL(edfAssigned1.Value,edfDefault1.value),'') <> '\'\'') 
		AND (IFNULL(IFNULL(edfAssigned1.Value,edfDefault1.value),'') <> '') 
		AND (((INSTR(Locations.Name,'Peak 10') > 0) OR (INSTR(Clients.Name,'Kablelink') > 0) 
		OR (INSTR(Clients.Name,'CIO Tech') > 0))) 
		AND (NOT ((((INSTR(Clients.Name,'Crisis Center') > 0))))) 
		AND (IFNULL(ROUND(Computers.TotalMemory/1024,0),0) > 0) 
		AND (inv_processor.Cores > 0) 
		AND (((IF((Computers.flags & 2048) <> 0, 1, 0)<>0) 
		OR (IF((Computers.flags & 2048) <> 0, 1, 0)=0))) 
--		AND (((INSTR(IFNULL(IFNULL(edfAssigned1.Value,edfDefault1.value),''),'Enterprise') > 0) 
--		OR (INSTR(IFNULL(IFNULL(edfAssigned1.Value,edfDefault1.value),''),'Standard') > 0)
--		OR (INSTR(IFNULL(IFNULL(edfAssigned1.Value,edfDefault1.value),''),'Express') > 0))) 
		AND (((IF((Computers.flags & 2048) <> 0, 1, 0)<>0) OR (IF((Computers.flags & 2048) <> 0, 1, 0)=0))) 
		AND (INSTR(inv_operatingsystem.name,'Microsoft') > 0) 
		AND (inv_processor.Manufacturer <> 'Null data'))))
GROUP BY computers.computerid		
