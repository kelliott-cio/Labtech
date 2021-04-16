#Requires -Version 3.0
#requires -Module GroupPolicy

<#
.SYNOPSIS
	Creates a Backup and Reports for all Group Policies in the current Active Directory domain.
.DESCRIPTION
	Creates a Backup and HTML and XML Reports for all Group Policies in the current Active Directory domain.

	This Script requires at least PowerShell version 3 but runs best in version 5.

	This script requires at least one domain controller running Windows Server 2008 R2.
	
	This script outputs Text, XML and HTML files.
	
	You do NOT have to run this script on a domain controller, and it is best if you didn't.

	This script was developed and run from a Windows 10 domain-joined VM.

	This script requires Domain Admin rights and an elevated PowerShell session.
	
	To run the script from a workstation, RSAT is required.
	
	Remote Server Administration Tools for Windows 7 with Service Pack 1 (SP1)
		http://www.microsoft.com/en-us/download/details.aspx?id=7887
		
	Remote Server Administration Tools for Windows 8 
		http://www.microsoft.com/en-us/download/details.aspx?id=28972
		
	Remote Server Administration Tools for Windows 8.1 
		http://www.microsoft.com/en-us/download/details.aspx?id=39296
		
	Remote Server Administration Tools for Windows 10
		http://www.microsoft.com/en-us/download/details.aspx?id=45520
.PARAMETER ADDomain
	Specifies an Active Directory domain object by providing one of the following 
	property values. The identifier in parentheses is the LDAP display name for the 
	attribute. All values are for the domainDNS object that represents the domain.

	Distinguished Name

	Example: DC=tullahoma,DC=corp,DC=labaddomain,DC=com

	GUID (objectGUID)

	Example: b9fa5fbd-4334-4a98-85f1-3a3a44069fc6

	Security Identifier (objectSid)

	Example: S-1-5-21-3643273344-1505409314-3732760578

	DNS domain name

	Example: tullahoma.corp.labaddomain.com

	NetBIOS domain name

	Example: Tullahoma

	Default value is $Env:USERDNSDOMAIN
.PARAMETER ComputerName
	Specifies which domain controller to use to run the script against.
	ComputerName can be entered as the NetBIOS name, FQDN, localhost or IP Address.
	If entered as localhost, the actual computer name is determined and used.
	If entered as an IP address, an attempt is made to determine and use the actual 
	computer name.
	
	This parameter has an alias of ServerName.
	Default value is $Env:USERDNSDOMAIN	
.PARAMETER Folder
	Specifies the optional output folder to save the output report. 
	
	The folder specified must already exist.
.PARAMETER MaxZipSize
	Specifies the maximum size, in MB, of the two Zip files created.
	Default is 150MB which is the limit of Outlook 365 email attachments.
	
	https://technet.microsoft.com/en-us/library/exchange-online-limits.aspx#MessageLimits
.PARAMETER SmtpServer
	Specifies the optional email server to send the output report. 
.PARAMETER SmtpPort
	Specifies the SMTP port. 
	The default is 25.
.PARAMETER UseSSL
	Specifies whether to use SSL for the SmtpServer.
	The default is False.
.PARAMETER From
	Specifies the username for the From email address.
	If SmtpServer is used, this is a required parameter.
.PARAMETER To
	Specifies the username for the To email address.
	If SmtpServer is used, this is a required parameter.
.PARAMETER Dev
	Clears errors at the beginning of the script.
	Outputs all errors to a text file at the end of the script.
	
	This is used when the script developer requests more troubleshooting data.
	The text file is placed in the same folder from where the script is run.
	
	This parameter is disabled by default.
.PARAMETER ScriptInfo
	Outputs information about the script to a text file.
	The text file is placed in the same folder from where the script is run.
	
	This parameter is disabled by default.
	This parameter has an alias of SI.
.PARAMETER Log
	Generates a log file for troubleshooting.
.EXAMPLE
	PS C:\PSScript > .\Get-GPOBackupAndReports.ps1
	
	ComputerName = $Env:USERDNSDOMAIN
	ADDomain = $Env:USERDNSDOMAIN
	Folder = $pwd
.EXAMPLE
	PS C:\PSScript > .\Get-GPOBackupAndReports.ps1 -ComputerName PDCeDC
	
	ComputerName = PDCeDC
	ADDomain = $Env:USERDNSDOMAIN
	Folder = $pwd
.EXAMPLE
	PS C:\PSScript > .\Get-GPOBackupAndReports.ps1 -ComputerName ChildPDCeDC -ADDomain ChildDomain.com
	
	Assuming the script is run from the parent domain.
	ComputerName = ChildPDCeDC
	ADDomain = ChildDomain.com
	Folder = $pwd
.EXAMPLE
	PS C:\PSScript > .\Get-GPOBackupAndReports.ps1 -ComputerName ChildPDCeDC -ADDomain ChildDomain.com -Folder c:\GPOReports
	
	Assuming the script is run from the parent domain.
	ComputerName = ChildPDCeDC
	ADDomain = ChildDomain.com
	Folder = C:\GPOReports (C:\GPOReports must already exist)
.EXAMPLE
	PS C:\PSScript > .\Get-GPOBackupAndReports.ps1 -SmtpServer mail.domain.tld
	-From XDAdmin@domain.tld -To ITGroup@domain.tld	
	
	The script will use the email server mail.domain.tld, sending from XDAdmin@domain.tld, 
	sending to ITGroup@domain.tld.
	
	The script will use the default SMTP port 25 and will not use SSL.
	
	If the current user's credentials are not valid to send email, 
	the user will be prompted to enter valid credentials.
.EXAMPLE
	PS C:\PSScript > .\Get-GPOBackupAndReports.ps1 -SmtpServer smtp.office365.com -SmtpPort 587
	-UseSSL -From Webster@CarlWebster.com -To ITGroup@CarlWebster.com	
	
	The script will use the email server smtp.office365.com on port 587 using SSL, 
	sending from webster@carlwebster.com, sending to ITGroup@carlwebster.com.
	
	If the current user's credentials are not valid to send email, 
	the user will be prompted to enter valid credentials.
.INPUTS
	None.  You cannot pipe objects to this script.
.OUTPUTS
	No objects are output from this script.
.NOTES
	NAME: Get-GPOBackupAndReports.ps1
	VERSION: 1.10
	AUTHOR: Carl Webster, Sr. Solutions Architect, Choice Solutions, LLC
	LASTEDIT: June 1, 2018
#>


