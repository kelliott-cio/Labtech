$drive = Get-WmiObject Win32_logicaldisk  | Where-Object { $_.drivetype -match "3" }

foreach ($friendlyname in $drive) {

    $driveletter = $friendlyname.deviceid -replace ':', ''
    $free = (Get-PSDrive $driveletter |  Where-Object { $_.Provider -match "FileSystem" } | Select-Object @{Name = 'TotalGB'; Expression = {
                [math]::Round(
                    ($_.Free / 1GB) + ($_.Used / 1GB)) 
            }
        }, @{Name = 'UsedGB'; Expression = {
                [math]::Round($_.Used / 1GB) 
            }
        }, @{Name = 'FreeGB'; Expression = {
                [math]::Round($_.Free / 1GB) 
            }
        }, @{Name = 'PercentFree'; Expression = {
                [math]::Round((($_.Free / 1GB) / (($_.Free / 1GB) + ($_.Used / 1GB))) * 100)
            }
        }
    ) 

    $letter = $friendlyname.deviceid

    if ($free.percentfree -gt 40) { 
        $size = "UNBOUNDED"
        vssadmin resize shadowstorage /for=$letter /on=$letter /maxsize=$size
    }
    else {
        if (($free.percentfree -gt 20) -xor ($free.percentfree -gt 40)) {
            $size = "10%"
            vssadmin resize shadowstorage /for=$letter /on=$letter /maxsize=$size
        }
        else {
            $size = "5%"
            vssadmin resize shadowstorage /for=$letter /on=$letter /maxsize=$size
        }
    }
}
