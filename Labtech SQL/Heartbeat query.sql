SELECT COUNT(*)  AS `NumberOfRecentHeartbeats`, (SELECT COUNT(*) FROM v_xr_computers WHERE ComputerDateLastContact > DATE_SUB(CURRENT_DATE(), INTERVAL 24 HOUR)) AS NumberOfComputerCheckins FROM HeartBeatComputers
WHERE LastHeartbeatTime > DATE_SUB(CURRENT_DATE(), INTERVAL 24 HOUR)
