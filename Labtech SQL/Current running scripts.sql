SELECT c.computerid, c.lastcontact, r.scriptid, l.scriptname, r.start, r.running FROM computers c JOIN runningscripts r ON r.`ComputerID` = c.`ComputerID` JOIN	lt_scripts l ON l.`ScriptId`=r.`ScriptID` WHERE c.`LastContact` <DATE_SUB(NOW(),INTERVAL -10 MINUTE) AND r.`Running`=1
