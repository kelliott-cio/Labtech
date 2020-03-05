SELECT  computers.computerid                                    AS `Computer Id`
       ,computers.name                                          AS `Computer Name`
       ,clients.name                                            AS `Client Name`
       ,computers.domain                                        AS `Computer Domain`
       ,computers.username                                      AS `Computer User`
       ,IFNULL(IFNULL(edfAssigned1.Value,edfDefault1.value),'') AS `Computer - Extra Data Field - SQL - SQL Editions found`
       ,IFNULL(IFNULL(edfAssigned2.Value,edfDefault2.value),'') AS `Computer - Extra Data Field - SQL - SQL Editions found`
       ,IFNULL(IFNULL(edfAssigned3.Value,edfDefault3.value),'') AS `Computer - Extra Data Field - SQL - SQL Editions found`
       ,IFNULL(IFNULL(edfAssigned4.Value,edfDefault4.value),'') AS `Computer - Extra Data Field - SQL - SQL Editions found`
       ,IFNULL(IFNULL(edfAssigned5.Value,edfDefault5.value),'') AS `Computer - Extra Data Field - SQL - SQL Editions found`
       ,IFNULL(IFNULL(edfAssigned6.Value,edfDefault6.value),'') AS `Computer - Extra Data Field - SQL - SQL Editions found`
       ,Locations.Name                                          AS `Computer.Location.General.Name`
       ,Clients.Name                                            AS `Computer.Client.General.Name`
       ,Computers.Name                                          AS `Computer.General.Name`
       ,IFNULL(ROUND(Computers.TotalMemory/1024,0),0)           AS `Computer.Hardware.MemoryTotal.GB`
       ,SUM(inv_processor.Cores)                                AS `Computer.Processors.Cores.Total`
       ,COUNT(inv_processor.cores)                              AS `Computer.Processors.Sockets`
       ,IF((Computers.flags & 2048) <> 0,1,0)                   AS `Computer.Hardware.IsVirtual`
       ,IFNULL(IFNULL(edfAssigned7.Value,edfDefault7.value),'') AS `Computer - Extra Data Field - SQL - SQL Editions found`
       ,IFNULL(IFNULL(edfAssigned8.Value,edfDefault8.value),'') AS `Computer - Extra Data Field - SQL - SQL Editions found`
       ,inv_operatingsystem.name                                AS `Computer.OS.Name`
       ,inv_processor.Manufacturer                              AS `Computer.Processors.Manufacturer`
