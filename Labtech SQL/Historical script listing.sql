SELECT h_scripts.scriptid, lt_Scripts.scriptname, h_scripts.computerid, h_scripts.starteddate FROM h_scripts
JOIN lt_scripts ON lt_scripts.scriptid = h_scripts.scriptid
WHERE finishstatus = 1 AND h_scripts.starteddate > DATE_SUB(DATE(NOW()), INTERVAL 1 DAY)
