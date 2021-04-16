$ErrorActionPreference = "SilentlyContinue"
$dir = '@SetupPath@'
mkdir $dir
$webClient = New-Object System.Net.WebClient
$url = 'https://go.microsoft.com/fwlink/?LinkID=799445'
$file = "$($dir)\Win10Upgrade.exe"
$webClient.DownloadFile($url,$file)
$install = Start-Process -FilePath $file -ArgumentList "/quietinstall /skipeula /auto upgrade /copylogs $dir" -Wait -PassThru
$hex = "{0:x}" -f $install.ExitCode
$exit_code = "0x$hex"
​
# Get latest compatibility report XML and list programs
[xml]$compatreport = Get-ChildItem "$dir\Windows10UpgradeLogs\panther\compat*" | sort LastWriteTime | select -last 1 | Get-Content
$incompatible_programs = $compatreport.Compatreport.Programs | % {$_.Program.Name}
​
# Convert hex code to human readable
$message = Switch ($exit_code) {
   "0xC1900210" { "SUCCESS: No compatibility issues detected"; break } 
   "0xC1900101" { "ERROR: Driver compatibility issue detected. https://docs.microsoft.com/en-us/windows/deployment/upgrade/resolution-procedures"; break }
   "0xC1900208" { "ERROR: Compatibility issue detected, unsupported programs:`r`n$incompatible_programs`r`n"; break }
   "0xC1900204" { "ERROR: Migration choice not available." ; break }
   "0xC1900200" { "ERROR: System not compatible with upgrade." ; break }
   "0xC190020E" { "ERROR: Insufficient disk space." ; break }
   "0x80070490" { "ERROR: General Windows Update failure, try the following troubleshooting steps`r`n- Run update troubleshooter`r`n- sfc /scannow`r`n- DISM.exe /Online /Cleanup-image /Restorehealth`r`n - Reset windows update components.`r`n"; break }
   "0xC1800118" { "ERROR: WSUS has downloaded content that it cannot use due to a missing decryption key."; break }
   "0x80090011" { "ERROR: A device driver error occurred during user data migration."; break }
   "0xC7700112" { "ERROR: Failure to complete writing data to the system drive, possibly due to write access failure on the hard disk."; break }
   "0xC1900201" { "ERROR: The system did not pass the minimum requirements to install the update."; break }
   "0x80240017" { "ERROR: The upgrade is unavailable for this edition of Windows."; break }
   "0x80070020" { "ERROR: The existing process cannot access the file because it is being used by another process."; break }
   "0xC1900107" { "ERROR: A cleanup operation from a previous installation attempt is still pending and a system reboot is required in order to continue the upgrade."; break }
   "0x3" { "SUCCESS: The upgrade started, no compatibility issues."; break }
   "0x5" { "ERROR: The compatibility check detected issues that require resolution before the upgrade can continue."; break }
   "0x7" { "ERROR: The installation option (upgrade or data only) was not available."; break }
   "0x0" { "SUCCESS: Upgrade started."; break }
   default { "WARNING: Unknown exit code."; break }
}
​
Write-Output "$message (Code: $exit_code)"