CREATE TEMPORARY TABLE IF NOT EXISTS Tcomp (INDEX (Computerid)) SELECT computerid FROM computers WHERE ComputerID NOT IN (SELECT ComputerID FROM AgentIgnore WHERE AgentID=225104);
SELECT DISTINCT c.computerid AS TestValue, UPPER(CONCAT(ad_d.NTDomain,'\\',ad_e.Name)) AS IDField, c.computerid, c.Name AS computername, loc.locationid, loc.name AS locationname, cl.Clientid, cl.name AS clientname, acd.NoAlerts, acd.UpTimeStart, acd.UpTimeEnd
FROM (SELECT c1.clientid, MIN(c1.computerid) AS computerid FROM computers AS c1 WHERE c1.flags&128=128 GROUP BY clientid) AS probemap
JOIN (SELECT DISTINCT c1.clientid, REPLACE(c1.Domain,'DC:','') AS domainname FROM computers AS c1 WHERE c1.domain LIKE 'DC:%') AS cm ON cm.clientid=probemap.clientid
JOIN plugin_ad_domains AS ad_d ON cm.domainname=ad_d.domainname
JOIN plugin_ad_entries AS ad_e ON ad_d.ObjectGUID=ad_e.DomainGUID AND ad_e.ObjectType=2 AND ad_e.ObjectCategory LIKE 'CN=Computer,%'
JOIN plugin_ad_computers AS ad_c ON ad_e.ObjectGUID=ad_c.ObjectGUID AND ad_c.OS LIKE 'Windows%'
JOIN computers AS c ON c.computerid=probemap.computerid
JOIN Locations AS loc ON loc.LocationID=c.Locationid
JOIN Clients AS cl ON cl.clientid=c.clientid
JOIN AgentComputerData AS acd ON c.ComputerID=acd.ComputerID
WHERE NOT (EXISTS (SELECT * FROM computers AS missing WHERE missing.Name=ad_e.Name AND REPLACE(missing.Domain,'DC:','')=cm.domainname) OR EXISTS (SELECT * FROM retiredassets AS retired WHERE retired.Name=ad_e.Name AND retired.clientid=cm.clientid))
AND ad_c.LastLogon>DATE_ADD(NOW(),INTERVAL -30 DAY) AND c.ComputerID IN (SELECT ComputerID FROM Tcomp);
