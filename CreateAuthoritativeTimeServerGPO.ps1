Set-StrictMode -Version 2

#Carl Webster, CTP and independent consultant
#webster@carlwebster.com
#@carlwebster on Twitter
#http://www.CarlWebster.com
#With help from Michael B. Smith - http://www.theessentialexchange.com

# load required modules
Import-Module ActiveDirectory
Import-Module GroupPolicy
#the following module is available for download from 
#http://gallery.technet.microsoft.com/scriptcenter/Group-Policy-WMI-filter-38a188f3
#assuming the module is in the same folder as the script
Import-Module ( Join-Path ( Split-Path $MyInvocation.MyCommand.Path -Parent) GPWmiFilter.psm1 )

#define variables specific to an AD environment
$GPOName       = 'Set PDCe as Authoritative Time Server'
$defaultNC     = ( [ADSI]"LDAP://RootDSE" ).defaultNamingContext.Value
$TargetOU      = 'OU=Domain Controllers,' + $defaultNC
$TimeServer    = 'north-america.pool.ntp.org,0x1'
$WMIFilterName = 'PDCe Role Filter'

#the GPWmiFilter module said to put this in the main code
new-itemproperty "HKLM:\System\CurrentControlSet\Services\NTDS\Parameters" `
-name "Allow System Only Change" -value 1 -propertyType dword -EA 0

#create WMI Filter
$filter = New-GPWmiFilter -Name $WMIFilterName `
-Expression 'Select * from Win32_ComputerSystem where DomainRole = 5' `
-Description 'Queries for the Domain Controller that holds the PDCe FSMO Role' `
-PassThru

#create new GPO shell
$GPO = New-GPO -Name $GPOName

#add WMI filter
$GPO.WmiFilter = $Filter

#set the three registry keys in the Preferences section of the new GPO
Set-GPPrefRegistryValue -Name $GPOName -Action Update -Context Computer `
-Key 'HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Config' `
-Type DWord  -ValueName 'AnnounceFlags' -Value 5 | out-null

Set-GPPrefRegistryValue -Name $GPOName -Action Update -Context Computer `
-Key 'HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters' `
-Type String -ValueName 'NtpServer' -Value $TimeServer | out-null

Set-GPPrefRegistryValue -Name $GPOName -Action Update -Context Computer `
-Key 'HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters' `
-Type String -ValueName 'Type' -Value 'NTP' | out-null

#link the new GPO to the Domain Controllers OU
New-GPLink -Name $GPOName `
-Target $TargetOU | out-null
