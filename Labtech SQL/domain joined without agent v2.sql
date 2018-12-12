CREATE TEMPORARY TABLE IF NOT EXISTS Tcomp (INDEX (Computerid)) SELECT computerid FROM computers WHERE ComputerID NOT IN (SELECT ComputerID FROM AgentIgnore WHERE AgentID=145914);
SELECT DISTINCT c.computerid AS TestValue, UPPER(CONCAT(ad_d.NTDomain,'\\',ad_e.Name)) AS IDField, c.computerid, c.Name AS computername, loc.locationid, loc.name AS locationname, cl.Clientid, cl.name AS clientname, acd.NoAlerts, acd.UpTimeStart, acd.UpTimeEnd
FROM (SELECT DISTINCT c1.clientid,  MIN(c1.computerid) AS computerid, REPLACE(c1.Domain,'DC:','') AS domainname FROM computers AS c1 WHERE c1.domain LIKE 'DC:%' AND ComputerID NOT IN (SELECT ComputerID FROM AgentIgnore WHERE AgentID=145914) GROUP BY clientid, domainname) AS cm
JOIN plugin_ad_domains AS ad_d ON cm.domainname=ad_d.domainname
JOIN plugin_ad_entries AS ad_e ON ad_d.ObjectGUID=ad_e.DomainGUID AND ad_e.ObjectType=2 AND ad_e.ObjectCategory LIKE 'CN=Computer,%' AND IFNULL(ad_e.Description,'') NOT LIKE '%exclude%'
JOIN plugin_ad_computers AS ad_c ON ad_e.ObjectGUID=ad_c.ObjectGUID AND ad_c.OS LIKE 'Windows%' AND LEFT(IFNULL(ad_c.OSVersion,''),3) NOT IN ('4.0','5.0','5.1','5.2')
LEFT JOIN computers AS NoReport ON NoReport.Name=ad_e.Name AND (REPLACE(NoReport.Domain,'DC:','')=cm.domainname OR (NoReport.clientid=cm.clientid AND (IFNULL(NoReport.Domain,'')='' OR NOT NoReport.Domain LIKE '%.%')))
LEFT JOIN retiredassets AS retired ON retired.Name=ad_e.Name AND retired.clientid=cm.clientid
JOIN computers AS c ON c.computerid=cm.computerid
JOIN Locations AS loc ON loc.LocationID=c.Locationid
JOIN Clients AS cl ON cl.clientid=c.clientid
JOIN AgentComputerData AS acd ON c.ComputerID=acd.ComputerID
WHERE ad_c.LastLogon>DATE_ADD(NOW(),INTERVAL -30 DAY) AND NOT ad_e.Name LIKE '%VEEAM%' AND
ISNULL(NoReport.Name) AND ISNULL(retired.Name) AND
c.ComputerID IN (SELECT ComputerID FROM Tcomp);




Update the two references to `AgentID=145914` to match your actual monitor ID.


SELECT
   computers.computerid as `Computer Id`,
   computers.name as `Computer Name`,
   clients.name as `Client Name`,
   computers.domain as `Computer Domain`,
   computers.username as `Computer User`,
   IF(Computers.Uptime >= 0 AND DATE_ADD(Computers.LastContact, INTERVAL 15 MINUTE) > NOW(), 1, 0) as `Computer.LabTech.IsOnline`
FROM Computers
LEFT JOIN inv_operatingsystem ON (Computers.ComputerId=inv_operatingsystem.ComputerId)
LEFT JOIN Clients ON (Computers.ClientId=Clients.ClientId)
LEFT JOIN Locations ON (Computers.LocationId=Locations.LocationID)
 WHERE
((IF(Computers.Uptime >= 0 AND DATE_ADD(Computers.LastContact, INTERVAL 15 MINUTE) > NOW(), 1, 0)<>0))
