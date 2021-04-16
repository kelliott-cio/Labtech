<#
.SYNOPSIS
This script is developed to install netsckope to customer equipment. It requires 3 fields to be passed in a parameter, the email domain (after the @ symbol from their email), the netskope token and the netskope tenant URL.

.DESCRIPTION
This script is developed to install netsckope to customer equipment. It requires 3 fields to be passed in a parameter, the email domain (after the @ symbol from their email), the netskope token and the netskope tenant URL. Originally written by Patrick Ford, modified by Netskope support and then refactored to be customer non-specific by Kyle Elliott

.PARAMETER domain
[required] This is the customer's email domain

.PARAMETER Token
[required] Enter the customers Netskope token

.PARAMETER tenant
[required] enter customer tenant URL

.EXAMPLE
nsclient_install.ps1 -domain example.com -token as23rfj3923904r1298rtj132 -tenant addon-example.goskope.com

.NOTES


#>

param
(
    [Parameter(Mandatory=$true)]
    [string]$domain,

    [Parameter(Mandatory=$true)]
    [string]$token,

    [Parameter(Mandatory=$true)]
    [string]$tenant

)

# Get the ID and security principal of the current user account
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
 
# Get the security principal for the Administrator role
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
 
# Check to see if we are currently running "as Administrator"
if ($myWindowsPrincipal.IsInRole($adminRole))
   {
   # We are running "as Administrator" - so change the title and background color to indicate this
   $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
   $Host.UI.RawUI.BackgroundColor = "DarkBlue"
   clear-host
   }
#else
   {
   # We are not running "as Administrator" - so relaunch as administrator
   
   # Create a new process object that starts PowerShell
   $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
   
   # Specify the current script path and name as a parameter
   $newProcess.Arguments = $myInvocation.MyCommand.Definition;
   
   # Indicate that the process should be elevated
   $newProcess.Verb = "runas";
   
   # Start the new process
   [System.Diagnostics.Process]::Start($newProcess);
   
   # Exit from the current, unelevated, process
   exit
   }
 
# Run your code that needs to be elevated here
Set-ExecutionPolicy Bypass -Force
New-Item -Path "C:\ProgramData\Netskope\STAgent" -ItemType "directory"
Set-Location -Path 'C:\Windows\Temp'
$tenanturl="https://$tenant"

$brandingfile="C:\ProgramData\Netskope\STAgent\nsbranding.json"

# Get host name
$hostname=(Get-CIMInstance CIM_ComputerSystem).Name
# Get users email 
# Pull Office365 registration email address and store in variable $baseemail 

$baseemail = Get-ItemProperty HKLM:\Software\Microsoft\Office\ClickToRun\Configuration\ -Name O365BusinessRetail.EmailAddress | Select-object -expandproperty O365BusinessRetail.EmailAddress
$useremail="$(($baseemail -split '@')[0])@$(($domain))"


# Download Netskope configs for useremail
# Original provided script was storing email address in variable $email but line 55 was calling a string via url for email address as #useremail. Adjusted above on line 50
$nskp_url="$tenanturl/config/user/getbrandingbyemail?orgkey=$token&email=$useremail"

Write-Host $nskp_url

Invoke-RestMethod -Uri $nskp_url -Method Get -OutFile $brandingfile;

$branding = Get-Content $brandingfile | Out-String | ConvertFrom-Json
Write-Host $branding.status

 #Execute the NSClient package 
    $returncode=(Start-Process "msiexec.exe" -ArgumentList "/i NSClient.msi token=$token host=$tenant /passive /qn" -Wait -Passthru).ExitCode

    if ($returncode -eq 0) {
        Write-Host "Install Successful"
    } else {
        Write-Host "Error !! - $returncode"
    }
  