FROM Computers
LEFT JOIN inv_operatingsystem
ON (Computers.ComputerId=inv_operatingsystem.ComputerId)
LEFT JOIN Clients
ON (Computers.ClientId=Clients.ClientId)
LEFT JOIN Locations
ON (Computers.LocationId=Locations.LocationID)
LEFT JOIN ExtraFieldData edfAssigned1
ON (edfAssigned1.id=Computers.ComputerId AND edfAssigned1.ExtraFieldId =(
SELECT  ExtraField.id
FROM ExtraField
WHERE LTGuid='99e011f7-4e75-4033-b1fe-84633ff095eb')) 
LEFT JOIN ExtraFieldData edfDefault1
ON (edfDefault1.id=0 AND edfDefault1.ExtraFieldId =(
SELECT  ExtraField.id
FROM ExtraField
WHERE LTGuid='99e011f7-4e75-4033-b1fe-84633ff095eb')) 
LEFT JOIN ExtraFieldData edfAssigned2
ON (edfAssigned2.id=Computers.ComputerId AND edfAssigned2.ExtraFieldId =(
SELECT  ExtraField.id
FROM ExtraField
WHERE LTGuid='99e011f7-4e75-4033-b1fe-84633ff095eb')) 
LEFT JOIN ExtraFieldData edfDefault2
ON (edfDefault2.id=0 AND edfDefault2.ExtraFieldId =(
SELECT  ExtraField.id
FROM ExtraField
WHERE LTGuid='99e011f7-4e75-4033-b1fe-84633ff095eb')) 
LEFT JOIN ExtraFieldData edfAssigned3
ON (edfAssigned3.id=Computers.ComputerId AND edfAssigned3.ExtraFieldId =(
SELECT  ExtraField.id
FROM ExtraField
WHERE LTGuid='99e011f7-4e75-4033-b1fe-84633ff095eb')) 
LEFT JOIN ExtraFieldData edfDefault3
ON (edfDefault3.id=0 AND edfDefault3.ExtraFieldId =(
SELECT  ExtraField.id
FROM ExtraField
WHERE LTGuid='99e011f7-4e75-4033-b1fe-84633ff095eb')) 
LEFT JOIN ExtraFieldData edfAssigned4
ON (edfAssigned4.id=Computers.ComputerId AND edfAssigned4.ExtraFieldId =(
SELECT  ExtraField.id
FROM ExtraField
WHERE LTGuid='99e011f7-4e75-4033-b1fe-84633ff095eb')) 
LEFT JOIN ExtraFieldData edfDefault4
ON (edfDefault4.id=0 AND edfDefault4.ExtraFieldId =(
SELECT  ExtraField.id
FROM ExtraField
WHERE LTGuid='99e011f7-4e75-4033-b1fe-84633ff095eb')) 
LEFT JOIN ExtraFieldData edfAssigned5
ON (edfAssigned5.id=Computers.ComputerId AND edfAssigned5.ExtraFieldId =(
SELECT  ExtraField.id
FROM ExtraField
WHERE LTGuid='99e011f7-4e75-4033-b1fe-84633ff095eb')) 
LEFT JOIN ExtraFieldData edfDefault5
ON (edfDefault5.id=0 AND edfDefault5.ExtraFieldId =(
SELECT  ExtraField.id
FROM ExtraField
WHERE LTGuid='99e011f7-4e75-4033-b1fe-84633ff095eb')) 
LEFT JOIN ExtraFieldData edfAssigned6
ON (edfAssigned6.id=Computers.ComputerId AND edfAssigned6.ExtraFieldId =(
SELECT  ExtraField.id
FROM ExtraField
WHERE LTGuid='99e011f7-4e75-4033-b1fe-84633ff095eb')) 
LEFT JOIN ExtraFieldData edfDefault6
ON (edfDefault6.id=0 AND edfDefault6.ExtraFieldId =(
SELECT  ExtraField.id
FROM ExtraField
WHERE LTGuid='99e011f7-4e75-4033-b1fe-84633ff095eb')) 
LEFT JOIN inv_processor
ON (inv_processor.ComputerId = Computers.ComputerId AND inv_processor.Enabled = 1)
LEFT JOIN ExtraFieldData edfAssigned7
ON (edfAssigned7.id=Computers.ComputerId AND edfAssigned7.ExtraFieldId =(
SELECT  ExtraField.id
FROM ExtraField
WHERE LTGuid='99e011f7-4e75-4033-b1fe-84633ff095eb')) 
LEFT JOIN ExtraFieldData edfDefault7
ON (edfDefault7.id=0 AND edfDefault7.ExtraFieldId =(
SELECT  ExtraField.id
FROM ExtraField
WHERE LTGuid='99e011f7-4e75-4033-b1fe-84633ff095eb')) 
LEFT JOIN ExtraFieldData edfAssigned8
ON (edfAssigned8.id=Computers.ComputerId AND edfAssigned8.ExtraFieldId =(
SELECT  ExtraField.id
FROM ExtraField
WHERE LTGuid='99e011f7-4e75-4033-b1fe-84633ff095eb')) 
LEFT JOIN ExtraFieldData edfDefault8
ON (edfDefault8.id=0 AND edfDefault8.ExtraFieldId =(
SELECT  ExtraField.id
FROM ExtraField
WHERE LTGuid='99e011f7-4e75-4033-b1fe-84633ff095eb')) 
WHERE ((((NOT ((((Instr(IFNULL(IFNULL(edfAssigned1.Value,edfDefault1.value),''),'cannot find path') > 0) OR (Instr(IFNULL(IFNULL(edfAssigned2.Value,edfDefault2.value),''),'is not recognized as') > 0) OR (Instr(IFNULL(IFNULL(edfAssigned3.Value,edfDefault3.value),''),'cannot find path') > 0))))) AND ( NOT ((Instr(IFNULL(IFNULL(edfAssigned4.Value,edfDefault4.value),''),'OK') > 0))) AND (IFNULL(IFNULL(edfAssigned5.Value,edfDefault5.value),'') <> '\'\'') AND (IFNULL(IFNULL(edfAssigned6.Value,edfDefault6.value),'') <> '') AND ( ((Instr(Locations.Name,'Peak 10') > 0) OR (Instr(Clients.Name,'Kablelink') > 0) OR (Instr(Clients.Name,'CIO Tech') > 0))) AND ( NOT ((((Instr(Clients.Name,'Crisis Center') > 0) AND (Computers.Name = 'ARGTPAWN-DB-DWH'))))) AND (IFNULL(ROUND(Computers.TotalMemory/1024,0),0) > 0) AND (IFNULL(COUNT(inv_processor.Cores > 0))) AND ( ((IF((Computers.flags & 2048) <> 0, 1, 0)<>0) OR (IF((Computers.flags & 2048) <> 0, 1, 0)=0))) AND ( ((Instr(IFNULL(IFNULL(edfAssigned7.Value,edfDefault7.value),''),'Enterprise') > 0) OR (Instr(IFNULL(IFNULL(edfAssigned8.Value,edfDefault8.value),''),'Standard') > 0))) AND ( ((IF((Computers.flags & 2048) <> 0, 1, 0)<>0) OR (IF((Computers.flags & 2048) <> 0, 1, 0)=0))) AND (Instr(inv_operatingsystem.name,'Microsoft') > 0) AND (inv_processor.Manufacturer <> 'kmart')))) 
GROUP BY  computers.computerid
ORDER BY `client name`