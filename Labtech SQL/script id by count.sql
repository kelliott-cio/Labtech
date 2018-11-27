SELECT pendingscripts.ScriptID, lt_scripts.scriptname, COUNT(pendingscripts.scriptid) FROM pendingscripts, lt_scripts
WHERE pendingscripts.scriptid = lt_scripts.scriptid
GROUP BY scriptid
ORDER BY COUNT(*) DESC
