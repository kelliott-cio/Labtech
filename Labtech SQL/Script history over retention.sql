SELECT * FROM `h_scripts` WHERE HistoryDate < DATE_SUB(NOW(), INTERVAL (SELECT VALUE FROM properties WHERE NAME = 'RetentionHistoryScriptLogs') DAY);
