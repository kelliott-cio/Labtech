SELECT UUID() AS id,
   computers.computerid AS `Computer Id`,
   computers.comment AS Comments,
   computers.name AS `Computer Name`,
   clients.name AS `Client Name`,
   computers.domain AS `Computer Domain`,
   computers.username AS `Computer User`,
   Uptime AS 'Uptime Minutes',
   DATEDIFF(NOW(), Computers.VirusDefs) AS `Computer.Antivirus.DefinitionFileAge.Days`,
   DATEDIFF(NOW(), Computers.LastContact) AS `Computer.LabTech.LastContactAge.Days`,
   inv_operatingsystem.name AS `Computer.OS.Name`,
   Computers.LastContact AS `Computer.LabTech.LastContactDate`,
   VirusScanners.Name AS `Computer.Antivirus.Name`,
   Locations.Name AS `Computer.Location.General.Name`,
   IF(Computers.Uptime >= 0 AND DATE_ADD(Computers.LastContact, INTERVAL 15 MINUTE) > NOW(), 1, 0) AS `Computer.LabTech.IsOnline`,
   IFNULL(IFNULL(edfAssigned1.Value,edfDefault1.value),'0') AS `Computer - Location - Extra Data Field - Antivirus - No CIO AV`,
   IFNULL(IFNULL(edfAssigned2.Value,edfDefault2.value),'0') AS `Computer - Extra Data Field - Exclusions - Do Not Deploy AV`
FROM Computers
LEFT JOIN inv_operatingsystem ON (Computers.ComputerId=inv_operatingsystem.ComputerId)
LEFT JOIN Clients ON (Computers.ClientId=Clients.ClientId)
LEFT JOIN Locations ON (Computers.LocationId=Locations.LocationID)
LEFT JOIN VirusScanners ON (VirusScanners.VSCanId=Computers.VirusScanner)
LEFT JOIN ExtraFieldData edfAssigned1 ON (edfAssigned1.id=Locations.LocationId AND edfAssigned1.ExtraFieldId =(SELECT ExtraField.id FROM ExtraField WHERE LTGuid='8604e393-167e-446c-8ac2-0f364ac27a81'))
LEFT JOIN ExtraFieldData edfDefault1 ON (edfDefault1.id=0 AND edfDefault1.ExtraFieldId =(SELECT ExtraField.id FROM ExtraField WHERE LTGuid='8604e393-167e-446c-8ac2-0f364ac27a81'))
LEFT JOIN ExtraFieldData edfAssigned2 ON (edfAssigned2.id=Computers.ComputerId AND edfAssigned2.ExtraFieldId =(SELECT ExtraField.id FROM ExtraField WHERE LTGuid='f8d53638-967f-4cb4-bff5-17e30f51138a'))
LEFT JOIN ExtraFieldData edfDefault2 ON (edfDefault2.id=0 AND edfDefault2.ExtraFieldId =(SELECT ExtraField.id FROM ExtraField WHERE LTGuid='f8d53638-967f-4cb4-bff5-17e30f51138a'))
WHERE
((IFNULL(IFNULL(edfAssigned1.Value,edfDefault1.value),'0')=0)) AND
((IFNULL(IFNULL(edfAssigned2.Value,edfDefault2.value),'0')=0))