[CmdletBinding(SupportsShouldProcess = $False, ConfirmImpact = "None", DefaultParameterSetName = "Default") ]

Param(
	[parameter(Mandatory=$False)] 
	[string]$ADDomain=$Env:USERDNSDOMAIN, 

	[parameter(Mandatory=$False)] 
	[Alias("ServerName")]
	[string]$ComputerName=$Env:USERDNSDOMAIN,
	
	[parameter(Mandatory=$False)] 
	[string]$Folder="",
	
	[parameter(Mandatory=$False)] 
	[int]$MaxZipSize=150,
	
	[parameter(ParameterSetName="SMTP",Mandatory=$True)] 
	[string]$SmtpServer="",

	[parameter(ParameterSetName="SMTP",Mandatory=$False)] 
	[int]$SmtpPort=25,

	[parameter(ParameterSetName="SMTP",Mandatory=$False)] 
	[switch]$UseSSL=$False,

	[parameter(ParameterSetName="SMTP",Mandatory=$True)] 
	[string]$From="",

	[parameter(ParameterSetName="SMTP",Mandatory=$True)] 
	[string]$To="",

	[parameter(Mandatory=$False)] 
	[Switch]$Dev=$False,
	
	[parameter(Mandatory=$False)] 
	[Alias("SI")]
	[Switch]$ScriptInfo=$False,
	
	[parameter(Mandatory=$False)] 
	[Switch]$Log=$False
	
	)

	
#webster@carlwebster.com
#Sr. Solutions Architect at Choice Solutions, LLC
#@carlwebster on Twitter
#http://www.CarlWebster.com
#Created on April 25, 2018

#Version 1.0 released to the community on 1-May-2018
#
#Version 1.10 1-Jun-2018
#
#	Add Parameter MaxZipSize (in MBs)
#		Test combined size of the two Zip files created to see if <= to MaxZipSize
#		If > MaxZipSize, do not attempt the email
#	Backup GPOs one at a time
#		Show the name of each GPO being backed up to show the GPO causing a backup error

Set-StrictMode -Version 2

#force  on
$PSDefaultParameterValues = @{"*:Verbose"=$True}
$SaveEAPreference = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'

#region check for DA and elevatation
Function UserIsaDomainAdmin
{
	#function adapted from sample code provided by Thomas Vuylsteke
	$IsDA = $False
	$name = $env:username
	Write-Verbose "$(Get-Date): TokenGroups - Checking groups for $name"

	$root = [ADSI]""
	$filter = "(sAMAccountName=$name)"
	$props = @("distinguishedName")
	$Searcher = new-Object System.DirectoryServices.DirectorySearcher($root,$filter,$props)
	$account = $Searcher.FindOne().properties.distinguishedname

	$user = [ADSI]"LDAP://$Account"
	$user.GetInfoEx(@("tokengroups"),0)
	$groups = $user.Get("tokengroups")

	$domainAdminsSID = New-Object System.Security.Principal.SecurityIdentifier (((Get-ADDomain -Server $ADDomain -EA 0).DomainSid).Value+"-512") 

	ForEach($group in $groups)
	{     
		$ID = New-Object System.Security.Principal.SecurityIdentifier($group,0)       
		If($ID.CompareTo($domainAdminsSID) -eq 0)
		{
			$IsDA = $True
			Break
		}     
	}

	Return $IsDA
}

Function ElevatedSession
{
	$currentPrincipal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent() )

	If($currentPrincipal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator ))
	{
		Write-Verbose "$(Get-Date): This is an elevated PowerShell session"
		Return $True
	}
	Else
	{
		Write-Host "" -Foreground White
		Write-Host "$(Get-Date): This is NOT an elevated PowerShell session" -Foreground White
		Write-Host "" -Foreground White
		Return $False
	}
}
#endregion

