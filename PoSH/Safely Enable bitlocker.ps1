$OSInfo = (get-wmiobject win32_operatingsystem)
if (!(($OSInfo.Version) -match "10\.0\.")) { 
  Write-Output "This Script is only designed to run on Windows 10. Unable to Continue."
  Exit 1 
}
if (!(($OSInfo.Caption) -match "Pro|Enterprise")) { 
  Write-Output "Bitlocker is only usable on Pro and Enterprise versions of Windows 10. Unable to Continue." 
  Exit 1 
}
if (!(Get-WmiObject -Namespace "ROOT\CIMV2\Security\MicrosoftTPM" -Class "Win32_tpm")) {
  Write-Output "No TPM Chip Found. Unable to Continue."
  Exit 1
}
$bdestatus = (manage-bde $($env:systemdrive) -status)
if ($bdestatus -match "Numerical Password") {
Write-Output "Volume already Encrypted, Output of manage-bde $($env:systemdrive) -status:`r`n$($bdestatus)"
exit 1
} else {
manage-bde $($env:systemdrive) -protectors -add -tpm
manage-bde $($env:systemdrive) -protectors -add -rp
manage-bde $($env:systemdrive) -on
}
$drives = Get-WmiObject -Namespace ROOT\CIMV2\Security\Microsoftvolumeencryption -Class Win32_encryptablevolume
$encrypted = @($drives | Where-Object {$_.ProtectionStatus -ne 0})
$regRecovery = New-Object System.Text.RegularExpressions.Regex ('[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}')
$regLock = New-Object System.Text.RegularExpressions.Regex '(?:Lock Status:\s+)(\w+)'
$keys = @()
foreach ($drive in $encrypted) {
    $driveStatus = manage-bde.exe $drive.DriveLetter -status
    $lockStatus = $regLock.Match($driveStatus).Groups[1].Value
    if ($lockStatus -eq "Unlocked") {
        $out = manage-bde $drive.DriveLetter -protectors -get -type RecoveryPassword
        $key = $regRecovery.Match($out).Value
        $key_formatted = $drive.DriveLetter + $key
        $keys += $key_formatted
    }
}
Write-Output ($keys -join ";")