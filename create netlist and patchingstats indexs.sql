SET @exist := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_name = 'patchconfigurationinformation' AND index_name = 'PatchingStats' AND table_schema = DATABASE()); 
SET @sqlstmt := IF( @exist > 0, 'ALTER TABLE `labtech`.`patchconfigurationinformation` DROP INDEX `PatchingStats`;','select ''INFO: PatchingStats Index does not exist. Creating it.'''); 
PREPARE stmt FROM @sqlstmt; 
EXECUTE stmt;
ALTER TABLE `labtech`.`patchconfigurationinformation` ADD KEY `PatchingStats` (`ItemValue`);


SET @exist := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_name = 'subgroupsnetworkdevices' AND index_name = 'NetList' AND table_schema = DATABASE()); 
SET @sqlstmt := IF( @exist > 0, 'ALTER TABLE `labtech`.`subgroupsnetworkdevices` DROP INDEX `NetList`;', 'select ''INFO: NetList Index does not exist. Creating it.'''); 
PREPARE stmt FROM @sqlstmt; 
EXECUTE stmt; 
ALTER TABLE `labtech`.`subgroupsnetworkdevices` ADD KEY `NetList` (`DeviceId`, `GroupId`);