#region script setup function
Function ProcessScriptSetup
{
	$Script:GPOStartTime = Get-Date

	#make sure user is running the script with Domain Admin rights
	Write-Verbose "$(Get-Date): Testing to see if $env:username has Domain Admin rights"
	$AmIReallyDA = UserIsaDomainAdmin
	If($AmIReallyDA -eq $True)
	{
		#user has Domain Admin rights
		Write-Verbose "$(Get-Date): $env:username has Domain Admin rights in the $ADDomain Domain"
	}
	Else
	{
		#user does not have Domain Admin rights
		Write-Error "$(Get-Date): $env:username does not have Domain Admin rights in the $ADDomain Domain. Script cannot continue."
		$ErrorActionPreference = $SaveEAPreference
		Exit
	}
	
	$Elevated = ElevatedSession
	
	If( -not $Elevated )
	{
		Write-Error "This is not an elevated PowerShell session. Script cannot continue."
		$ErrorActionPreference = $SaveEAPreference
		Exit
	}

	#if computer name is localhost, get actual server name
	If($ComputerName -eq "localhost")
	{
		$ComputerName = $env:ComputerName
		Write-Verbose "$(Get-Date): Server name has been changed from localhost to $($ComputerName)"
	}
	
	#see if default value of $Env:USERDNSDOMAIN was used
	If($ComputerName -eq $Env:USERDNSDOMAIN)
	{
		#change $ComputerName to a found global catalog server
		$Results = (Get-ADDomainController -DomainName $ADDomain -Discover -Service GlobalCatalog -EA 0).Name
		
		If($? -and $Null -ne $Results)
		{
			$ComputerName = $Results
			Write-Verbose "$(Get-Date): Server name has been changed from $Env:USERDNSDOMAIN to $ComputerName"
		}
		ElseIf(!$?) #changed for 2.16
		{
			#may be in a child domain where -Service GlobalCatalog doesn't work. Try PrimaryDC
			$Results = (Get-ADDomainController -DomainName $ADDomain -Discover -Service PrimaryDC -EA 0).Name

			If($? -and $Null -ne $Results)
			{
				$ComputerName = $Results
				Write-Verbose "$(Get-Date): Server name has been changed from $Env:USERDNSDOMAIN to $ComputerName"
			}
		}
	}

	#if computer name is an IP address, get host name from DNS
	#http://blogs.technet.com/b/gary/archive/2009/08/29/resolve-ip-addresses-to-hostname-using-powershell.aspx
	#help from Michael B. Smith
	$ip = $ComputerName -as [System.Net.IpAddress]
	If($ip)
	{
		$Result = [System.Net.Dns]::gethostentry($ip)
		
		If($? -and $Null -ne $Result)
		{
			$ComputerName = $Result.HostName
			Write-Verbose "$(Get-Date): Server name has been changed from $ip to $ComputerName"
		}
		Else
		{
			Write-Warning "Unable to resolve $ComputerName to a hostname"
		}
	}
	Else
	{
		#server is online but for some reason $ComputerName cannot be converted to a System.Net.IpAddress
	}

	If(![String]::IsNullOrEmpty($ComputerName)) 
	{
		#get server name
		#first test to make sure the server is reachable
		Write-Verbose "$(Get-Date): Testing to see if $ComputerName is online and reachable"
		If(Test-Connection -ComputerName $ComputerName -quiet -EA 0)
		{
			Write-Verbose "$(Get-Date): Server $ComputerName is online."
			Write-Verbose "$(Get-Date): `tTest #1 to see if $ComputerName is a Domain Controller."
			#the server may be online but is it really a domain controller?

			#is the ComputerName in the current domain
			$Results = Get-ADDomainController $ComputerName -EA 0
			
			If(!$? -or $Null -eq $Results)
			{
				#try using the Forest name
				Write-Verbose "$(Get-Date): `tTest #2 to see if $ComputerName is a Domain Controller."
				$Results = Get-ADDomainController $ComputerName -Server $ADDomain -EA 0
				If(!$?)
				{
					$ErrorActionPreference = $SaveEAPreference
					Write-Error "`n`n`t`t$ComputerName is not a domain controller for $ADDomain.`n`t`tScript cannot continue.`n`n"
					$ErrorActionPreference = $SaveEAPreference
					Exit
				}
				Else
				{
					Write-Verbose "$(Get-Date): `tTest #2 succeeded. $ComputerName is a Domain Controller."
				}
			}
			Else
			{
				Write-Verbose "$(Get-Date): `tTest #1 succeeded. $ComputerName is a Domain Controller."
			}
			
			$Results = $Null
		}
		Else
		{
			Write-Error "Computer $ComputerName is offline.`nScript cannot continue.`n`n"
			$ErrorActionPreference = $SaveEAPreference
			Exit
		}
	}

	If([String]::IsNullOrEmpty($ComputerName))
	{
		$results = Get-ADDomain -Identity $ADDomain -EA 0
		
		If(!$?)
		{
			Write-Error "Could not find a domain identified by: $ADDomain.`nScript cannot continue.`n`n"
			$ErrorActionPreference = $SaveEAPreference
			Exit
		}
	}
	Else
	{
		$results = Get-ADDomain -Identity $ADDomain -Server $ComputerName -EA 0

		If(!$?)
		{
			Write-Error "Could not find a domain with the name of $ADDomain.`n`n`t`tScript cannot continue.`n`n`t`tIs $ComputerName running Active Directory Web Services?"
			$ErrorActionPreference = $SaveEAPreference
			Exit
		}
	}
	Write-Verbose "$(Get-Date): $ADDomain is a valid domain name"

	If($Folder -ne "")
	{
		Write-Verbose "$(Get-Date): Testing folder path"
		#does it exist
		If(Test-Path $Folder -EA 0)
		{
			#it exists, now check to see if it is a folder and not a file
			If(Test-Path $Folder -pathType Container -EA 0)
			{
				#it exists and it is a folder
				Write-Verbose "$(Get-Date): Folder path $Folder exists and is a folder"
			}
			Else
			{
				#it exists but it is a file not a folder
				Write-Error "Folder $Folder is a file, not a folder.  Script cannot continue"
				$ErrorActionPreference = $SaveEAPreference
				Exit
			}
		}
		Else
		{
			#does not exist
			Write-Error "Folder $Folder does not exist.  Script cannot continue"
			$ErrorActionPreference = $SaveEAPreference
			Exit
		}
	}

	If($Folder -eq "")
	{
		$Script:pwdPath = $pwd.Path
	}
	Else
	{
		$Script:pwdPath = $Folder
	}

	If($Script:pwdPath.EndsWith("\"))
	{
		#remove the trailing \
		$Script:pwdPath = $Script:pwdPath.SubString(0, ($Script:pwdPath.Length - 1))
	}

	If($Dev)
	{
		$Error.Clear()
		$Script:DevErrorFile = "$($Script:pwdPath)\Get-GPOBackupAndReportsScriptErrors_$(Get-Date -f yyyy-MM-dd_HHmm).txt"
	}

	If($Log) 
	{
		#start transcript logging
		$Script:LogPath = "$($Script:pwdPath)\Get-GPOBackupAndReportsScriptTranscript_$(Get-Date -f yyyy-MM-dd_HHmm).txt"
		
		try 
		{
			Start-Transcript -Path $Script:LogPath -Force -Verbose:$false | Out-Null
			Write-Verbose "$(Get-Date): Transcript/log started at $Script:LogPath"
			$Script:StartLog = $true
		} 
		catch 
		{
			Write-Verbose "$(Get-Date): Transcript/log failed at $Script:LogPath"
			$Script:StartLog = $false
		}
	}

	[string]$Script:RunningOS = (Get-WmiObject -class Win32_OperatingSystem -EA 0).Caption

	#enter the email creds
	If(![System.String]::IsNullOrEmpty( $SmtpServer ))
	{
		$Script:emailCredentials = Get-Credential -Message "Enter the email account and password to send email"
	}
}
#endregion

#region email function
Function SendEmail
{
	Param([array]$Attachments)
	Write-Verbose "$(Get-Date): Prepare to email"
	
	$Success = $True
	$emailAttachment = $Attachments
	$emailSubject = "GPO Backup and Reports for $ADDomain"
	$emailBody = @"
Hello, <br />
<br />
$emailsubject is attached.
"@ 

	If($Dev)
	{
		Out-File -FilePath $Script:DevErrorFile -InputObject $error 4>$Null
	}

	$error.Clear()

	If($UseSSL)
	{
		Write-Verbose "$(Get-Date): Trying to send email using current user's credentials with SSL"
		Send-MailMessage -Attachments $emailAttachment -Body $emailBody -BodyAsHtml -From $From `
		-Port $SmtpPort -SmtpServer $SmtpServer -Subject $emailSubject -To $To `
		-UseSSL -credential $emailCredentials *>$Null
	}
	Else
	{
		Write-Verbose  "$(Get-Date): Trying to send email using current user's credentials without SSL"
		Send-MailMessage -Attachments $emailAttachment -Body $emailBody -BodyAsHtml -From $From `
		-Port $SmtpPort -SmtpServer $SmtpServer -Subject $emailSubject -To $To -credential $emailCredentials *>$Null
	}

	$e = $error[0]

	If($e.Exception.ToString().Contains("5.7.57"))
	{
		#The server response was: 5.7.57 SMTP; Client was not authenticated to send anonymous mail during MAIL FROM
		Write-Verbose "$(Get-Date): Current user's credentials failed. Ask for usable credentials."

		If($Dev)
		{
			Out-File -FilePath $Script:DevErrorFile -InputObject $error -Append 4>$Null
		}

		$error.Clear()

		$emailCredentials = Get-Credential -Message "Enter the email account and password to send email"

		If($UseSSL)
		{
			Send-MailMessage -Attachments $emailAttachment -Body $emailBody -BodyAsHtml -From $From `
			-Port $SmtpPort -SmtpServer $SmtpServer -Subject $emailSubject -To $To `
			-UseSSL -credential $emailCredentials *>$Null 
		}
		Else
		{
			Send-MailMessage -Attachments $emailAttachment -Body $emailBody -BodyAsHtml -From $From `
			-Port $SmtpPort -SmtpServer $SmtpServer -Subject $emailSubject -To $To `
			-credential $emailCredentials *>$Null 
		}

		$e = $error[0]

		If($? -and $Null -eq $e)
		{
			Write-Verbose "$(Get-Date): Email successfully sent using new credentials"
		}
		Else
		{
			Write-Verbose "$(Get-Date): Email was not sent:"
			Write-Warning "$(Get-Date): Exception: $e.Exception" 
			$Success = $False
		}
	}
	Else
	{
		Write-Verbose "$(Get-Date): Email was not sent:"
		Write-Warning "$(Get-Date): Exception: $e.Exception" 
		$Success = $False
	}

    If($Success)
    {
        Return $True
    }
    Else
    {
        Return $False
    }
}
#endregion

#region main function
Function GetGpoBackupAndReports
{
	Write-Verbose "$(Get-Date): Retrieving all GPOs"
	$GPOs = @(Get-GPO -All -EA 0)

	If($? -and $Null -ne $GPOs)
	{
		[int]$GPOCnt = $GPOs.Count

		$GPOs = $GPOs | Sort-Object -Property DisplayName
		
		Write-Verbose "$(Get-Date): Creating Backup and Reports folders"
		$ScriptDir = $Script:pwdPath
		$BackupDir = "$($ScriptDir)\GPOBackups"
		$ReportsDir = "$($ScriptDir)\GPOReports"
		New-Item -Path $BackupDir -Force -ItemType "directory" *> $Null
		New-Item -Path $ReportsDir -Force -ItemType "directory" *> $Null

		Write-Verbose "$(Get-Date): Backing up $GPOCnt GPOs to $BackupDir"
		#$Results = Backup-GPO -All -Path $BackupDir -EA 0 *> $Null
		
		#V1.10, backup individual GPO to show which GPO causes the backup to fail
		
		ForEach($GPO in $GPOs)
		{
			Write-Verbose "$(Get-Date): Backing up GPO $($GPO.DisplayName)"
			$Null = Backup-GPO -Name $GPO.DisplayName -Path $BackupDir -EA 0 *> $Null
			
			If(!($?))
			{
				Write-Warning "`t`t`tUnable to backup GPO $($GPO.DisplayName)"
			}
		}

		ForEach($GPO in $GPOs)
		{
			Write-Verbose "$(Get-Date): Creating reports for GPO $($GPO.DisplayName)"
			$Results = Get-GPOReport -Name $GPO.DisplayName -ReportType HTML -Path "$($ReportsDir)\$($GPO.DisplayName).html" 
			
			If(!($?))
			{
				Write-Warning "Unable to create an HTML report for GPO $($GPO.DisplayName)"
			}

			$Results = Get-GPOReport -Name $GPO.DisplayName -ReportType XML -Path "$($ReportsDir)\$($GPO.DisplayName).xml" 
			
			If(!($?))
			{
				Write-Warning "Unable to create an XML report for GPO $($GPO.DisplayName)"
			}
		}
	}
	ElseIf($? -and $Null -eq $GPOs)
	{
		Write-Warning "No GPOs were found. Script cannot continue."
		$ErrorActionPreference = $SaveEAPreference
		Exit
	}
	Else
	{
		Write-Error "Unable to retrieve GPOs. Script cannot continue."
		$ErrorActionPreference = $SaveEAPreference
		Exit
	}
}
#endregion

