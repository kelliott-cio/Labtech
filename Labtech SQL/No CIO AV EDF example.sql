SELECT 
   computers.computerid AS `Computer Id`,
   computers.name AS `Computer Name`,
   clients.name AS `Client Name`,
   computers.domain AS `Computer Domain`,
   computers.username AS `Computer User`,
   IFNULL(IFNULL(edfAssigned1.Value,edfDefault1.value),'0') AS `Computer - Location - Extra Data Field - Antivirus - No CIO AV`
FROM Computers
LEFT JOIN inv_operatingsystem ON (Computers.ComputerId=inv_operatingsystem.ComputerId)
LEFT JOIN Clients ON (Computers.ClientId=Clients.ClientId)
LEFT JOIN Locations ON (Computers.LocationId=Locations.LocationID)
LEFT JOIN ExtraFieldData edfAssigned1 ON (edfAssigned1.id=Locations.LocationId AND edfAssigned1.ExtraFieldId =(SELECT ExtraField.id FROM ExtraField WHERE LTGuid='8604e393-167e-446c-8ac2-0f364ac27a81'))
LEFT JOIN ExtraFieldData edfDefault1 ON (edfDefault1.id=0 AND edfDefault1.ExtraFieldId =(SELECT ExtraField.id FROM ExtraField WHERE LTGuid='8604e393-167e-446c-8ac2-0f364ac27a81'))
 WHERE
((IFNULL(IFNULL(edfAssigned1.Value,edfDefault1.value),'0')<>0))
