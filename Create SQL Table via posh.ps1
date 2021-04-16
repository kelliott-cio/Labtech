$clients = Get-AutomateSQLDataTable -SQL "select * from clients"
foreach ($c in $clients){
$body = "Insert Into SensorChecks (\``Name\``,\``SQL\``,\``QueryType\``,\``ListDATA\``,\``FolderID\``,\``SearchXML\``) Values('$($c.name)','SELECT \r\n   computers.computerid as \``Computer Id\``,\r\n   computers.name as \``Computer Name\``,\r\n   clients.name as \``Client Name\``,\r\n   computers.domain as \``Computer Domain\``,\r\n   computers.username as \``Computer User\``,\r\n   Clients.Name as \``Computer.Client.General.Name\``\r\nFROM Computers \r\nLEFT JOIN inv_operatingsystem ON (Computers.ComputerId=inv_operatingsystem.ComputerId)\r\nLEFT JOIN Clients ON (Computers.ClientId=Clients.ClientId)\r\nLEFT JOIN Locations ON (Computers.LocationId=Locations.LocationID)\r\n WHERE \r\n((Clients.Name = \'$($c.name)\'))\r\n',4, 'Select||=||=||=|^Select|||||||^',3, '<LabTechAbstractSearch><asn><st>AndNode</st><cn><asn><st>ComparisonNode</st><lon>Computer.Client.General.Name</lon><lok>Computer.Client.General.Name</lok><lmo>Equals</lmo><dv>$($c.name)</dv><dk>$($c.name)</dk></asn></cn></asn></LabTechAbstractSearch>')"
Get-AutomateSQLDataTable -sql $body
$lastid= Get-AutomateSQLDataTable -SQL "SELECT MAX(sensID) from sensorchecks"
Get-AutomateSQLDataTable -SQL "Insert into MasterGroups (ParentID,Parents,Name,Depth,fullname,Children,GroupType,Autojoinscript,LimitToParent,`GUID`) (select GroupID,CONVERT(CONCAT(Parents,GroupID,',') using latin1),'All Agents - $($c.Name)',(SELECT `Depth` + 1 FROM `MasterGroups` WHERE `GroupId`=5),CONVERT(CONCAT(Fullname,'.$($c.name)' using latin1),',',GroupType,$($lastid),1,uuid() from MasterGroups where GroupID=5);"
}



#Pull data from SQLSpy to find it's format and validate.
#above was written to add in azure ad sync stuff, needs redesigned for searches planned






#May be a duplication? 
Insert into MasterGroups (ParentID,Parents,Name,Depth,fullname,Children,GroupType,Autojoinscript,LimitToParent,`GUID`) (select GroupID,CONVERT(CONCAT(Parents,GroupID,',') using latin1),'All Agents rafmenn ehf prufa 2',(SELECT `Depth` + 1 FROM `MasterGroups` WHERE `GroupId`=5),CONVERT(CONCAT(Fullname,'.New Group') using latin1),',',GroupType,2287,1,uuid() from MasterGroups where GroupID=5);"