#region script end
Function ProcessScriptEnd
{
	Write-Verbose "$(Get-Date): Script has completed"
	Write-Verbose "$(Get-Date): "

	Write-Verbose "$(Get-Date): Creating First Zip File"
	$ScriptDir = $Script:pwdPath
	$BackupDir = "$($ScriptDir)\GPOBackups"
	$ReportsDir = "$($ScriptDir)\GPOReports"

	[Reflection.Assembly]::LoadWithPartialName( "System.IO.Compression.FileSystem" ) > $Null
	[System.AppDomain]::CurrentDomain.GetAssemblies() > $Null
	$src_folder = $BackupDir
	$destfile1 = "$ScriptDir\_GetGPOBackup_$($ADDomain).zip"
	$compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
	$includebasedir = $true
	[System.IO.Compression.ZipFile]::CreateFromDirectory($src_folder, $destfile1, $compressionLevel, $includebasedir) > $Null

	Write-Verbose "$(Get-Date): Creating second Zip File"
	$src_folder = $ReportsDir
	$destfile2 = "$ScriptDir\_GetGPOReports_$($ADDomain).zip"
	$compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
	$includebasedir = $true
	[System.IO.Compression.ZipFile]::CreateFromDirectory($src_folder, $destfile2, $compressionLevel, $includebasedir) > $Null

	#email zip files if requested
	If(![System.String]::IsNullOrEmpty( $SmtpServer ))
	{
		#V1.10, check the size of the combined zip files to see if the size is smaller than MaxZipSize (150MB by default)
		$Zip1Size = ([System.IO.FileInfo]$destfile1).Length
		$Zip1Size = ([math]::round(($Zip1Size/1MB),3))

		$Zip2Size = ([System.IO.FileInfo]$destfile2).Length
		$Zip2Size = ([math]::round(($Zip2Size/1MB),3))
		
		$TotalZipSize = $Zip1Size + $Zip2Size

		If($TotalZipSize -le $MaxZipSize)
		{
			Write-Verbose "$(Get-Date): Combined size of the two zip files is $TotalZipSize MB. Proceeding with email attempt."
			Write-Verbose "$(Get-Date): Sending email"
			$emailattachment = @()
			$emailAttachment += $destfile1
			$emailAttachment += $destfile2
			$MailSuccess = SendEmail $emailAttachment
			If($MailSuccess)
			{
				Write-Verbose "$(Get-Date): Email sent"
			}
			Else
			{
				Write-Host "$(Get-Date): Unable to send $emailAttachment via email" -ForegroundColor Red
				Write-Host "$(Get-Date): Please send $emailAttachment to $To" -ForegroundColor Red
			}
		}
		Else
		{
			Write-Verbose "$(Get-Date): Combined size of the two zip files is $TotalZipSize. Cancel email attempt."
			Write-Host "$(Get-Date): Unable to send $emailAttachment via email because of MaxZipSize limit" -ForegroundColor Red
			Write-Host "$(Get-Date): Please send $emailAttachment to $To" -ForegroundColor Red
		}
	}    

	Write-Verbose "$(Get-Date): Script started: $($Script:GPOStartTime)"
	Write-Verbose "$(Get-Date): Script ended: $(Get-Date)"
	$runtime = $(Get-Date) - $Script:GPOStartTime
	$Str = [string]::format("{0} days, {1} hours, {2} minutes, {3}.{4} seconds",
		$runtime.Days,
		$runtime.Hours,
		$runtime.Minutes,
		$runtime.Seconds,
		$runtime.Milliseconds)
	Write-Verbose "$(Get-Date): Elapsed time: $($Str)"

	If($Dev)
	{
		Out-File -FilePath $Script:DevErrorFile -InputObject $error -Append 4>$Null
	}

	If($ScriptInfo)
	{
		$SIFile = "$($Script:pwdPath)\GetGpoBackupAndReportsScriptInfo_$(Get-Date -f yyyy-MM-dd_HHmm).txt"
		Out-File -FilePath $SIFile -InputObject "" 4>$Null
		Out-File -FilePath $SIFile -Append -InputObject "ComputerName   : $ComputerName" 4>$Null
		Out-File -FilePath $SIFile -Append -InputObject "Dev            : $Dev" 4>$Null
		If($Dev)
		{
			Out-File -FilePath $SIFile -Append -InputObject "DevErrorFile   : $Script:DevErrorFile" 4>$Null
		}
		Out-File -FilePath $SIFile -Append -InputObject "Domain name    : $ADDomain" 4>$Null
		Out-File -FilePath $SIFile -Append -InputObject "Folder         : $Folder" 4>$Null
		Out-File -FilePath $SIFile -Append -InputObject "Log            : $($Log)" 4>$Null
		Out-File -FilePath $SIFile -Append -InputObject "Script Info    : $ScriptInfo" 4>$Null
		Out-File -FilePath $SIFile -Append -InputObject "" 4>$Null
		Out-File -FilePath $SIFile -Append -InputObject "OS Detected    : $Script:RunningOS" 4>$Null
		Out-File -FilePath $SIFile -Append -InputObject "PoSH version   : $($Host.Version)" 4>$Null
	}

	#stop transcript logging
	If($Log -eq $True) 
	{
		If($Script:StartLog -eq $true) 
		{
			try 
			{
				Stop-Transcript | Out-Null
				Write-Verbose "$(Get-Date): $Script:LogPath is ready for use"
			} 
			catch 
			{
				Write-Verbose "$(Get-Date): Transcript/log stop failed"
			}
		}
	}
	$ErrorActionPreference = $SaveEAPreference
}
#endregion

