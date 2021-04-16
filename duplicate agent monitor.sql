
INSERT INTO `Agents` (`Name`,`LocID`,`ClientID`,`ComputerID`,`DriveID`,`CheckAction`,`AlertAction`,`AlertMessage`,`ContactID`,`interval`,`Where`,`What`,`DataOut`,`Comparor`,`DataIn`,`LastScan`,`LastFailed`,`FailCount`,`IDField`,`AlertStyle`,`Changed`,`Last_Date`,`Last_User`,`ReportCategory`,`TicketCategory`,`Flags`,`GUID`,`AgentDefaultGUID`,`WarningCount`,`DeviceId`) Values('Duplicate Agent Detection*','0','0','0','0','0','1','%NAME% %STATUS% on %CLIENTNAME%\\%COMPUTERNAME% at %LOCATIONNAME% for Agent \#%ComputerID%\r\n\r\nThis agent ID is no longer considered a duplicate as it has reported back in, or the duplicate agent was identified and removed.!!!%NAME% %STATUS% on %CLIENTNAME%\\%COMPUTERNAME% at %LOCATIONNAME% for Agent \#%computerid%\r\n\r\nIt appears that this agent has registered a new ComputerID with LabTech, under the same Location. This Agent or Agent ID \#%RESULT% can be removed from LabTech after confirmation of the newer duplicate.\r\n','1','86400','computers','ComputerID','','7','(SELECT DISTINCT C2.computerid FROM (\`computers\` AS c1 LEFT JOIN \`computers\` AS c2 USING (\`ClientID\`,\`LocationID\`,\`Name\`)) WHERE NOT ( c2.\`ComputerID\` IS NULL OR c1.\`ComputerID\`=c2.\`ComputerID\` OR C1.DateAdded>C2.LastContact OR C1.LastContact>C2.LastContact ) AND ((C1.\`OS\`=c2.\`OS\`)+(C1.\`Version\`=c2.\`Version\`)+(C1.\`BiosFlash\`=c2.\`BiosFlash\`)+(C1.\`Domain\`=c2.\`Domain\`)+(C1.\`TotalMemory\`=c2.\`TotalMemory\`)+10*((C1.\`BiosName\`=c2.\`BiosName\`)+(C1.\`BiosVer\`=c2.\`BiosVer\`)+(C1.\`BiosMFG\`=c2.\`BiosMFG\`)))>33)','2018/12/10 08:50:08','2018/12/10 08:51:06','48','(SELECT GROUP_CONCAT(c2.computerid SEPARATOR \',\') FROM computers AS C2 WHERE c2.computerid<>computers.computerid AND c2.clientid=computers.clientid AND c2.locationid=computers.locationid AND c2.Name=computers.Name AND (((C2.BiosName=computers.BiosName)+(C2.BiosVer=computers.BiosVer)+(C2.BiosMFG=computers.BiosMFG))*10+(C2.OS=computers.OS)+(C2.\`Version\`=computers.\`Version\`)+(C2.BiosFlash=computers.BiosFlash)+(C2.Domain=computers.Domain)+(C2.TotalMemory=computers.TotalMemory))>33)','0','0','2018/12/10 08:51:06','kelliott@10.104.2.158','1','6','1','615293da-2a6c-4e22-913c-388ef047d50b','','0','0');
