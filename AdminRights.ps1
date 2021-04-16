######## 
#ODFB Rights Administration 
#Copyright:     Free to use, please leave this header intact 
#Author:        Jos Lieben (OGD) 
#Company:       OGD (http://www.ogd.nl) 
#Script help:   http://www.lieben.nu 
#Purpose:       Give an administrator rights on all Onedrive for Business accounts 
######## 
#Requirements: 
######## 
<# 
Powershell 4 
.NET 4.5 
Sharepoint Online Management Shell (X64) 
http://www.microsoft.com/en-us/download/details.aspx?id=35588 
Sharepoint Server 2013 Client Components 
http://www.microsoft.com/en-us/download/details.aspx?id=35585 
run “Set-Executionpolicy Unrestricted” in an elevated powershell window 
Windows 7+ or Windows Server 2008+ 
#> 

$o365login     = "cioadmin@tmdcompanies.com"           #Username of O365 Admin 
$o365pw        = "##R3d@l3rt!!"                                        #Password of O365 Admin 
$spAdminURL    = "https://tmdcompanies-admin.sharepoint.com"    #URL to your SP Admin site 
$spMyURL       = "https://tmdcompanies-my.sharepoint.com"       #URL to your SP MySites 

$logfile       = "$($(get-location).path)\LogFile.txt"     #Logfile in case of errors 

#Start script 
ac $logfile "-----$(Get-Date) ODFB_RA v0.1 $($env:COMPUTERNAME) Session log-----`n" 
 
#build Credential Object 
$secpasswd = ConvertTo-SecureString $o365pw -AsPlainText -Force 
$Credentials = New-Object System.Management.Automation.PSCredential ($o365login, $secpasswd) 
 
#Load sharepoint module 
try { 
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client") | Out-Null 
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.Runtime") | Out-Null 
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.UserProfiles") | Out-Null 
} catch { 
    $errorstring = "ERROR: Failed to load Sharepoint Libraries, exiting" 
    ac $logfile $errorstring 
    Write-Host $errorstring 
    Pause 
    Exit 
}

#load SPOnline module
$env:PSModulePath += ";C:\Program Files\SharePoint Online Management Shell\"
try {
    Import-Module Microsoft.Online.SharePoint.PowerShell
} catch { 
    $errorstring = "ERROR: Failed to load Sharepoint Online module, exiting" 
    ac $logfile $errorstring 
    ac $logfile $error[0] 
    Write-Host $errorstring 
    Pause 
    Exit 
} 
 
#Build sP credential object 
$creds = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($o365login,$secpasswd) 
 
#build proxy 
$proxyaddr = "$spAdminURL/_vti_bin/UserProfileService.asmx?wsdl" 
$UserProfileService= New-WebServiceProxy -Uri $proxyaddr -UseDefaultCredential False 
$UserProfileService.Credentials = $creds 
 
$strAuthCookie = $creds.GetAuthenticationCookie($spAdminURL) 
$uri = New-Object System.Uri($spAdminURL) 
$container = New-Object System.Net.CookieContainer 
$container.SetCookies($uri, $strAuthCookie) 
$UserProfileService.CookieContainer = $container 

try { 
    $UserProfileResult = $UserProfileService.GetUserProfileByIndex(-1) 
} catch { 
    $errorstring = "Critical error, unable to get profiles" 
    ac $logfile $errorstring 
    ac $logfile $error[0] 
    Write-Host $errorstring $error[0] 
    Pause 
    Exit 
} 

$NumProfiles = $UserProfileService.GetUserProfileCount() 
$i = 1 
$ProfileURLs = @() 
 
Write-Host "Begin discovery of $NumProfiles profiles" 
While ($UserProfileResult.NextValue -ne -1)  
{ 
    Write-Host "Checking profile $i of $NumProfiles" 
    $Prop = $UserProfileResult.UserProfile | Where-Object { $_.Name -eq "PersonalSpace" }  
    $Url= $Prop.Values[0].Value 
    if ($Url) { 
        Write-Host "Adding $Url to the list" 
        $ProfileURLs += $Url 
    } 
    $UserProfileResult = $UserProfileService.GetUserProfileByIndex($UserProfileResult.NextValue) 
    $i++ 
} 
Write-Host "Finished discovery of profiles" 
 
Write-Host "Connecting to Sharepoint Online" 
try { 
    Connect-SPOService -Url $spAdminURL -Credential $Credentials 
} catch { 
    $errorstring = "Critical error, unable to Connect to Sharepoint Online" 
    ac $logfile $errorstring 
    ac $logfile $error[0] 
    Write-Host $errorstring $error[0] 
    Pause 
    Exit 
} 
 
Write-Host "Start processing profiles" 
 
foreach ($profileURL in $ProfileURLs) { 
    $fullPath = "$spMyURL$profileURL".TrimEnd("/") 
    Write-Host "Processing $fullPath" 
    try { 
        Set-SPOUser -Site $fullPath -LoginName $o365login -IsSiteCollectionAdmin $true 
        Write-Host "$o365login permissions added to $fullPath" 
    } catch { 
        $errorstring = "Failed adding $o365login permissions to $fullPath" 
        ac $logfile $errorstring 
        ac $logfile $error[0] 
        Write-Host $errorstring $error[0]       
    } 
} 
 
ac $logfile "Script finished" 
Write-Host "Job Finished" 
Pause 
Exit