#region script core
#Script begins

ProcessScriptSetup

GetGpoBackupAndReports
#endregion

#region finish script
Write-Verbose "$(Get-Date): Finishing up script"
#end of document processing

ProcessScriptEnd
[gc]::collect()
#endregion


# SIG # Begin signature block
# MIIhUgYJKoZIhvcNAQcCoIIhQzCCIT8CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUF8bmoOPw0L+OHg4tEmxsMMj0
# Q3qgghy8MIIDtzCCAp+gAwIBAgIQDOfg5RfYRv6P5WD8G/AwOTANBgkqhkiG9w0B
# AQUFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVk
# IElEIFJvb3QgQ0EwHhcNMDYxMTEwMDAwMDAwWhcNMzExMTEwMDAwMDAwWjBlMQsw
# CQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cu
# ZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3Qg
# Q0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCtDhXO5EOAXLGH87dg
# +XESpa7cJpSIqvTO9SA5KFhgDPiA2qkVlTJhPLWxKISKityfCgyDF3qPkKyK53lT
# XDGEKvYPmDI2dsze3Tyoou9q+yHyUmHfnyDXH+Kx2f4YZNISW1/5WBg1vEfNoTb5
# a3/UsDg+wRvDjDPZ2C8Y/igPs6eD1sNuRMBhNZYW/lmci3Zt1/GiSw0r/wty2p5g
# 0I6QNcZ4VYcgoc/lbQrISXwxmDNsIumH0DJaoroTghHtORedmTpyoeb6pNnVFzF1
# roV9Iq4/AUaG9ih5yLHa5FcXxH4cDrC0kqZWs72yl+2qp/C3xag/lRbQ/6GW6whf
# GHdPAgMBAAGjYzBhMA4GA1UdDwEB/wQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB0G
# A1UdDgQWBBRF66Kv9JLLgjEtUYunpyGd823IDzAfBgNVHSMEGDAWgBRF66Kv9JLL
# gjEtUYunpyGd823IDzANBgkqhkiG9w0BAQUFAAOCAQEAog683+Lt8ONyc3pklL/3
# cmbYMuRCdWKuh+vy1dneVrOfzM4UKLkNl2BcEkxY5NM9g0lFWJc1aRqoR+pWxnmr
# EthngYTffwk8lOa4JiwgvT2zKIn3X/8i4peEH+ll74fg38FnSbNd67IJKusm7Xi+
# fT8r87cmNW1fiQG2SVufAQWbqz0lwcy2f8Lxb4bG+mRo64EtlOtCt/qMHt1i8b5Q
# Z7dsvfPxH2sMNgcWfzd8qVttevESRmCD1ycEvkvOl77DZypoEd+A5wwzZr8TDRRu
# 838fYxAe+o0bJW1sj6W3YQGx0qMmoRBxna3iw/nDmVG3KwcIzi7mULKn+gpFL6Lw
# 8jCCBRcwggP/oAMCAQICEAs/+4v3K5kWNoIKRSzDCywwDQYJKoZIhvcNAQEFBQAw
# bzELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQ
# d3d3LmRpZ2ljZXJ0LmNvbTEuMCwGA1UEAxMlRGlnaUNlcnQgQXNzdXJlZCBJRCBD
# b2RlIFNpZ25pbmcgQ0EtMTAeFw0xODAxMjQwMDAwMDBaFw0xODEwMDMxMjAwMDBa
# MGMxCzAJBgNVBAYTAlVTMRIwEAYDVQQIEwlUZW5uZXNzZWUxEjAQBgNVBAcTCVR1
# bGxhaG9tYTEVMBMGA1UEChMMQ2FybCBXZWJzdGVyMRUwEwYDVQQDEwxDYXJsIFdl
# YnN0ZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDH/nMD6igNuEEO
# vbZVq8IgjA4AXGrSlDdTZWMN3UGjnlXtzIBEDh+aGhQLVZKouCZOYfTNhXAy5Ceu
# YuzV3c/aK3AozhzDjEnIb9tzL1P+NoqurIvQ11PR8mTPIbr4Y4CkwwHRbD9khZsm
# nzeDa+ndpFqHlXRgTRTwNC59I2A8V7TynrTFdHAAFAeciIgdxwNBvZFMB/4Rr25P
# 19Vfl+gLQ/Fe0NONkWRjvFdPayU5kxIfaXOnHdOHv6k+7S8eL70OkwYROHL0Ppw4
# nnv6skeedwEGh+FAsfBCOgCFe7Qqv5THdeeIx3aMEShgAghtdvP+JlqEZkmJGxv+
# JhH7G5I1AgMBAAGjggG5MIIBtTAfBgNVHSMEGDAWgBR7aM4pqsAXvkl64eU/1qf3
# RY81MjAdBgNVHQ4EFgQUQ+FwfwgCQpprAv5bJC0lEVQ6NC4wDgYDVR0PAQH/BAQD
# AgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMG0GA1UdHwRmMGQwMKAuoCyGKmh0dHA6
# Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9hc3N1cmVkLWNzLWcxLmNybDAwoC6gLIYqaHR0
# cDovL2NybDQuZGlnaWNlcnQuY29tL2Fzc3VyZWQtY3MtZzEuY3JsMEwGA1UdIARF
# MEMwNwYJYIZIAYb9bAMBMCowKAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2lj
# ZXJ0LmNvbS9DUFMwCAYGZ4EMAQQBMIGCBggrBgEFBQcBAQR2MHQwJAYIKwYBBQUH
# MAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBMBggrBgEFBQcwAoZAaHR0cDov
# L2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEQ29kZVNpZ25p
# bmdDQS0xLmNydDAMBgNVHRMBAf8EAjAAMA0GCSqGSIb3DQEBBQUAA4IBAQCG2/4m
# CXx6RqoW275xcEGAIrDibOBaB8AOunAkoQHN8j41/Nh+h4wuaL6yT+cKsUF5Oypk
# rKJmQIM1Y0nokG6fRtlrcddt+upV9i/4vgE8PtHlMYgkZpmCsjki43+HDcxBTSAg
# vM8UesAFHjD2QTCV5m8cMVl8735eVo+kY6u2QKfZa4Hz4q23uk6Zr6AtUFEdphR8
# i9UBUUs64nJq9NiANBkLq/CSxoB49j+9j1O1UW5hbr8SJE0PSVsZx1w8VggQPfMG
# igZeR8o2TNZQx3D+k/BCmblsFYsjQ1kV83npUkGIXkYtFJeyeEY8KjvY+IDMsQ9k
# ikgqJni2uJjdKEMYMIIGajCCBVKgAwIBAgIQAwGaAjr/WLFr1tXq5hfwZjANBgkq
# hkiG9w0BAQUFADBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5j
# MRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBB
# c3N1cmVkIElEIENBLTEwHhcNMTQxMDIyMDAwMDAwWhcNMjQxMDIyMDAwMDAwWjBH
# MQswCQYDVQQGEwJVUzERMA8GA1UEChMIRGlnaUNlcnQxJTAjBgNVBAMTHERpZ2lD
# ZXJ0IFRpbWVzdGFtcCBSZXNwb25kZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAw
# ggEKAoIBAQCjZF38fLPggjXg4PbGKuZJdTvMbuBTqZ8fZFnmfGt/a4ydVfiS457V
# WmNbAklQ2YPOb2bu3cuF6V+l+dSHdIhEOxnJ5fWRn8YUOawk6qhLLJGJzF4o9GS2
# ULf1ErNzlgpno75hn67z/RJ4dQ6mWxT9RSOOhkRVfRiGBYxVh3lIRvfKDo2n3k5f
# 4qi2LVkCYYhhchhoubh87ubnNC8xd4EwH7s2AY3vJ+P3mvBMMWSN4+v6GYeofs/s
# jAw2W3rBerh4x8kGLkYQyI3oBGDbvHN0+k7Y/qpA8bLOcEaD6dpAoVk62RUJV5lW
# MJPzyWHM0AjMa+xiQpGsAsDvpPCJEY93AgMBAAGjggM1MIIDMTAOBgNVHQ8BAf8E
# BAMCB4AwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDCCAb8G
# A1UdIASCAbYwggGyMIIBoQYJYIZIAYb9bAcBMIIBkjAoBggrBgEFBQcCARYcaHR0
# cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzCCAWQGCCsGAQUFBwICMIIBVh6CAVIA
# QQBuAHkAIAB1AHMAZQAgAG8AZgAgAHQAaABpAHMAIABDAGUAcgB0AGkAZgBpAGMA
# YQB0AGUAIABjAG8AbgBzAHQAaQB0AHUAdABlAHMAIABhAGMAYwBlAHAAdABhAG4A
# YwBlACAAbwBmACAAdABoAGUAIABEAGkAZwBpAEMAZQByAHQAIABDAFAALwBDAFAA
# UwAgAGEAbgBkACAAdABoAGUAIABSAGUAbAB5AGkAbgBnACAAUABhAHIAdAB5ACAA
# QQBnAHIAZQBlAG0AZQBuAHQAIAB3AGgAaQBjAGgAIABsAGkAbQBpAHQAIABsAGkA
# YQBiAGkAbABpAHQAeQAgAGEAbgBkACAAYQByAGUAIABpAG4AYwBvAHIAcABvAHIA
# YQB0AGUAZAAgAGgAZQByAGUAaQBuACAAYgB5ACAAcgBlAGYAZQByAGUAbgBjAGUA
# LjALBglghkgBhv1sAxUwHwYDVR0jBBgwFoAUFQASKxOYspkH7R7for5XDStnAs0w
# HQYDVR0OBBYEFGFaTSS2STKdSip5GoNL9B6Jwcp9MH0GA1UdHwR2MHQwOKA2oDSG
# Mmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRENBLTEu
# Y3JsMDigNqA0hjJodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1
# cmVkSURDQS0xLmNybDB3BggrBgEFBQcBAQRrMGkwJAYIKwYBBQUHMAGGGGh0dHA6
# Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBBBggrBgEFBQcwAoY1aHR0cDovL2NhY2VydHMu
# ZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEQ0EtMS5jcnQwDQYJKoZIhvcN
# AQEFBQADggEBAJ0lfhszTbImgVybhs4jIA+Ah+WI//+x1GosMe06FxlxF82pG7xa
# FjkAneNshORaQPveBgGMN/qbsZ0kfv4gpFetW7easGAm6mlXIV00Lx9xsIOUGQVr
# NZAQoHuXx/Y/5+IRQaa9YtnwJz04HShvOlIJ8OxwYtNiS7Dgc6aSwNOOMdgv420X
# Ewbu5AO2FKvzj0OncZ0h3RTKFV2SQdr5D4HRmXQNJsQOfxu19aDxxncGKBXp2JPl
# VRbwuwqrHNtcSCdmyKOLChzlldquxC5ZoGHd2vNtomHpigtt7BIYvfdVVEADkitr
# wlHCCkivsNRu4PQUCjob4489yq9qjXvc2EQwggajMIIFi6ADAgECAhAPqEkGFdcA
# oL4hdv3F7G29MA0GCSqGSIb3DQEBBQUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNV
# BAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0xMTAyMTExMjAwMDBa
# Fw0yNjAyMTAxMjAwMDBaMG8xCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2Vy
# dCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xLjAsBgNVBAMTJURpZ2lD
# ZXJ0IEFzc3VyZWQgSUQgQ29kZSBTaWduaW5nIENBLTEwggEiMA0GCSqGSIb3DQEB
# AQUAA4IBDwAwggEKAoIBAQCcfPmgjwrKiUtTmjzsGSJ/DMv3SETQPyJumk/6zt/G
# 0ySR/6hSk+dy+PFGhpTFqxf0eH/Ler6QJhx8Uy/lg+e7agUozKAXEUsYIPO3vfLc
# y7iGQEUfT/k5mNM7629ppFwBLrFm6aa43Abero1i/kQngqkDw/7mJguTSXHlOG1O
# /oBcZ3e11W9mZJRru4hJaNjR9H4hwebFHsnglrgJlflLnq7MMb1qWkKnxAVHfWAr
# 2aFdvftWk+8b/HL53z4y/d0qLDJG2l5jvNC4y0wQNfxQX6xDRHz+hERQtIwqPXQM
# 9HqLckvgVrUTtmPpP05JI+cGFvAlqwH4KEHmx9RkO12rAgMBAAGjggNDMIIDPzAO
# BgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUHAwMwggHDBgNVHSAEggG6
# MIIBtjCCAbIGCGCGSAGG/WwDMIIBpDA6BggrBgEFBQcCARYuaHR0cDovL3d3dy5k
# aWdpY2VydC5jb20vc3NsLWNwcy1yZXBvc2l0b3J5Lmh0bTCCAWQGCCsGAQUFBwIC
# MIIBVh6CAVIAQQBuAHkAIAB1AHMAZQAgAG8AZgAgAHQAaABpAHMAIABDAGUAcgB0
# AGkAZgBpAGMAYQB0AGUAIABjAG8AbgBzAHQAaQB0AHUAdABlAHMAIABhAGMAYwBl
# AHAAdABhAG4AYwBlACAAbwBmACAAdABoAGUAIABEAGkAZwBpAEMAZQByAHQAIABD
# AFAALwBDAFAAUwAgAGEAbgBkACAAdABoAGUAIABSAGUAbAB5AGkAbgBnACAAUABh
# AHIAdAB5ACAAQQBnAHIAZQBlAG0AZQBuAHQAIAB3AGgAaQBjAGgAIABsAGkAbQBp
# AHQAIABsAGkAYQBiAGkAbABpAHQAeQAgAGEAbgBkACAAYQByAGUAIABpAG4AYwBv
# AHIAcABvAHIAYQB0AGUAZAAgAGgAZQByAGUAaQBuACAAYgB5ACAAcgBlAGYAZQBy
# AGUAbgBjAGUALjASBgNVHRMBAf8ECDAGAQH/AgEAMHkGCCsGAQUFBwEBBG0wazAk
# BggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAC
# hjdodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURS
# b290Q0EuY3J0MIGBBgNVHR8EejB4MDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2Vy
# dC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8v
# Y3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMB0G
# A1UdDgQWBBR7aM4pqsAXvkl64eU/1qf3RY81MjAfBgNVHSMEGDAWgBRF66Kv9JLL
# gjEtUYunpyGd823IDzANBgkqhkiG9w0BAQUFAAOCAQEAe3IdZP+IyDrBt+nnqcSH
# u9uUkteQWTP6K4feqFuAJT8Tj5uDG3xDxOaM3zk+wxXssNo7ISV7JMFyXbhHkYET
# RvqcP2pRON60Jcvwq9/FKAFUeRBGJNE4DyahYZBNur0o5j/xxKqb9to1U0/J8j3T
# bNwj7aqgTWcJ8zqAPTz7NkyQ53ak3fI6v1Y1L6JMZejg1NrRx8iRai0jTzc7GZQY
# 1NWcEDzVsRwZ/4/Ia5ue+K6cmZZ40c2cURVbQiZyWo0KSiOSQOiG3iLCkzrUm2im
# 3yl/Brk8Dr2fxIacgkdCcTKGCZlyCXlLnXFp9UH/fzl3ZPGEjb6LHrJ9aKOlkLEM
# /zCCBs0wggW1oAMCAQICEAb9+QOWA63qAArrPye7uhswDQYJKoZIhvcNAQEFBQAw
# ZTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQ
# d3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBS
# b290IENBMB4XDTA2MTExMDAwMDAwMFoXDTIxMTExMDAwMDAwMFowYjELMAkGA1UE
# BhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2lj
# ZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgQXNzdXJlZCBJRCBDQS0xMIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA6IItmfnKwkKVpYBzQHDSnlZUXKnE
# 0kEGj8kz/E1FkVyBn+0snPgWWd+etSQVwpi5tHdJ3InECtqvy15r7a2wcTHrzzpA
# DEZNk+yLejYIA6sMNP4YSYL+x8cxSIB8HqIPkg5QycaH6zY/2DDD/6b3+6LNb3Mj
# /qxWBZDwMiEWicZwiPkFl32jx0PdAug7Pe2xQaPtP77blUjE7h6z8rwMK5nQxl0S
# QoHhg26Ccz8mSxSQrllmCsSNvtLOBq6thG9IhJtPQLnxTPKvmPv2zkBdXPao8S+v
# 7Iki8msYZbHBc63X8djPHgp0XEK4aH631XcKJ1Z8D2KkPzIUYJX9BwSiCQIDAQAB
# o4IDejCCA3YwDgYDVR0PAQH/BAQDAgGGMDsGA1UdJQQ0MDIGCCsGAQUFBwMBBggr
# BgEFBQcDAgYIKwYBBQUHAwMGCCsGAQUFBwMEBggrBgEFBQcDCDCCAdIGA1UdIASC
# AckwggHFMIIBtAYKYIZIAYb9bAABBDCCAaQwOgYIKwYBBQUHAgEWLmh0dHA6Ly93
# d3cuZGlnaWNlcnQuY29tL3NzbC1jcHMtcmVwb3NpdG9yeS5odG0wggFkBggrBgEF
# BQcCAjCCAVYeggFSAEEAbgB5ACAAdQBzAGUAIABvAGYAIAB0AGgAaQBzACAAQwBl
# AHIAdABpAGYAaQBjAGEAdABlACAAYwBvAG4AcwB0AGkAdAB1AHQAZQBzACAAYQBj
# AGMAZQBwAHQAYQBuAGMAZQAgAG8AZgAgAHQAaABlACAARABpAGcAaQBDAGUAcgB0
# ACAAQwBQAC8AQwBQAFMAIABhAG4AZAAgAHQAaABlACAAUgBlAGwAeQBpAG4AZwAg
# AFAAYQByAHQAeQAgAEEAZwByAGUAZQBtAGUAbgB0ACAAdwBoAGkAYwBoACAAbABp
# AG0AaQB0ACAAbABpAGEAYgBpAGwAaQB0AHkAIABhAG4AZAAgAGEAcgBlACAAaQBu
# AGMAbwByAHAAbwByAGEAdABlAGQAIABoAGUAcgBlAGkAbgAgAGIAeQAgAHIAZQBm
# AGUAcgBlAG4AYwBlAC4wCwYJYIZIAYb9bAMVMBIGA1UdEwEB/wQIMAYBAf8CAQAw
# eQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2Vy
# dC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9E
# aWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwgYEGA1UdHwR6MHgwOqA4oDaGNGh0
# dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5j
# cmwwOqA4oDaGNGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3Vy
# ZWRJRFJvb3RDQS5jcmwwHQYDVR0OBBYEFBUAEisTmLKZB+0e36K+Vw0rZwLNMB8G
# A1UdIwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA0GCSqGSIb3DQEBBQUAA4IB
# AQBGUD7Jtygkpzgdtlspr1LPUukxR6tWXHvVDQtBs+/sdR90OPKyXGGinJXDUOSC
# uSPRujqGcq04eKx1XRcXNHJHhZRW0eu7NoR3zCSl8wQZVann4+erYs37iy2QwsDS
# tZS9Xk+xBdIOPRqpFFumhjFiqKgz5Js5p8T1zh14dpQlc+Qqq8+cdkvtX8JLFuRL
# cEwAiR78xXm8TBJX/l/hHrwCXaj++wc4Tw3GXZG5D2dFzdaD7eeSDY2xaYxP+1ng
# Iw/Sqq4AfO6cQg7PkdcntxbuD8O9fAqg7iwIVYUiuOsYGk38KiGtSTGDR5V3cdyx
# G0tLHBCcdxTBnU8vWpUIKRAmMYIEADCCA/wCAQEwgYMwbzELMAkGA1UEBhMCVVMx
# FTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNv
# bTEuMCwGA1UEAxMlRGlnaUNlcnQgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0Et
# MQIQCz/7i/crmRY2ggpFLMMLLDAJBgUrDgMCGgUAoEAwGQYJKoZIhvcNAQkDMQwG
# CisGAQQBgjcCAQQwIwYJKoZIhvcNAQkEMRYEFALT7ZBByEXv1QC5CYWUbjHMF8p5
# MA0GCSqGSIb3DQEBAQUABIIBAJYnIyzNmx19LW27vVKmPUNQ8CGrJkWgZpuy4YqX
# O3YEd1rt7trm/vQlhd/ApEr5h7/5BKlIhKc/CiWhY8yQ+D7A8INn8STY60GD+S8E
# lUEW/J+lmWmzj+CVTa70q/7yr3rf6YIqZp51vnGM2pUb9znqgaHsHxraIU5l1R46
# sr4mjIT1fn/fU7J6I8VG3NLQfMBxk1Jmt2W52LV2aC01dbbuvogaX66YywIiEKef
# lJW4AEACOpQGP/crT+Sv+MRWYdAjL2jtiMre084R7IiiWwZa/W5RdOv93k5R1FzW
# of6PmoOrv2Bjlff/Qn4YnDWheMDmGNT+GnnJzmx23vaQVr2hggIPMIICCwYJKoZI
# hvcNAQkGMYIB/DCCAfgCAQEwdjBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGln
# aUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhE
# aWdpQ2VydCBBc3N1cmVkIElEIENBLTECEAMBmgI6/1ixa9bV6uYX8GYwCQYFKw4D
# AhoFAKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8X
# DTE4MDYwMTE4MDU0N1owIwYJKoZIhvcNAQkEMRYEFI/qLYeJhfbxJtk3MfeLZNId
# eiVrMA0GCSqGSIb3DQEBAQUABIIBAGBtQIpsZKuAMx02YFZz9KPMEaXqGFiR41Yb
# ICjPRztlMQvP0UyEAYOzxj8VJGNUHB4SO3/uNoIR3peTPMNLDbDBNyTYGU8VnJ7t
# P7G9FUDCjm7Qt0unmI8IBFHs/3xPixpfBsjO1kZ07qb1L3yQWfk7WRcSe6qSt5mU
# Ban3TJeb8fcCXs2leSLYDBCr5lZJ8MG2JDFmvJ5bwJxPctdMZGzNivakfC45bewr
# KYKMKfT5dA342Zov5pFtXWfm7YQr9u926aWGSaelglJjzaBzmc43McHm1GyuPshi
# eS4xv/sZj60/Fu0TQWpX/5hdsELRfx84zarAouCRFhDTw9UQXNk=
# SIG # End signature block
