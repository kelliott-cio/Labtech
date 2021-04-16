<#
.SYNOPSIS
    Script searches all user profiles on a system, and disables PSTs
.DESCRIPTION
    This script disables PSTs across all existing users. For it to apply to users not yet created, make sure to use local GPO or AD GPO. This only affects existing accounts. It currently works on 2010+
.EXAMPLE
    c:\support\Disable-PST.ps1
.INPUTS
    None Required
.NOTES
    Created by Kyle Elliott @ CIO TECH on 11-9-2020 
    No warranty implied or given
    Verified as working on 11-9-2020
#>

#Create function to Disable PSTs across all users
function Disable-PST {
    # Test for group policy controlled keys, create if missing
    if (test-path -path "registry::HKEY_USERS\$($Item.SID)\Software\Policies\Microsoft\Office\$ver") {
        if (test-path -path "registry::HKEY_USERS\$($Item.SID)\Software\Policies\Microsoft\Office\$ver\Outlook\PST"){
            New-ItemProperty "registry::HKEY_USERS\$($Item.SID)\Software\Policies\Microsoft\Office\$ver\Outlook\PST" -name "DisablePST" -value 1 -propertytype dword -force
            New-ItemProperty "registry::HKEY_USERS\$($Item.SID)\Software\Policies\Microsoft\Office\$ver\Outlook\PST" -name "PSTDisableGrow" -value 1 -propertytype dword -force
        }
        else {
            New-Item "registry::HKEY_USERS\$($Item.SID)\Software\Policies\Microsoft\Office\$ver\Outlook" -name PST
            New-ItemProperty "registry::HKEY_USERS\$($Item.SID)\Software\Policies\Microsoft\Office\$ver\Outlook\PST" -name "DisablePST" -value 1 -propertytype dword -force
            New-ItemProperty "registry::HKEY_USERS\$($Item.SID)\Software\Policies\Microsoft\Office\$ver\Outlook\PST" -name "PSTDisableGrow" -value 1 -propertytype dword -force
        }
    }
    # Test for non group policy controlled keys, create if missing
    if (test-path -path "registry::HKEY_USERS\$($Item.SID)\Software\Microsoft\Office\$ver\Outlook\") {
        if (test-path -path "registry::HKEY_USERS\$($Item.SID)\Software\Microsoft\Office\$ver\Outlook\PST"){
            New-ItemProperty "registry::HKEY_USERS\$($Item.SID)\Software\Microsoft\Office\$ver\Outlook\PST" -name "DisablePST" -value 1 -propertytype dword -force
            New-ItemProperty "registry::HKEY_USERS\$($Item.SID)\Software\Microsoft\Office\$ver\Outlook\PST" -name "PSTDisableGrow" -value 1 -propertytype dword -force
        }
        else {
            New-Item "registry::HKEY_USERS\$($Item.SID)\Software\Microsoft\Office\$ver\Outlook\" -name PST
            New-ItemProperty "registry::HKEY_USERS\$($Item.SID)\Software\Microsoft\Office\$ver\Outlook\PST" -name "DisablePST" -value 1 -propertytype dword -force
            New-ItemProperty "registry::HKEY_USERS\$($Item.SID)\Software\Microsoft\Office\$ver\Outlook\PST" -name "PSTDisableGrow" -value 1 -propertytype dword -force
        }
    }  
}

# Regex pattern for SIDs
$PatternSID = 'S-1-5-21-\d+-\d+\-\d+\-\d+$'
 
# Get Username, SID, and location of ntuser.dat for all users
$ProfileList = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | Where-Object {$_.PSChildName -match $PatternSID} | 
    Select-Object  @{name="SID";expression={$_.PSChildName}}, 
            @{name="UserHive";expression={"$($_.ProfileImagePath)\ntuser.dat"}}, 
            @{name="Username";expression={$_.ProfileImagePath -replace '^(.*[\\\/])', ''}}
 
# Get all user SIDs found in HKEY_USERS (ntuder.dat files that are loaded)
$LoadedHives = Get-ChildItem Registry::HKEY_USERS | Where-Object {$_.PSChildname -match $PatternSID} | Select-Object @{name="SID";expression={$_.PSChildName}}
 
# Get all users that are not currently logged
$UnloadedHives = Compare-Object $ProfileList.SID $LoadedHives.SID | Select-Object @{name="SID";expression={$_.InputObject}}, UserHive, Username
 
# Loop through each profile on the machine
Foreach ($item in $ProfileList) {
    # Load User ntuser.dat if it's not already loaded
    IF ($item.SID -in $UnloadedHives.SID) {
        reg load HKU\$($Item.SID) $($Item.UserHive) | Out-Null
    }
 
    #####################################################################
    # Set version and trigger the function to block PSTs on that version number
    "{0}" -f $($item.Username) | Write-Output
    $ver ="16.0"
    Disable-PST
    $ver ="15.0"
    Disable-PST
    $ver ="14.0"
    Disable-PST
    #####################################################################
 
    # Unload ntuser.dat        
    IF ($item.SID -in $UnloadedHives.SID) {
        ### Garbage collection and closing of ntuser.dat ###
        [gc]::Collect()
        reg unload HKU\$($Item.SID) | Out-Null
    }
}
