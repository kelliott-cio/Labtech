Select computers.computerID,
    computers.Name as 'Computer',
    count(1) as 'Failed count',
    lt_scripts.scriptName,
    h_scripts.*
from ((h_scripts left join lt_scripts on h_scripts.scriptID = lt_scripts.scriptID)
        left join computers on h_scripts.computerID = computers.computerID)
where h_scripts.scriptStatus = 1 #failed = 1, log message = 2, successful = 3
    and h_scripts.historyDate > current_date
group by h_scripts.computerID
having count(1) > 5
