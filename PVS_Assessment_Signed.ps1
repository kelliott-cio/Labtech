<#
.SYNOPSIS
	Creates a basic assessment of a Citrix PVS 5.x, 6.x or 7.x farm.
.DESCRIPTION
	Creates a basic assessment of a Citrix PVS 5.x, 6.x or 7.x farm.
	Creates a text document named after the PVS farm.
	
	Register the PVS Console PowerShell Snap-in.

	For versions of Windows prior to Windows 8 and Server 2012, run:
	
	For 32-bit:
		%systemroot%\Microsoft.NET\Framework\v2.0.50727\installutil.exe "%ProgramFiles%\Citrix\Provisioning Services Console\McliPSSnapIn.dll"
	For 64-bit:
		%systemroot%\Microsoft.NET\Framework64\v2.0.50727\installutil.exe "%ProgramFiles%\Citrix\Provisioning Services Console\McliPSSnapIn.dll"

	For Windows 8.x, Server 2012 and Server 2012 R2, run:
	
	For 32-bit:
		%systemroot%\Microsoft.NET\Framework\v4.0.30319\installutil.exe "%ProgramFiles%\Citrix\Provisioning Services Console\McliPSSnapIn.dll"
	For 64-bit:
		%systemroot%\Microsoft.NET\Framework64\v4.0.30319\installutil.exe "%ProgramFiles%\Citrix\Provisioning Services Console\McliPSSnapIn.dll"

	All lines are one line. 

	If you are running 64-bit Windows, you will need to run both commands so 
	the snap-in is registered for both 32-bit and 64-bit PowerShell.

.PARAMETER AdminAddress
	Specifies the name of a PVS server that the PowerShell script will connect to. 
	Using this parameter requires the script be run from an elevated PowerShell session.
	Starting with V1.11 of the script, this requirement is now checked.
	This parameter has an alias of AA.
.PARAMETER User
	Specifies the user used for the AdminAddress connection. 
.PARAMETER Domain
	Specifies the domain used for the AdminAddress connection. 
.PARAMETER Password
	Specifies the password used for the AdminAddress connection. 
.PARAMETER Folder
	Specifies the optional output folder to save the output report. 
.PARAMETER SmtpServer
	Specifies the optional email server to send the output report. 
.PARAMETER SmtpPort
	Specifies the SMTP port. 
	Default is 25.
.PARAMETER UseSSL
	Specifies whether to use SSL for the SmtpServer.
	Default is False.
.PARAMETER From
	Specifies the username for the From email address.
	If SmtpServer is used, this is a required parameter.
.PARAMETER To
	Specifies the username for the To email address.
	If SmtpServer is used, this is a required parameter.
.EXAMPLE
	PS C:\PSScript > .\PVS_Assessment.ps1
	
	Will use all Default values.
	LocalHost for AdminAddress.
.EXAMPLE
	PS C:\PSScript > .\PVS_Assessment.ps1 -AdminAddress PVS1 -User cwebster -Domain WebstersLab -Password Abc123!@#

	This example is usually used to run the script against a PVS Farm in 
	another domain or forest.
	
	Will use:
		PVS1 for AdminAddress.
		cwebster for User.
		WebstersLab for Domain.
		Abc123!@# for Password.
.EXAMPLE
	PS C:\PSScript > .\PVS_Assessment.ps1 -AdminAddress PVS1 -User cwebster

	Will use:
		PVS1 for AdminAddress.
		cwebster for User.
		Script will prompt for the Domain and Password
.EXAMPLE
	PS C:\PSScript > .\PVS_Assessment.ps1 -Folder \\FileServer\ShareName
	
	Output file will be saved in the path \\FileServer\ShareName
.EXAMPLE
	PS C:\PSScript > .\PVS_Assessment.ps1 -SmtpServer mail.domain.tld -From XDAdmin@domain.tld -To ITGroup@domain.tld -ComputerName DHCPServer01
	
	Script will use the email server mail.domain.tld, sending from XDAdmin@domain.tld, sending to ITGroup@domain.tld.
	If the current user's credentials are not valid to send email, the user will be prompted to enter valid credentials.
.EXAMPLE
	PS C:\PSScript > .\PVS_Assessment.ps1 -SmtpServer smtp.office365.com -SmtpPort 587 -UseSSL -From Webster@CarlWebster.com -To ITGroup@CarlWebster.com
	
	Script will use the email server smtp.office365.com on port 587 using SSL, sending from webster@carlwebster.com, sending to ITGroup@carlwebster.com.
	If the current user's credentials are not valid to send email, the user will be prompted to enter valid credentials.
.INPUTS
	None.  You cannot pipe objects to this script.
.OUTPUTS
	No objects are output from this script.  This script creates a text file.
.NOTES
	NAME: PVS_Assessment.ps1
	VERSION: 1.15
	AUTHOR: Carl Webster, Sr. Solutions Architect at Choice Solutions (with a lot of help from BG a, now former, Citrix dev)
	LASTEDIT: April 12, 2018
#>


#thanks to @jeffwouters for helping me with these parameters
[CmdletBinding(SupportsShouldProcess = $False, ConfirmImpact = "None", DefaultParameterSetName = "Default") ]

Param(
	[parameter(Mandatory=$False)] 
	[Alias("AA")]
	[string]$AdminAddress="",

	[parameter(ParameterSetName="Default",Mandatory=$False)] 
	[parameter(ParameterSetName="SMTP",Mandatory=$False)] 
	[string]$Domain=$env:UserDnsDomain,

	[parameter(Mandatory=$False)] 
	[string]$User="",

	[parameter(Mandatory=$False)] 
	[string]$Password="",

	[parameter(Mandatory=$False)] 
	[string]$Folder="",

	[parameter(ParameterSetName="SMTP",Mandatory=$True)] 
	[string]$SmtpServer="",

	[parameter(ParameterSetName="SMTP",Mandatory=$False)] 
	[int]$SmtpPort=25,

	[parameter(ParameterSetName="SMTP",Mandatory=$False)] 
	[switch]$UseSSL=$False,

	[parameter(ParameterSetName="SMTP",Mandatory=$True)] 
	[string]$From="",

	[parameter(ParameterSetName="SMTP",Mandatory=$True)] 
	[string]$To=""
	
	)


#Carl Webster, CTP and Sr. Solutions Architect at Choice Solutions
#webster@carlwebster.com
#@carlwebster on Twitter
#http://www.CarlWebster.com
#script created August 8, 2015
#released to the community on February 2, 2016
#
#Version 1.15 12-Apr-2018
#	Fixed invalid variable $Text
#
#Version 1.14 7-Apr-2018
#	Added Operating System information to Functions GetComputerWMIInfo and OutputComputerItem
#	Code cleanup from Visual Studio Code
#
#Version 1.13 29-Mar-2017
#	Added Appendix L for vDisks configured to Cache on Server
#
#Version 1.12 28-Feb-2017
#	Added Citrix PVS Services Failure Actions Appendix F2
#
#Version 1.11 12-Sep-2016
#	Added an alias AA for AdminAddress to match the other scripts that use AdminAddress
#	Added output to appendixes to show if nothing was found
#	Added checking for $ComputerName parameter when testing PVS services
#	Changed the "No unassociated vDisks found" to "<None found>" to match the changes to the other Appendixes
#	Fixed an issue where Appendix I was not output
#	Fixed error message in output when no PVS services were found (said No Bootstraps found)
#	If remoting is used (-AdminAddress), check if the script is being run elevated. If not,
#		show the script needs elevation and end the script
#	Removed all references to $ErrorActionPreference since it is no longer used
#
#Version 1.10 8-Sep-2016
#	Added Appendix K for 33 Misc Registry Keys
#		Miscellaneous Registry Items That May or May Not Exist on Servers
#		These items may or may not be needed
#		This Appendix is strictly for server comparison only
#	Added Break statements to most of the Switch statements
#	Added checking the NIC's "Allow the computer to turn off this device to save power" setting
#	Added function Get-RegKeyToObject contributed by Andrew Williamson @ Fujitsu Services
#	Added testing for $Null –eq $DiskLocators. PoSH V2 did not like that I forgot to do that
#	Added to the console and report, lines when nothing was found for various items being checked
#	Cleaned up duplicate IP addresses appearing in Appendix J
#		Changed NICIPAddressess from array to hashtable
#		Reset the StreamingIPAddresses array between servers
#	Moved the initialization of arrays to the top of the script instead of inside a function
#	PoSH V2 did not like the “4>$Null”. I test for V2 now and use “2>$Null”
#	Script now works properly with PoSH V2 and PVS 5.x.x
#	Since PoSH V2 does not work with the way I forced Verbose on, I changed all the Write-Verbose statements to Write-Host
#		You should not be able to tell any difference
#	With the help and patience of Andrew Williamson and MBS, the script should now work with PVS servers that have multiple NICs
#
#Version 1.04 1-Aug-2016
#	Added back missing AdminAddress, User and Password parameters
#	Fixed several invalid output lines
#
#Version 1.03 22-Feb-2016
#	Added validating the Store Path and Write Cache locations
#
#Version 1.02 17-Feb-2016
#	In help text, changed the DLL registration lines to not wrap
#	In help text, changed the smart quotes to regular quotes
#	Added for Appendix E a link to the Citrix article on DisableTaskOffload
#	Added link to PVS server sizing for server RAM calculation
#	Added comparing Streaming IP addresses to the IP addresses configured for the server
#		If a streaming IP address does not exist on the server, it is an invalid streaming IP address
#		This is a bug in PVS that allows invalid IP addresses to be added for streaming IPs
#
#Version 1.01 8-Feb-2016
#	Added specifying an optional output folder
#	Added the option to email the output file
#	Fixed several spacing and typo errors

Set-StrictMode -Version 2

If($Folder -ne "")
{
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Testing folder path"
	#does it exist
	If(Test-Path $Folder -EA 0)
	{
		#it exists, now check to see if it is a folder and not a file
		If(Test-Path $Folder -pathType Container -EA 0)
		{
			#it exists and it is a folder
			Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Folder path $Folder exists and is a folder"
		}
		Else
		{
			#it exists but it is a file not a folder
			Write-Error "Folder $Folder is a file, not a folder.  Script cannot continue"
			Exit
		}
	}
	Else
	{
		#does not exist
		Write-Error "Folder $Folder does not exist.  Script cannot continue"
		Exit
	}
}

$Script:AdvancedItems1 = @()
$Script:AdvancedItems2 = @()
$Script:ConfigWizItems = @()
$Script:BootstrapItems = @()
$Script:TaskOffloadItems = @()
$Script:PVSServiceItems = @()
$Script:VersionsToMerge = @()
$Script:NICIPAddresses = @{}
$Script:StreamingIPAddresses = @()
$Script:BadIPs = @()
$Script:EmptyDeviceCollections = @()
$Script:MiscRegistryItems = @()
$Script:CacheOnServer = @()

#region code for -hardware switch
Function GetComputerWMIInfo
{
	Param([string]$RemoteComputerName)
	
	# original work by Kees Baggerman, 
	# Senior Technical Consultant @ Inter Access
	# k.baggerman@myvirtualvision.com
	# @kbaggerman on Twitter
	# http://blog.myvirtualvision.com
	# modified 1-May-2014 to work in trusted AD Forests and using different domain admin credentials	
	# modified 17-Aug-2016 to fix a few issues with Text and HTML output
	# modified 2-Apr-2018 to add ComputerOS information

	#Get Computer info
	Write-Verbose "$(Get-Date): `t`tProcessing WMI Computer information"
	Write-Verbose "$(Get-Date): `t`t`tHardware information"
	Line 0 "Computer Information: $($RemoteComputerName)"
	Line 1 "General Computer"
	
	[bool]$GotComputerItems = $True
	
	Try
	{
		$Results = Get-WmiObject -computername $RemoteComputerName win32_computersystem
	}
	
	Catch
	{
		$Results = $Null
	}
	
	If($? -and $Null -ne $Results)
	{
		$ComputerItems = $Results | Select-Object Manufacturer, Model, Domain, `
		@{N="TotalPhysicalRam"; E={[math]::round(($_.TotalPhysicalMemory / 1GB),0)}}, `
		NumberOfProcessors, NumberOfLogicalProcessors
		$Results = $Null
		[string]$ComputerOS = (Get-WmiObject -class Win32_OperatingSystem -computername $RemoteComputerName -EA 0).Caption

		ForEach($Item in $ComputerItems)
		{
			OutputComputerItem $Item $ComputerOS
		}
	}
	ElseIf(!$?)
	{
		Write-Verbose "$(Get-Date): Get-WmiObject win32_computersystem failed for $($RemoteComputerName)"
		Write-Warning "Get-WmiObject win32_computersystem failed for $($RemoteComputerName)"
		Line 2 "Get-WmiObject win32_computersystem failed for $($RemoteComputerName)"
		Line 2 "On $($RemoteComputerName) you may need to run winmgmt /verifyrepository"
		Line 2 "and winmgmt /salvagerepository.  If this is a trusted Forest, you may"
		Line 2 "need to rerun the script with Domain Admin credentials from the trusted Forest."
		Line 2 ""
	}
	Else
	{
		Write-Verbose "$(Get-Date): No results Returned for Computer information"
		Line 2 "No results Returned for Computer information"
	}
	
	#Get Disk info
	Write-Verbose "$(Get-Date): `t`t`tDrive information"

	Line 1 "Drive(s)"

	[bool]$GotDrives = $True
	
	Try
	{
		$Results = Get-WmiObject -computername $RemoteComputerName Win32_LogicalDisk
	}
	
	Catch
	{
		$Results = $Null
	}

	If($? -and $Null -ne $Results)
	{
		$drives = $Results | Select-Object caption, @{N="drivesize"; E={[math]::round(($_.size / 1GB),0)}}, 
		filesystem, @{N="drivefreespace"; E={[math]::round(($_.freespace / 1GB),0)}}, 
		volumename, drivetype, volumedirty, volumeserialnumber
		$Results = $Null
		ForEach($drive in $drives)
		{
			If($drive.caption -ne "A:" -and $drive.caption -ne "B:")
			{
				OutputDriveItem $drive
			}
		}
	}
	ElseIf(!$?)
	{
		Write-Verbose "$(Get-Date): Get-WmiObject Win32_LogicalDisk failed for $($RemoteComputerName)"
		Write-Warning "Get-WmiObject Win32_LogicalDisk failed for $($RemoteComputerName)"
		Line 2 "Get-WmiObject Win32_LogicalDisk failed for $($RemoteComputerName)"
		Line 2 "On $($RemoteComputerName) you may need to run winmgmt /verifyrepository"
		Line 2 "and winmgmt /salvagerepository.  If this is a trusted Forest, you may"
		Line 2 "need to rerun the script with Domain Admin credentials from the trusted Forest."
	}
	Else
	{
		Write-Verbose "$(Get-Date): No results Returned for Drive information"
		Line 2 "No results Returned for Drive information"
	}
	

	#Get CPU's and stepping
	Write-Verbose "$(Get-Date): `t`t`tProcessor information"

	Line 1 "Processor(s)"

	[bool]$GotProcessors = $True
	
	Try
	{
		$Results = Get-WmiObject -computername $RemoteComputerName win32_Processor
	}
	
	Catch
	{
		$Results = $Null
	}

	If($? -and $Null -ne $Results)
	{
		$Processors = $Results | Select-Object availability, name, description, maxclockspeed, 
		l2cachesize, l3cachesize, numberofcores, numberoflogicalprocessors
		$Results = $Null
		ForEach($processor in $processors)
		{
			OutputProcessorItem $processor
		}
	}
	ElseIf(!$?)
	{
		Write-Verbose "$(Get-Date): Get-WmiObject win32_Processor failed for $($RemoteComputerName)"
		Write-Warning "Get-WmiObject win32_Processor failed for $($RemoteComputerName)"
		Line 2 "Get-WmiObject win32_Processor failed for $($RemoteComputerName)"
		Line 2 "On $($RemoteComputerName) you may need to run winmgmt /verifyrepository"
		Line 2 "and winmgmt /salvagerepository.  If this is a trusted Forest, you may"
		Line 2 "need to rerun the script with Domain Admin credentials from the trusted Forest."
	}
	Else
	{
		Write-Verbose "$(Get-Date): No results Returned for Processor information"
		Line 2 "No results Returned for Processor information"
	}

	#Get Nics
	Write-Verbose "$(Get-Date): `t`t`tNIC information"

	Line 1 "Network Interface(s)"

	[bool]$GotNics = $True
	
	Try
	{
		$Results = Get-WmiObject -computername $RemoteComputerName win32_networkadapterconfiguration
	}
	
	Catch
	{
		$Results = $Null
	}

	If($? -and $Null -ne $Results)
	{
		$Nics = $Results | Where-Object {$Null -ne $_.ipaddress}
		$Results = $Null

		If($Nics -eq $Null ) 
		{ 
			$GotNics = $False 
		} 
		Else 
		{ 
			$GotNics = !($Nics.__PROPERTY_COUNT -eq 0) 
		} 
	
		If($GotNics)
		{
			ForEach($nic in $nics)
			{
				Try
				{
					$ThisNic = Get-WmiObject -computername $RemoteComputerName win32_networkadapter | Where-Object {$_.index -eq $nic.index}
				}
				
				Catch 
				{
					$ThisNic = $Null
				}
				
				If($? -and $Null -ne $ThisNic)
				{
					OutputNicItem $Nic $ThisNic
				}
				ElseIf(!$?)
				{
					Write-Warning "$(Get-Date): Error retrieving NIC information"
					Write-Verbose "$(Get-Date): Get-WmiObject win32_networkadapterconfiguration failed for $($RemoteComputerName)"
					Write-Warning "Get-WmiObject win32_networkadapterconfiguration failed for $($RemoteComputerName)"
					Line 2 "Error retrieving NIC information"
					Line 2 "Get-WmiObject win32_networkadapterconfiguration failed for $($RemoteComputerName)"
					Line 2 "On $($RemoteComputerName) you may need to run winmgmt /verifyrepository"
					Line 2 "and winmgmt /salvagerepository.  If this is a trusted Forest, you may"
					Line 2 "need to rerun the script with Domain Admin credentials from the trusted Forest."
				}
				Else
				{
					Write-Verbose "$(Get-Date): No results Returned for NIC information"
					Line 2 "No results Returned for NIC information"
				}
			}
		}	
	}
	ElseIf(!$?)
	{
		Write-Warning "$(Get-Date): Error retrieving NIC configuration information"
		Write-Verbose "$(Get-Date): Get-WmiObject win32_networkadapterconfiguration failed for $($RemoteComputerName)"
		Write-Warning "Get-WmiObject win32_networkadapterconfiguration failed for $($RemoteComputerName)"
		Line 2 "Error retrieving NIC configuration information"
		Line 2 "Get-WmiObject win32_networkadapterconfiguration failed for $($RemoteComputerName)"
		Line 2 "On $($RemoteComputerName) you may need to run winmgmt /verifyrepository"
		Line 2 "and winmgmt /salvagerepository.  If this is a trusted Forest, you may"
		Line 2 "need to rerun the script with Domain Admin credentials from the trusted Forest."
	}
	Else
	{
		Write-Verbose "$(Get-Date): No results Returned for NIC configuration information"
		Line 2 "No results Returned for NIC configuration information"
	}
	
	Line 0 ""
}

Function OutputComputerItem
{
	Param([object]$Item, [string]$OS)
	# modified 2-Apr-2018 to add Operating System information
	
	Line 2 "Manufacturer`t`t`t: " $Item.manufacturer
	Line 2 "Model`t`t`t`t: " $Item.model
	Line 2 "Domain`t`t`t`t: " $Item.domain
	Line 2 "Operating System`t`t: " $OS
	Line 2 "Total Ram`t`t`t: $($Item.totalphysicalram) GB"
	Line 2 "Physical Processors (sockets)`t: " $Item.NumberOfProcessors
	Line 2 "Logical Processors (cores w/HT)`t: " $Item.NumberOfLogicalProcessors
	Line 2 ""
}

Function OutputDriveItem
{
	Param([object]$Drive)
	
	$xDriveType = ""
	Switch ($drive.drivetype)
	{
		0	{$xDriveType = "Unknown"; Break}
		1	{$xDriveType = "No Root Directory"; Break}
		2	{$xDriveType = "Removable Disk"; Break}
		3	{$xDriveType = "Local Disk"; Break}
		4	{$xDriveType = "Network Drive"; Break}
		5	{$xDriveType = "Compact Disc"; Break}
		6	{$xDriveType = "RAM Disk"; Break}
		Default {$xDriveType = "Unknown"; Break}
	}
	
	$xVolumeDirty = ""
	If(![String]::IsNullOrEmpty($drive.volumedirty))
	{
		If($drive.volumedirty)
		{
			$xVolumeDirty = "Yes"
		}
		Else
		{
			$xVolumeDirty = "No"
		}
	}

	Line 3 "Caption: " $drive.caption
	Line 3 "Size: $($drive.drivesize) GB"
	If(![String]::IsNullOrEmpty($drive.filesystem))
	{
		Line 3 "File System: " $drive.filesystem
	}
	Line 3 "Free Space: $($drive.drivefreespace) GB"
	If(![String]::IsNullOrEmpty($drive.volumename))
	{
		Line 3 "Volume Name: " $drive.volumename
	}
	If(![String]::IsNullOrEmpty($drive.volumedirty))
	{
		Line 3 "Volume is Dirty: " $xVolumeDirty
	}
	If(![String]::IsNullOrEmpty($drive.volumeserialnumber))
	{
		Line 3 "Volume Serial #: " $drive.volumeserialnumber
	}
	Line 3 "Drive Type: " $xDriveType
	Line 3 ""
}

Function OutputProcessorItem
{
	Param([object]$Processor)
	
	$xAvailability = ""
	Switch ($processor.availability)
	{
		1	{$xAvailability = "Other"; Break }
		2	{$xAvailability = "Unknown"; Break }
		3	{$xAvailability = "Running or Full Power"; Break }
		4	{$xAvailability = "Warning"; Break }
		5	{$xAvailability = "In Test"; Break }
		6	{$xAvailability = "Not Applicable"; Break }
		7	{$xAvailability = "Power Off"; Break }
		8	{$xAvailability = "Off Line"; Break }
		9	{$xAvailability = "Off Duty"; Break }
		10	{$xAvailability = "Degraded"; Break }
		11	{$xAvailability = "Not Installed"; Break }
		12	{$xAvailability = "Install Error"; Break }
		13	{$xAvailability = "Power Save - Unknown"; Break }
		14	{$xAvailability = "Power Save - Low Power Mode"; Break }
		15	{$xAvailability = "Power Save - Standby"; Break }
		16	{$xAvailability = "Power Cycle"; Break }
		17	{$xAvailability = "Power Save - Warning"; Break }
		Default	{$xAvailability = "Unknown"; Break }
	}

	Line 3 "Name: " $processor.name
	Line 3 "Description: " $processor.description
	Line 3 "Max Clock Speed: $($processor.maxclockspeed) MHz"
	If($processor.l2cachesize -gt 0)
	{
		Line 3 "L2 Cache Size: $($processor.l2cachesize) KB"
	}
	If($processor.l3cachesize -gt 0)
	{
		Line 3 "L3 Cache Size: $($processor.l3cachesize) KB"
	}
	If($processor.numberofcores -gt 0)
	{
		Line 3 "# of Cores: " $processor.numberofcores
	}
	If($processor.numberoflogicalprocessors -gt 0)
	{
		Line 3 "# of Logical Procs (cores w/HT): " $processor.numberoflogicalprocessors
	}
	Line 3 "Availability: " $xAvailability
	Line 3 ""
}

Function OutputNicItem
{
	Param([object]$Nic, [object]$ThisNic, [string] $ComputerName)
	
	$powerMgmt = Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi | Where-Object {$_.InstanceName -match [regex]::Escape($ThisNic.PNPDeviceID)}

	If($? -and $Null -ne $powerMgmt)
	{
		If($powerMgmt.Enable -eq $True)
		{
			$PowerSaving = "Enabled"
		}
		Else
		{
			$PowerSaving = "Disabled"
		}
	}
	Else
	{
        $PowerSaving = "N/A"
	}
	
	$xAvailability = ""
	Switch ($processor.availability)
	{
		1	{$xAvailability = "Other"; Break }
		2	{$xAvailability = "Unknown"; Break }
		3	{$xAvailability = "Running or Full Power"; Break }
		4	{$xAvailability = "Warning"; Break }
		5	{$xAvailability = "In Test"; Break }
		6	{$xAvailability = "Not Applicable"; Break }
		7	{$xAvailability = "Power Off"; Break }
		8	{$xAvailability = "Off Line"; Break }
		9	{$xAvailability = "Off Duty"; Break }
		10	{$xAvailability = "Degraded"; Break }
		11	{$xAvailability = "Not Installed"; Break }
		12	{$xAvailability = "Install Error"; Break }
		13	{$xAvailability = "Power Save - Unknown"; Break }
		14	{$xAvailability = "Power Save - Low Power Mode"; Break }
		15	{$xAvailability = "Power Save - Standby"; Break }
		16	{$xAvailability = "Power Cycle"; Break }
		17	{$xAvailability = "Power Save - Warning"; Break }
		Default	{$xAvailability = "Unknown"; Break }
	}

	$xIPAddresses = @()
	ForEach($IPAddress in $Nic.ipaddress)
	{
		$xIPAddresses += "$($IPAddress)"
		#$Script:NICIPAddresses.Add($ComputerName, $IPAddress)
		If($Script:NICIPAddresses.ContainsKey($ComputerName)) 
		{
			$MultiIP = @()
			$MultiIP += $Script:NICIPAddresses.Item($ComputerName)
			$MultiIP += $IPAddress
			$Script:NICIPAddresses.Item($ComputerName) = $MultiIP
		} 
		Else 
		{
			$Script:NICIPAddresses.Add($ComputerName,$IPAddress)
		}
	}

	$xIPSubnet = @()
	ForEach($IPSubnet in $Nic.ipsubnet)
	{
		$xIPSubnet += "$($IPSubnet)"
	}

	If($Null -ne $nic.dnsdomainsuffixsearchorder -and $nic.dnsdomainsuffixsearchorder.length -gt 0)
	{
		$nicdnsdomainsuffixsearchorder = $nic.dnsdomainsuffixsearchorder
		$xnicdnsdomainsuffixsearchorder = @()
		ForEach($DNSDomain in $nicdnsdomainsuffixsearchorder)
		{
			$xnicdnsdomainsuffixsearchorder += "$($DNSDomain)"
		}
	}
	
	If($Null -ne $nic.dnsserversearchorder -and $nic.dnsserversearchorder.length -gt 0)
	{
		$nicdnsserversearchorder = $nic.dnsserversearchorder
		$xnicdnsserversearchorder = @()
		ForEach($DNSServer in $nicdnsserversearchorder)
		{
			$xnicdnsserversearchorder += "$($DNSServer)"
		}
	}

	$xdnsenabledforwinsresolution = ""
	If($nic.dnsenabledforwinsresolution)
	{
		$xdnsenabledforwinsresolution = "Yes"
	}
	Else
	{
		$xdnsenabledforwinsresolution = "No"
	}
	
	$xTcpipNetbiosOptions = ""
	Switch ($nic.TcpipNetbiosOptions)
	{
		0	{$xTcpipNetbiosOptions = "Use NetBIOS setting from DHCP Server"; Break}
		1	{$xTcpipNetbiosOptions = "Enable NetBIOS"; Break}
		2	{$xTcpipNetbiosOptions = "Disable NetBIOS"; Break}
		Default	{$xTcpipNetbiosOptions = "Unknown"; Break}
	}
	
	$xwinsenablelmhostslookup = ""
	If($nic.winsenablelmhostslookup)
	{
		$xwinsenablelmhostslookup = "Yes"
	}
	Else
	{
		$xwinsenablelmhostslookup = "No"
	}

	Line 3 "Name: " $ThisNic.Name
	If($ThisNic.Name -ne $nic.description)
	{
		Line 3 "Description: " $nic.description
	}
	Line 3 "Connection ID: " $ThisNic.NetConnectionID
	Line 3 "Manufacturer: " $ThisNic.manufacturer
	Line 3 "Availability: " $xAvailability
    Line 3 "Allow the computer to turn off this device to save power: " $PowerSaving
	Line 3 "Physical Address: " $nic.macaddress
	Line 3 "IP Address: " $xIPAddresses[0]
	$cnt = -1
	ForEach($tmp in $xIPAddresses)
	{
		$cnt++
		If($cnt -gt 0)
		{
			Line 4 "    " $tmp
		}
	}
	Line 3 "Default Gateway: " $Nic.Defaultipgateway
	Line 3 "Subnet Mask: " $xIPSubnet[0]
	$cnt = -1
	ForEach($tmp in $xIPSubnet)
	{
		$cnt++
		If($cnt -gt 0)
		{
			Line 4 "     " $tmp
		}
	}
	If($nic.dhcpenabled)
	{
		$DHCPLeaseObtainedDate = $nic.ConvertToDateTime($nic.dhcpleaseobtained)
		$DHCPLeaseExpiresDate = $nic.ConvertToDateTime($nic.dhcpleaseexpires)
		Line 3 "DHCP Enabled: " $nic.dhcpenabled
		Line 3 "DHCP Lease Obtained: " $dhcpleaseobtaineddate
		Line 3 "DHCP Lease Expires: " $dhcpleaseexpiresdate
		Line 3 "DHCP Server:" $nic.dhcpserver
	}
	If(![String]::IsNullOrEmpty($nic.dnsdomain))
	{
		Line 3 "DNS Domain: " $nic.dnsdomain
	}
	If($Null -ne $nic.dnsdomainsuffixsearchorder -and $nic.dnsdomainsuffixsearchorder.length -gt 0)
	{
		[int]$x = 1
		Line 3 "DNS Search Suffixes: " $xnicdnsdomainsuffixsearchorder[0]
		$cnt = -1
		ForEach($tmp in $xnicdnsdomainsuffixsearchorder)
		{
			$cnt++
			If($cnt -gt 0)
			{
				Line 4 "    " $tmp
			}
		}
	}
	Line 3 "DNS WINS Enabled: " $xdnsenabledforwinsresolution
	If($Null -ne $nic.dnsserversearchorder -and $nic.dnsserversearchorder.length -gt 0)
	{
		[int]$x = 1
		Line 3 "DNS Servers: " $xnicdnsserversearchorder[0]
		$cnt = -1
		ForEach($tmp in $xnicdnsserversearchorder)
		{
			$cnt++
			If($cnt -gt 0)
			{
				Line 4 "     " $tmp
			}
		}
	}
	Line 3 "NetBIOS Setting: " $xTcpipNetbiosOptions
	Line 3 "Enabled LMHosts: " $xwinsenablelmhostslookup
	If(![String]::IsNullOrEmpty($nic.winshostlookupfile))
	{
		Line 3 "Host Lookup File: " $nic.winshostlookupfile
	}
	If(![String]::IsNullOrEmpty($nic.winsprimaryserver))
	{
		Line 3 "Primary Server: " $nic.winsprimaryserver
	}
	If(![String]::IsNullOrEmpty($nic.winssecondaryserver))
	{
		Line 3 "Secondary Server: " $nic.winssecondaryserver
	}
	If(![String]::IsNullOrEmpty($nic.winsscopeid))
	{
		Line 3 "Scope ID: " $nic.winsscopeid
	}
	Line 0 ""
}
#endregion

#region email function
Function SendEmail
{
	Param([string]$Attachments)
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Prepare to email"
	$emailAttachment = $Attachments
	$emailSubject = $Script:Title
	$emailBody = @"
Hello, <br />
<br />
$Script:Title is attached.
"@ 

	$error.Clear()
	If($UseSSL)
	{
		Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Trying to send email using current user's credentials with SSL"
		Send-MailMessage -Attachments $emailAttachment -Body $emailBody -BodyAsHtml -From $From `
		-Port $SmtpPort -SmtpServer $SmtpServer -Subject $emailSubject -To $To `
		-UseSSL *>$Null
	}
	Else
	{
		Write-Verbose  "$(Get-Date): Trying to send email using current user's credentials without SSL"
		Send-MailMessage -Attachments $emailAttachment -Body $emailBody -BodyAsHtml -From $From `
		-Port $SmtpPort -SmtpServer $SmtpServer -Subject $emailSubject -To $To *>$Null
	}

	$e = $error[0]

	If($e.Exception.ToString().Contains("5.7.57"))
	{
		#The server response was: 5.7.57 SMTP; Client was not authenticated to send anonymous mail during MAIL FROM
		Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Current user's credentials failed. Ask for usable credentials."

		$emailCredentials = Get-Credential -Message "Enter the email account and password to send email"

		$error.Clear()
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
			Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Email successfully sent using new credentials"
		}
		Else
		{
			Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Email was not sent:"
			Write-Warning "$(Get-Date): Exception: $e.Exception" 
		}
	}
	Else
	{
		Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Email was not sent:"
		Write-Warning "$(Get-Date): Exception: $e.Exception" 
	}
}
#endregion

Function GetConfigWizardInfo
{
	Param([string]$ComputerName)
	
	$DHCPServicesValue = Get-RegistryValue "HKLM:\SOFTWARE\Citrix\ProvisioningServices\Wizard" "DHCPType" $ComputerName
	$PXEServiceValue = Get-RegistryValue "HKLM:\SOFTWARE\Citrix\ProvisioningServices\Wizard" "PXEType" $ComputerName
	
	$DHCPServices = ""
	$PXEServices = ""

	Switch ($DHCPServicesValue)
	{
		1073741824 {$DHCPServices = "The service that runs on another computer"; Break}
		0 {$DHCPServices = "Microsoft DHCP"; Break}
		1 {$DHCPServices = "Provisioning Services BOOTP service"; Break}
		2 {$DHCPServices = "Other BOOTP or DHCP service"; Break}
		Default {$DHCPServices = "Unable to determine DHCPServices: $($DHCPServiceValue)"; Break}
	}

	If($DHCPServicesValue -eq 1073741824)
	{
		Switch ($PXEServiceValue)
		{
			1073741824 {$PXEServices = "The service that runs on another computer"; Break}
			0 {$PXEServices = "Provisioning Services PXE service"; Break}
			Default {$PXEServices = "Unable to determine PXEServices: $($PXEServiceValue)"; Break}
		}
	}
	ElseIf($DHCPServicesValue -eq 0)
	{
		Switch ($PXEServiceValue)
		{
			1073741824 {$PXEServices = "The service that runs on another computer"; Break}
			0 {$PXEServices = "Microsoft DHCP"; Break}
			1 {$PXEServices = "Provisioning Services PXE service"; Break}
			Default {$PXEServices = "Unable to determine PXEServices: $($PXEServiceValue)"; Break}
		}
	}
	ELseIf($DHCPServicesValue -eq 1)
	{
		$PXEServices = "N/A"
	}
	ElseIf($DHCPServicesValue -eq 2)
	{
		Switch ($PXEServiceValue)
		{
			1073741824 {$PXEServices = "The service that runs on another computer"; Break}
			0 {$PXEServices = "Provisioning Services PXE service"; Break}
			Default {$PXEServices = "Unable to determine PXEServices: $($PXEServiceValue)"; Break}
		}
	}

	$UserAccount1Value = Get-RegistryValue "HKLM:\SOFTWARE\Citrix\ProvisioningServices\Wizard" "Account1" $ComputerName
	$UserAccount3Value = Get-RegistryValue "HKLM:\SOFTWARE\Citrix\ProvisioningServices\Wizard" "Account3" $ComputerName
	
	$UserAccount = ""
	
	If([String]::IsNullOrEmpty($UserAccount1Value) -and $UserAccount3Value -eq 1)
	{
		$UserAccount = "NetWork Service"
	}
	ElseIf([String]::IsNullOrEmpty($UserAccount1Value) -and $UserAccount3Value -eq 0)
	{
		$UserAccount = "Local system account"
	}
	ElseIf(![String]::IsNullOrEmpty($UserAccount1Value))
	{
		$UserAccount = $UserAccount1Value
	}

	$TFTPOptionValue = Get-RegistryValue "HKLM:\SOFTWARE\Citrix\ProvisioningServices\Wizard" "TFTPSetting" $ComputerName
	$TFTPOption = ""
	
	If($TFTPOptionValue -eq 1)
	{
		$TFTPOption = "Yes"
		$TFTPBootstrapLocation = Get-RegistryValue "HKLM:\SOFTWARE\Citrix\ProvisioningServices\Admin" "Bootstrap" $ComputerName
	}
	Else
	{
		$TFTPOption = "No"
	}

	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Gather Config Wizard info for Appendix C"
	$obj1 = New-Object -TypeName PSObject
	
	$obj1 | Add-Member -MemberType NoteProperty -Name ServerName 		-Value $ComputerName
	$obj1 | Add-Member -MemberType NoteProperty -Name DHCPServicesValue	-Value $DHCPServicesValue
	$obj1 | Add-Member -MemberType NoteProperty -Name PXEServicesValue  -Value $PXEServiceValue
	$obj1 | Add-Member -MemberType NoteProperty -Name UserAccount  		-Value $UserAccount
	$obj1 | Add-Member -MemberType NoteProperty -Name TFTPOptionValue	-Value $TFTPOptionValue
	$Script:ConfigWizItems +=  $obj1
	
	Line 2 "Configuration Wizard Settings"
	Line 3 "DHCP Services: " $DHCPServices
	Line 3 "PXE Services: " $PXEServices
	Line 3 "User account: " $UserAccount
	Line 3 "TFTP Option: " $TFTPOption
	If($TFTPOptionValue -eq 1)
	{
		Line 3 "TFTP Bootstrap Location: " $TFTPBootstrapLocation
	}
	
	Line 0 ""
}

Function GetDisableTaskOffloadInfo
{
	Param([string]$ComputerName)
	
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Gather TaskOffload info for Appendix E"
	$TaskOffloadValue = Get-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Services\TCPIP\Parameters" "DisableTaskOffload" $ComputerName
	
	If($Null -eq $TaskOffloadValue)
	{
		$TaskOffloadValue = "Missing"
	}
	
	$obj1 = New-Object -TypeName PSObject
	
	$obj1 | Add-Member -MemberType NoteProperty -Name ServerName 		-Value $ComputerName
	$obj1 | Add-Member -MemberType NoteProperty -Name TaskOffloadValue	-Value $TaskOffloadValue
	$Script:TaskOffloadItems +=  $obj1
	
	Line 2 "TaskOffload Settings"
	Line 3 "Value: " $TaskOffloadValue
	
	Line 0 ""
}

Function Get-RegKeyToObject 
{
	#function contributed by Andrew Williamson @ Fujitsu Services
    param([string]$RegPath,
    [string]$RegKey,
    [string]$ComputerName)
	
    $val = Get-RegistryValue $RegPath $RegKey $ComputerName
	
    $obj1 = New-Object -TypeName PSObject
	$obj1 | Add-Member -MemberType NoteProperty -Name ServerName	-Value $ComputerName
	$obj1 | Add-Member -MemberType NoteProperty -Name RegKey		-Value $RegPath
	$obj1 | Add-Member -MemberType NoteProperty -Name RegValue		-Value $RegKey
    If($Null -eq $val) 
	{
        $obj1 | Add-Member -MemberType NoteProperty -Name Value		-Value "Not set"
    } 
	Else 
	{
	    $obj1 | Add-Member -MemberType NoteProperty -Name Value		-Value $val
    }
    $Script:MiscRegistryItems +=  $obj1
}

Function GetMiscRegistryKeys
{
	Param([string]$ComputerName)
	
	#look for the following registry keys and values on PVS servers
		
	#Registry Key                                                      Registry Value                 
	#=================================================================================================
	#HKLM:\SOFTWARE\Citrix\ProvisioningServices                        AutoUpdateUserCache            
	#HKLM:\SOFTWARE\Citrix\ProvisioningServices                        LoggingLevel 
	#HKLM:\SOFTWARE\Citrix\ProvisioningServices                        SkipBootMenu                   
	#HKLM:\SOFTWARE\Citrix\ProvisioningServices                        UseManagementIpInCatalog       
	#HKLM:\SOFTWARE\Citrix\ProvisioningServices                        UseTemplateBootOrder           
	#HKLM:\SOFTWARE\Citrix\ProvisioningServices\IPC                    IPv4Address                    
	#HKLM:\SOFTWARE\Citrix\ProvisioningServices\IPC                    PortBase 
	#HKLM:\SOFTWARE\Citrix\ProvisioningServices\IPC                    PortCount 
	#HKLM:\SOFTWARE\Citrix\ProvisioningServices\Manager                GeneralInetAddr                
	#HKLM:\SOFTWARE\Citrix\ProvisioningServices\MgmtDaemon             IPCTraceFile 
	#HKLM:\SOFTWARE\Citrix\ProvisioningServices\MgmtDaemon             IPCTraceState 
	#HKLM:\SOFTWARE\Citrix\ProvisioningServices\MgmtDaemon             PortOffset 
	#HKLM:\SOFTWARE\Citrix\ProvisioningServices\Notifier               IPCTraceFile 
	#HKLM:\SOFTWARE\Citrix\ProvisioningServices\Notifier               IPCTraceState 
	#HKLM:\SOFTWARE\Citrix\ProvisioningServices\Notifier               PortOffset 
	#HKLM:\SOFTWARE\Citrix\ProvisioningServices\SoapServer             PortOffset 
	#HKLM:\SOFTWARE\Citrix\ProvisioningServices\StreamProcess          IPCTraceFile 
	#HKLM:\SOFTWARE\Citrix\ProvisioningServices\StreamProcess          IPCTraceState 
	#HKLM:\SOFTWARE\Citrix\ProvisioningServices\StreamProcess          PortOffset 
	#HKLM:\SOFTWARE\Citrix\ProvisioningServices\StreamProcess          SkipBootMenu                   
	#HKLM:\SOFTWARE\Citrix\ProvisioningServices\StreamProcess          SkipRIMS                       
	#HKLM:\SOFTWARE\Citrix\ProvisioningServices\StreamProcess          SkipRIMSforPrivate             
	#HKLM:\SYSTEM\CurrentControlSet\Services\BNIStack\Parameters       SocketOpenRetryIntervalMS      
	#HKLM:\SYSTEM\CurrentControlSet\Services\BNIStack\Parameters       SocketOpenRetryLimit           
	#HKLM:\SYSTEM\CurrentControlSet\Services\BNIStack\Parameters       WcHDNoIntermediateBuffering    
	#HKLM:\SYSTEM\CurrentControlSet\services\BNIStack\Parameters       WcRamConfiguration             
	#HKLM:\SYSTEM\CurrentControlSet\Services\BNIStack\Parameters       WcWarningIncrement             
	#HKLM:\SYSTEM\CurrentControlSet\Services\BNIStack\Parameters       WcWarningPercent               
	#HKLM:\SYSTEM\CurrentControlSet\Services\BNNS\Parameters           EnableOffload                  
	#HKLM:\SYSTEM\Currentcontrolset\services\BNTFTP\Parameters         InitTimeoutSec           
	#HKLM:\SYSTEM\Currentcontrolset\services\BNTFTP\Parameters         MaxBindRetry             
	#HKLM:\SYSTEM\Currentcontrolset\services\PVSTSB\Parameters         InitTimeoutSec           
	#HKLM:\SYSTEM\Currentcontrolset\services\PVSTSB\Parameters         MaxBindRetry      
	
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Gather Misc Registry Key data for Appendix K"

	#https://docs.citrix.com/en-us/provisioning/7-1/pvs-readme-7/7-fixed-issues.html
	Get-RegKeyToObject "HKLM:\SOFTWARE\Citrix\ProvisioningServices" "AutoUpdateUserCache" $ComputerName

	#https://support.citrix.com/article/CTX135299
	Get-RegKeyToObject "HKLM:\SOFTWARE\Citrix\ProvisioningServices" "SkipBootMenu" $ComputerName

	#https://support.citrix.com/article/CTX142613
	Get-RegKeyToObject "HKLM:\SOFTWARE\Citrix\ProvisioningServices" "UseManagementIpInCatalog" $ComputerName

	#https://support.citrix.com/article/CTX142613
	Get-RegKeyToObject "HKLM:\SOFTWARE\Citrix\ProvisioningServices" "UseTemplateBootOrder" $ComputerName

	#https://support.citrix.com/article/CTX200196
	Get-RegKeyToObject "HKLM:\SOFTWARE\Citrix\ProvisioningServices\IPC" "UseTemplateBootOrder" $ComputerName

	#https://support.citrix.com/article/CTX200196
	Get-RegKeyToObject "HKLM:\SOFTWARE\Citrix\ProvisioningServices\Manager" "UseTemplateBootOrder" $ComputerName

	#https://support.citrix.com/article/CTX135299
	Get-RegKeyToObject "HKLM:\SOFTWARE\Citrix\ProvisioningServices\StreamProcess" "UseTemplateBootOrder" $ComputerName

	Get-RegKeyToObject "HKLM:\SOFTWARE\Citrix\ProvisioningServices\StreamProcess" "SkipRIMS" $ComputerName

	#https://support.citrix.com/article/CTX200233
	Get-RegKeyToObject "HKLM:\SOFTWARE\Citrix\ProvisioningServices\StreamProcess" "SkipRIMSforPrivate" $ComputerName

	#https://support.citrix.com/article/CTX136570
	Get-RegKeyToObject "HKLM:\SYSTEM\CurrentControlSet\Services\BNIStack\Parameters" "SocketOpenRetryIntervalMS" $ComputerName

	#https://support.citrix.com/article/CTX136570
	Get-RegKeyToObject "HKLM:\SYSTEM\CurrentControlSet\Services\BNIStack\Parameters" "SocketOpenRetryLimit" $ComputerName

	#https://support.citrix.com/article/CTX126042?_ga=1.42836768.408415398.1458651624
	Get-RegKeyToObject "HKLM:\SYSTEM\CurrentControlSet\Services\BNIStack\Parameters" "WcHDNoIntermediateBuffering" $ComputerName

	#https://support.citrix.com/article/CTX139849
	Get-RegKeyToObject "HKLM:\SYSTEM\CurrentControlSet\services\BNIStack\Parameters" "WcRamConfiguration" $ComputerName

	#https://docs.citrix.com/en-us/provisioning/7-1/pvs-readme-7/7-fixed-issues.html
	Get-RegKeyToObject "HKLM:\SYSTEM\CurrentControlSet\Services\BNIStack\Parameters" "WcWarningIncrement" $ComputerName

	#https://docs.citrix.com/en-us/provisioning/7-1/pvs-readme-7/7-fixed-issues.html
	Get-RegKeyToObject "HKLM:\SYSTEM\CurrentControlSet\Services\BNIStack\Parameters" "WcWarningPercent" $ComputerName

	#https://support.citrix.com/article/CTX117374
	Get-RegKeyToObject "HKLM:\SYSTEM\CurrentControlSet\Services\BNNS\Parameters" "EnableOffload" $ComputerName
	
	#https://discussions.citrix.com/topic/362671-error-pxe-e53/#entry1863984
	Get-RegKeyToObject "HKLM:\SYSTEM\Currentcontrolset\services\BNTFTP\Parameters" "InitTimeoutSec" $ComputerName
	
	#https://discussions.citrix.com/topic/362671-error-pxe-e53/#entry1863984
	Get-RegKeyToObject "HKLM:\SYSTEM\Currentcontrolset\services\BNTFTP\Parameters" "MaxBindRetry" $ComputerName

	#https://discussions.citrix.com/topic/362671-error-pxe-e53/#entry1863984
	Get-RegKeyToObject "HKLM:\SYSTEM\Currentcontrolset\services\PVSTSB\Parameters" "InitTimeoutSec" $ComputerName
	
	#https://discussions.citrix.com/topic/362671-error-pxe-e53/#entry1863984
	Get-RegKeyToObject "HKLM:\SYSTEM\Currentcontrolset\services\PVSTSB\Parameters" "MaxBindRetry" $ComputerName

	#regkeys recommended by Andrew Williamson @ Fujitsu Services
    Get-RegKeyToObject "HKLM:\SOFTWARE\Citrix\ProvisioningServices" "LoggingLevel" $ComputerName
    Get-RegKeyToObject "HKLM:\SOFTWARE\Citrix\ProvisioningServices\IPC" "PortBase" $ComputerName
    Get-RegKeyToObject "HKLM:\SOFTWARE\Citrix\ProvisioningServices\IPC" "PortCount" $ComputerName
    Get-RegKeyToObject "HKLM:\SOFTWARE\Citrix\ProvisioningServices\MgmtDaemon" "IPCTraceFile" $ComputerName
    Get-RegKeyToObject "HKLM:\SOFTWARE\Citrix\ProvisioningServices\MgmtDaemon" "IPCTraceState" $ComputerName
    Get-RegKeyToObject "HKLM:\SOFTWARE\Citrix\ProvisioningServices\MgmtDaemon" "PortOffset" $ComputerName
    Get-RegKeyToObject "HKLM:\SOFTWARE\Citrix\ProvisioningServices\Notifier" "IPCTraceFile" $ComputerName
    Get-RegKeyToObject "HKLM:\SOFTWARE\Citrix\ProvisioningServices\Notifier" "IPCTraceState" $ComputerName
    Get-RegKeyToObject "HKLM:\SOFTWARE\Citrix\ProvisioningServices\Notifier" "PortOffset" $ComputerName
    Get-RegKeyToObject "HKLM:\SOFTWARE\Citrix\ProvisioningServices\SoapServer" "PortOffset" $ComputerName
    Get-RegKeyToObject "HKLM:\SOFTWARE\Citrix\ProvisioningServices\StreamProcess" "IPCTraceFile" $ComputerName
    Get-RegKeyToObject "HKLM:\SOFTWARE\Citrix\ProvisioningServices\StreamProcess" "IPCTraceState" $ComputerName
    Get-RegKeyToObject "HKLM:\SOFTWARE\Citrix\ProvisioningServices\StreamProcess" "PortOffset" $ComputerName
}

# Gets the specified registry value or $Null if it is missing
Function Get-RegistryValue
{
	[CmdletBinding()]
	Param([string]$path, [string]$name, [string]$ComputerName)
	If($ComputerName -eq $env:computername)
	{
		$key = Get-Item -LiteralPath $path -EA 0
		If($key)
		{
			Return $key.GetValue($name, $Null)
		}
		Else
		{
			Return $Null
		}
	}
	Else
	{
		#path needed here is different for remote registry access
		$path = $path.SubString(6)
		$path2 = $path.Replace('\','\\')
		$Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $ComputerName)
		$RegKey = $Reg.OpenSubKey($path2)
		If ($RegKey)
		{
			$Results = $RegKey.GetValue($name)

			If($Null -ne $Results)
			{
				Return $Results
			}
			Else
			{
				Return $Null
			}
		}
		Else
		{
			Return $Null
		}
	}
}

Function BuildPVSObject
{
	Param([string]$MCLIGetWhat = '', [string]$MCLIGetParameters = '', [string]$TextForErrorMsg = '')

	$error.Clear()

	If($MCLIGetParameters -ne '')
	{
		$MCLIGetResult = Mcli-Get "$($MCLIGetWhat)" -p "$($MCLIGetParameters)"
	}
	Else
	{
		$MCLIGetResult = Mcli-Get "$($MCLIGetWhat)"
	}

	If($error.Count -eq 0)
	{
		$PluralObject = @()
		$SingleObject = $Null
		ForEach($record in $MCLIGetResult)
		{
			If($record.length -gt 5 -and $record.substring(0,6) -eq "Record")
			{
				If($Null -ne $SingleObject)
				{
					$PluralObject += $SingleObject
				}
				$SingleObject = new-object System.Object
			}

			$index = $record.IndexOf(':')
			If($index -gt 0)
			{
				$property = $record.SubString(0, $index)
				$value    = $record.SubString($index + 2)
				If($property -ne "Executing")
				{
					Add-Member -inputObject $SingleObject -MemberType NoteProperty -Name $property -Value $value
				}
			}
		}
		$PluralObject += $SingleObject
		Return $PluralObject
	}
	Else 
	{
		Line 0 "$($TextForErrorMsg) could not be retrieved"
		Line 0 "Error returned is " $error[0].FullyQualifiedErrorId.Split(',')[0].Trim()
	}
}

Function Check-NeededPSSnapins
{
	Param([parameter(Mandatory = $True)][alias("Snapin")][string[]]$Snapins)

	#Function specifics
	$MissingSnapins = @()
	[bool]$FoundMissingSnapin = $False
	$LoadedSnapins = @()
	$RegisteredSnapins = @()

	#Creates arrays of strings, rather than objects, we're passing strings so this will be more robust.
	$loadedSnapins += get-pssnapin | ForEach-Object {$_.name}
	$registeredSnapins += get-pssnapin -Registered | ForEach-Object {$_.name}

	ForEach($Snapin in $Snapins)
	{
		#check if the snapin is loaded
		If(!($LoadedSnapins -like $snapin))
		{
			#Check if the snapin is missing
			If(!($RegisteredSnapins -like $Snapin))
			{
				#set the flag if it's not already
				If(!($FoundMissingSnapin))
				{
					$FoundMissingSnapin = $True
				}
				#add the entry to the list
				$MissingSnapins += $Snapin
			}
			Else
			{
				#Snapin is registered, but not loaded, loading it now:
				Write-Host "Loading Windows PowerShell snap-in: $snapin"
				Add-PSSnapin -Name $snapin -EA 0
			}
		}
	}

	If($FoundMissingSnapin)
	{
		Write-Warning "Missing Windows PowerShell snap-ins Detected:"
		$missingSnapins | ForEach-Object {Write-Warning "($_)"}
		return $False
	}
	Else
	{
		Return $True
	}
}

Function line
#function created by Michael B. Smith, Exchange MVP
#@essentialexchange on Twitter
#http://TheEssentialExchange.com
#for creating the formatted text report
#created March 2011
#updated March 2014
{
	Param( [int]$tabs = 0, [string]$name = '', [string]$value = '', [string]$newLine = "`r`n", [switch]$nonewLine )
	While( $tabs -gt 0 ) { $Global:Output += "`t"; $tabs--; }
	If( $nonewLine )
	{
		$Global:Output += $name + $value
	}
	Else
	{
		$Global:Output += $name + $value + $newline
	}
}
	
Function SaveandCloseTextDocument
{
	If( $Host.Version.CompareTo( [System.Version]'2.0' ) -eq 0 )
	{
		Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Saving for PoSH V2"
		Write-Output $Global:Output | Out-String -width 120 | Out-File $Script:Filename1 2>$Null
	}
	Else
	{
		Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Saving for PoSH V3 or later"
		Write-Output $Global:Output | Out-String -width 120 | Out-File $Script:Filename1 4>$Null
	}
}

Function SetFileName1
{
	Param([string]$OutputFileName)
	If($Folder -eq "")
	{
		$pwdpath = $pwd.Path
	}
	Else
	{
		$pwdpath = $Folder
	}

	If($pwdpath.EndsWith("\"))
	{
		#remove the trailing \
		$pwdpath = $pwdpath.SubString(0, ($pwdpath.Length - 1))
	}

	[string]$Script:FileName1 = "$($pwdpath)\$($OutputFileName).txt"
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

Function SetupRemoting
{
	#setup remoting if $AdminAddress is not empty
	[bool]$Script:Remoting = $False
	If(![System.String]::IsNullOrEmpty($AdminAddress))
	{
		#since we are setting up remoting, the script must be run from an elevated PowerShell session
		$Elevated = ElevatedSession

		If( -not $Elevated )
		{
			Write-Host "Warning: " -Foreground White
			Write-Host "Warning: Remoting to another PVS server was requested but this is not an elevated PowerShell session." -Foreground White
			Write-Host "Warning: Using -AdminAddress requires the script be run from an elevated PowerShell session." -Foreground White
			Write-Host "Warning: Please run the script from an elevated PowerShell session.  Script cannot continue" -Foreground White
			Write-Host "Warning: " -Foreground White
			Exit
		}
		Else
		{
			Write-Host "" -Foreground White
			Write-Host "This is an elevated PowerShell session." -Foreground White
			Write-Host "" -Foreground White
		}
		
		If(![System.String]::IsNullOrEmpty($User))
		{
			If([System.String]::IsNullOrEmpty($Domain))
			{
				$Domain = Read-Host "Domain name for user is required.  Enter Domain name for user"
			}		

			If([System.String]::IsNullOrEmpty($Password))
			{
				$Password = Read-Host "Password for user is required.  Enter password for user"
			}		
			$error.Clear()
			mcli-run SetupConnection -p server="$($AdminAddress)",user="$($User)",domain="$($Domain)",password="$($Password)"
		}
		Else
		{
			$error.Clear()
			mcli-run SetupConnection -p server="$($AdminAddress)"
		}

		If($error.Count -eq 0)
		{
			$Script:Remoting = $True
			Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): This script is being run remotely against server $($AdminAddress)"
			If(![System.String]::IsNullOrEmpty($User))
			{
				Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): User=$($User)"
				Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Domain=$($Domain)"
			}
		}
		Else 
		{
			Write-Warning "Remoting could not be setup to server $($AdminAddress)"
			Write-Warning "Error returned is " $error[0]
			Write-Warning "Script cannot continue"
			Exit
		}
	}
}

Function VerifyPVSServices
{
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Verifying PVS SOAP and Stream Services are running"
	$soapserver = $Null
	$StreamService = $Null

	If($Script:Remoting)
	{
		$soapserver = Get-Service -ComputerName $AdminAddress -EA 0 | Where-Object {$_.DisplayName -like "*Citrix PVS Soap Server*"}
		$StreamService = Get-Service -ComputerName $AdminAddress -EA 0 | Where-Object {$_.DisplayName -like "*Citrix PVS Stream Service*"}
	}
	Else
	{
		$soapserver = Get-Service -EA 0 | Where-Object {$_.DisplayName -like "*Citrix PVS Soap Server*"}
		$StreamService = Get-Service -EA 0 | Where-Object {$_.DisplayName -like "*Citrix PVS Stream Service*"}
	}

	If($soapserver.Status -ne "Running")
	{
		If($Script:Remoting)
		{
			Write-Warning "The Citrix PVS Soap Server service is not Started on server $($AdminAddress)"
		}
		Else
		{
			Write-Warning "The Citrix PVS Soap Server service is not Started"
		}
		Write-Error "Script cannot continue.  See message above."
		Exit
	}

	If($StreamService.Status -ne "Running")
	{
		If($Script:Remoting)
		{
			Write-Warning "The Citrix PVS Stream Service service is not Started on server $($AdminAddress)"
		}
		Else
		{
			Write-Warning "The Citrix PVS Stream Service service is not Started"
		}
		Write-Error "Script cannot continue.  See message above."
		Exit
	}
}

Function VerifyPVSSOAPService
{
	Param([string]$PVSServer='')
	
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Verifying server $($PVSServer) is online"
	If(Test-Connection -ComputerName $server.servername -quiet -EA 0)
	{

		Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Verifying PVS SOAP Service is running on server $($PVSServer)"
		$soapserver = $Null

		$soapserver = Get-Service -ComputerName $PVSServer -EA 0 | Where-Object {$_.Name -like "soapserver"}

		If($soapserver.Status -ne "Running")
		{
			Write-Warning "The Citrix PVS Soap Server service is not Started on server $($PVSServer)"
			Write-Warning "Server $($PVSServer) cannot be processed.  See message above."
			Return $False
		}
		Else
		{
			Return $True
		}
	}
	Else
	{
		Write-Warning "The server $($PVSServer) is offLine or unreachable."
		Write-Warning "Server $($PVSServer) cannot be processed.  See message above."
		Return $False
	}
}

Function GetPVSVersion
{
	#get PVS major version
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Getting PVS version info"

	$error.Clear()
	$tempversion = mcli-info version
	If($? -and $error.Count -eq 0)
	{
		#build PVS version values
		$version = new-object System.Object 
		ForEach($record in $tempversion)
		{
			$index = $record.IndexOf(':')
			If($index -gt 0)
			{
				$property = $record.SubString(0, $index)
				$value = $record.SubString($index + 2)
				Add-Member -inputObject $version -MemberType NoteProperty -Name $property -Value $value
			}
		}
	} 
	Else 
	{
		Write-Warning "PVS version information could not be retrieved"
		[int]$NumErrors = $Error.Count
		For($x=0; $x -le $NumErrors; $x++)
		{
			Write-Warning "Error(s) returned: " $error[$x]
		}
		Write-Error "Script is terminating"
		#without version info, script should not proceed
		Exit
	}

	$Script:PVSVersion     = $Version.mapiVersion.SubString(0,1)
	$Script:PVSFullVersion = $Version.mapiVersion
}

Function GetPVSFarm
{
	#build PVS farm values
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Build PVS farm values"
	#there can only be one farm
	$GetWhat = "Farm"
	$GetParam = ""
	$ErrorTxt = "PVS Farm information"
	$Script:Farm = BuildPVSObject $GetWhat $GetParam $ErrorTxt

	If($Null -eq $Script:Farm)
	{
		#without farm info, script should not proceed
		Write-Error "PVS Farm information could not be retrieved.  Script is terminating."
		Exit
	}

	[string]$Script:Title = "PVS Assessment Report for Farm $($farm.FarmName)"
	SetFileName1 "$($farm.FarmName)"
}

Function ProcessPVSFarm
{
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing PVS Farm Information"
	#general tab
	Line 0 "PVS Farm Name: " $Script:farm.farmName
	Line 0 "Version: " $Script:PVSFullVersion
	
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing Licensing Tab"
	Line 0 "License server name: " $farm.licenseServer
	Line 0 "License server port: " $farm.licenseServerPort
	If($Script:PVSVersion -eq "5")
	{
		Line 0 "Use Datacenter licenses for desktops if no Desktop licenses are available: " -nonewline
		If($farm.licenseTradeUp -eq "1")
		{
			Line 0 "Yes"
		}
		Else
		{
			Line 0 "No"
		}
	}

	Line 0 "Enable auto-add: " -nonewline
	If($farm.autoAddEnabled -eq "1")
	{
		Line 0 "Yes"
		Line 0 "Add new devices to this site: " $farm.DefaultSiteName
		$Script:FarmAutoAddEnabled = $True
	}
	Else
	{
		Line 0 "No"	
		$Script:FarmAutoAddEnabled = $False
	}	
	
	#options tab
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing Options Tab"
	Line 0 "Enable auditing: " -nonewline
	If($Script:farm.auditingEnabled -eq "1")
	{
		Line 0 "Yes"
	}
	Else
	{
		Line 0 "No"
	}
	Line 0 "Enable offLine database support: " -nonewline
	If($Script:farm.offlineDatabaseSupportEnabled -eq "1")
	{
		Line 0 "Yes"	
	}
	Else
	{
		Line 0 "No"
	}

	If($Script:PVSVersion -eq "6" -or $Script:PVSVersion -eq "7")
	{
		#vDisk Version tab
		Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing vDisk Version Tab"
		Line 0 "vDisk Version"
		Line 1 "Alert if number of versions from base image exceeds: " $Script:farm.maxVersions
		Line 1 "Default access mode for new merge versions: " -nonewline
		Switch ($Script:farm.mergeMode)
		{
			0   {Line 0 "Production"; Break }
			1   {Line 0 "Test"; Break }
			2   {Line 0 "Maintenance"; Break}
			Default {Line 0 "Default access mode could not be determined: $($Script:farm.mergeMode)"; Break}
		}
	}
	
	#status tab
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing Status Tab"
	Line 0 "Database server: " $Script:farm.databaseServerName
	Line 0 "Database instance: " $Script:farm.databaseInstanceName
	Line 0 "Database: " $Script:farm.databaseName
	Line 0 "Failover Partner Server: " $Script:farm.failoverPartnerServerName
	Line 0 "Failover Partner Instance: " $Script:farm.failoverPartnerInstanceName
	If($Script:farm.adGroupsEnabled -eq "1")
	{
		Line 0 "Active Directory groups are used for access rights"
	}
	Else
	{
		Line 0 "Active Directory groups are not used for access rights"
	}
	Line 0 ""
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): "
}

Function ProcessPVSSite
{
	#build site values
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing Sites"
	$GetWhat = "site"
	$GetParam = ""
	$ErrorTxt = "PVS Site information"
	$PVSSites = BuildPVSObject $GetWhat $GetParam $ErrorTxt
	
	If($Null -eq $PVSSites)
	{
		Write-Host -foregroundcolor Red -backgroundcolor Black "WARNING: $(Get-Date): No Sites Found"
		Line 0 "No Sites Found "
	}
	Else
	{
		ForEach($PVSSite in $PVSSites)
		{
			Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing Site $($PVSSite.siteName)"
			Line 0 "Site Name: " $PVSSite.siteName

			#security tab
			Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing Security Tab"
			$temp = $PVSSite.SiteName
			$GetWhat = "authgroup"
			$GetParam = "sitename = $temp"
			$ErrorTxt = "Groups with Site Administrator access"
			$authgroups = BuildPVSObject $GetWhat $GetParam $ErrorTxt
			If($Null -ne $authGroups)
			{
				Line 1 "Groups with Site Administrator access:"
				ForEach($Group in $authgroups)
				{
					Line 2 $Group.authGroupName
				}
			}
			Else
			{
				Line 1 "Groups with Site Administrator access: No Site Administrators defined"
			}

			#MAK tab
			#MAK User and Password are encrypted

			#options tab
			Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing Options Tab"
			If($PVSVersion -eq "5" -or (($PVSVersion -eq "6" -or $PVSVersion -eq "7") -and $FarmAutoAddEnabled))
			{
				Line 1 "Add new devices to this collection: " -nonewline
				If($PVSSite.DefaultCollectionName)
				{
					Line 0 $PVSSite.DefaultCollectionName
				}
				Else
				{
					Line 0 "<No Default collection>"
				}
			}
			If($PVSVersion -eq "6" -or $PVSVersion -eq "7")
			{
				If($PVSVersion -eq "6")
				{
					Line 1 "Seconds between vDisk inventory scans: " $PVSSite.inventoryFilePollingInterval
				}

				#vDisk Update
				Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing vDisk Update Tab"
				If($PVSSite.enableDiskUpdate -eq "1")
				{
					Line 1 "Enable automatic vDisk updates on this site: Yes"
					Line 1 "Server to run vDisk updates for this site: " $PVSSite.diskUpdateServerName
				}
				Else
				{
					Line 1 "Enable automatic vDisk updates on this site: No"
				}
			}
			Line 0 ""
			
			#process all servers in site
			Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing Servers in Site $($PVSSite.siteName)"
			$temp = $PVSSite.SiteName
			$GetWhat = "server"
			$GetParam = "sitename = $temp"
			$ErrorTxt = "Servers for Site $temp"
			$servers = BuildPVSObject $GetWhat $GetParam $ErrorTxt
			
			If($Null -eq $servers)
			{
				Write-Host -foregroundcolor Red -backgroundcolor Black "WARNING: $(Get-Date): No Servers Found in Site $($PVSSite.siteName)"
				Line 0 "No Servers Found in Site $($PVSSite.siteName)"
			}
			Else
			{
				Line 1 "Servers"
				ForEach($Server in $Servers)
				{
					#first make sure the SOAP service is running on the server
					If(VerifyPVSSOAPService $Server.serverName)
					{
						Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing Server $($Server.serverName)"
						#general tab
						Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing General Tab"
						Line 2 "Name: " $Server.serverName
						Line 2 "Log events to the server's Windows Event Log: " -nonewline
						If($Server.eventLoggingEnabled -eq "1")
						{
							Line 0 "Yes"
						}
						Else
						{
							Line 0 "No"
						}
							
						Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing Network Tab"
						$test = $Server.ip.ToString()
						$test1 = $test.replace(",",", ")
						
						$tmparray= @($server.ip.split(","))
						
						ForEach($item in $tmparray)
						{
							$obj1 = New-Object -TypeName PSObject
							
							$obj1 | Add-Member -MemberType NoteProperty -Name ServerName 	-Value $Server.serverName
							$obj1 | Add-Member -MemberType NoteProperty -Name IPAddress		-Value $item
							$Script:StreamingIPAddresses +=  $obj1
						}
						If($Script:PVSVersion -eq "7")
						{
							Line 2 "Streaming IP addresses: " $test1
						}
						Else
						{
							Line 2 "IP addresses: " $test1
						}
						Line 2 "First port: " $Server.firstPort
						Line 2 "Last port: " $Server.lastPort
						If($Script:PVSVersion -eq "7")
						{
							Line 2 "Management IP: " $Server.managementIp
						}
							
						#create array for appendix A
						
						Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Gather Advanced server info for Appendix A and B"
						$obj1 = New-Object -TypeName PSObject
						$obj2 = New-Object -TypeName PSObject
						
						$obj1 | Add-Member -MemberType NoteProperty -Name ServerName              -Value $Server.serverName
						$obj1 | Add-Member -MemberType NoteProperty -Name ThreadsPerPort          -Value $Server.threadsPerPort
						$obj1 | Add-Member -MemberType NoteProperty -Name BuffersPerThread        -Value $Server.buffersPerThread
						$obj1 | Add-Member -MemberType NoteProperty -Name ServerCacheTimeout      -Value $Server.serverCacheTimeout
						$obj1 | Add-Member -MemberType NoteProperty -Name LocalConcurrentIOLimit  -Value $Server.localConcurrentIoLimit
						$obj1 | Add-Member -MemberType NoteProperty -Name RemoteConcurrentIOLimit -Value $Server.remoteConcurrentIoLimit
						$obj1 | Add-Member -MemberType NoteProperty -Name maxTransmissionUnits    -Value $Server.maxTransmissionUnits
						$obj1 | Add-Member -MemberType NoteProperty -Name IOBurstSize             -Value $Server.ioBurstSize
						$obj1 | Add-Member -MemberType NoteProperty -Name NonBlockingIOEnabled    -Value $Server.nonBlockingIoEnabled

						$obj2 | Add-Member -MemberType NoteProperty -Name ServerName              -Value $Server.serverName
						$obj2 | Add-Member -MemberType NoteProperty -Name BootPauseSeconds        -Value $Server.bootPauseSeconds
						$obj2 | Add-Member -MemberType NoteProperty -Name MaxBootSeconds          -Value $Server.maxBootSeconds
						$obj2 | Add-Member -MemberType NoteProperty -Name MaxBootDevicesAllowed   -Value $Server.maxBootDevicesAllowed
						$obj2 | Add-Member -MemberType NoteProperty -Name vDiskCreatePacing       -Value $Server.vDiskCreatePacing
						$obj2 | Add-Member -MemberType NoteProperty -Name LicenseTimeout          -Value $Server.licenseTimeout
						
						$Script:AdvancedItems1 +=  $obj1
						$Script:AdvancedItems2 +=  $obj2
						
						GetComputerWMIInfo $server.ServerName
							
						GetConfigWizardInfo $server.ServerName
							
						GetDisableTaskOffloadInfo $server.ServerName
							
						GetBootstrapInfo $server
							
						GetPVSServiceInfo $server.ServerName

						GetBadStreamingIPAddresses $server.ServerName
						
						GetMiscRegistryKeys $server.ServerName
					}
					Else
					{
						Line 2 "Name: " $Server.serverName
						Line 2 "Server was not processed because the server was offLine or the SOAP Service was not running"
						Line 0 ""
					}
				}
			}

			#process all device collections in site
			Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing all device collections in site"
			$Temp = $PVSSite.SiteName
			$GetWhat = "Collection"
			$GetParam = "siteName = $Temp"
			$ErrorTxt = "Device Collection information"
			$Collections = BuildPVSObject $GetWhat $GetParam $ErrorTxt

			If($Null -ne $Collections)
			{
				Line 1 "Device Collections"
				ForEach($Collection in $Collections)
				{
					Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing Collection $($Collection.collectionName)"
					Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing General Tab"
					Line 2 "Name: " $Collection.collectionName

					Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing Security Tab"
					$Temp = $Collection.collectionId
					$GetWhat = "authGroup"
					$GetParam = "collectionId = $Temp"
					$ErrorTxt = "Device Collection information"
					$AuthGroups = BuildPVSObject $GetWhat $GetParam $ErrorTxt

					$DeviceAdmins = $False
					If($Null -ne $AuthGroups)
					{
						Line 2 "Groups with 'Device Administrator' access:"
						ForEach($AuthGroup in $AuthGroups)
						{
							$Temp = $authgroup.authGroupName
							$GetWhat = "authgroupusage"
							$GetParam = "authgroupname = $Temp"
							$ErrorTxt = "Device Collection Administrator usage information"
							$AuthGroupUsages = BuildPVSObject $GetWhat $GetParam $ErrorTxt
							If($Null -ne $AuthGroupUsages)
							{
								ForEach($AuthGroupUsage in $AuthGroupUsages)
								{
									If($AuthGroupUsage.role -eq "300")
									{
										$DeviceAdmins = $True
										Line 3 $authgroup.authGroupName
									}
								}
							}
						}
					}
					If(!$DeviceAdmins)
					{
						Line 2 "Groups with 'Device Administrator' access: None defined"
					}

					$DeviceOperators = $False
					If($Null -ne $AuthGroups)
					{
						Line 2 "Groups with 'Device Operator' access:"
						ForEach($AuthGroup in $AuthGroups)
						{
							$Temp = $authgroup.authGroupName
							$GetWhat = "authgroupusage"
							$GetParam = "authgroupname = $Temp"
							$ErrorTxt = "Device Collection Operator usage information"
							$AuthGroupUsages = BuildPVSObject $GetWhat $GetParam $ErrorTxt
							If($Null -ne $AuthGroupUsages)
							{
								ForEach($AuthGroupUsage in $AuthGroupUsages)
								{
									If($AuthGroupUsage.role -eq "400")
									{
										$DeviceOperators = $True
										Line 3 $authgroup.authGroupName
									}
								}
							}
						}
					}
					If(!$DeviceOperators)
					{
						Line 2 "Groups with 'Device Operator' access: None defined"
					}

					Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing Auto-Add Tab"
					If($Script:FarmAutoAddEnabled)
					{
						Line 2 "Template target device: " $Collection.templateDeviceName
						If(![String]::IsNullOrEmpty($Collection.autoAddPrefix) -or ![String]::IsNullOrEmpty($Collection.autoAddPrefix))
						{
							Line 2 "Device Name"
						}
						If(![String]::IsNullOrEmpty($Collection.autoAddPrefix))
						{
							Line 3 "Prefix: " $Collection.autoAddPrefix
						}
						Line 3 "Length: " $Collection.autoAddNumberLength
						Line 3 "Zero fill: " -nonewline
						If($Collection.autoAddZeroFill -eq "1")
						{
							Line 0 "Yes"
						}
						Else
						{
							Line 0 "No"
						}
						If(![String]::IsNullOrEmpty($Collection.autoAddPrefix))
						{
							Line 3 "Suffix: " $Collection.autoAddSuffix
						}
						Line 3 "Last incremental #: " $Collection.lastAutoAddDeviceNumber
					}
					Else
					{
						Line 2 "The auto-add feature is not enabled at the PVS Farm level"
					}
					#for each collection process each device
					Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing the first device in each collection"
					$Temp = $Collection.collectionId
					$GetWhat = "deviceInfo"
					$GetParam = "collectionId = $Temp"
					$ErrorTxt = "Device Info information"
					$Devices = BuildPVSObject $GetWhat $GetParam $ErrorTxt
					
					If($Null -ne $Devices)
					{
						Line 0 ""
						$Device = $Devices[0]
						Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing Device $($Device.deviceName)"
						If($Device.type -eq "3")
						{
							Line 3 "Device with Personal vDisk Properties"
						}
						Else
						{
							Line 3 "Target Device Properties"
						}
						Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing General Tab"
						Line 3 "Name: " $Device.deviceName
						If(($PVSVersion -eq "6" -or $PVSVersion -eq "7") -and $Device.type -ne "3")
						{
							Line 3 "Type: " -nonewline
							Switch ($Device.type)
							{
								0 {Line 0 "Production"; Break}
								1 {Line 0 "Test"; Break}
								2 {Line 0 "Maintenance"; Break}
								3 {Line 0 "Personal vDisk"; Break}
								Default {Line 0 "Device type could not be determined: $($Device.type)"; Break}
							}
						}
						If($Device.type -ne "3")
						{
							Line 3 "Boot from: " -nonewline
							Switch ($Device.bootFrom)
							{
								1 {Line 0 "vDisk"; Break}
								2 {Line 0 "Hard Disk"; Break}
								3 {Line 0 "Floppy Disk"; Break}
								Default {Line 0 "Boot from could not be determined: $($Device.bootFrom)"; Break}
							}
						}
						Line 3 "Port: " $Device.port
						If($Device.type -ne "3")
						{
							Line 3 "Disabled: " -nonewline
							If($Device.enabled -eq "1")
							{
								Line 0 "No"
							}
							Else
							{
								Line 0 "Yes"
							}
						}
						Else
						{
							Line 3 "vDisk: " $Device.diskLocatorName
							Line 3 "Personal vDisk Drive: " $Device.pvdDriveLetter
						}
						Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing vDisks Tab"
						#process all vdisks for this device
						$Temp = $Device.deviceName
						$GetWhat = "DiskInfo"
						$GetParam = "deviceName = $Temp"
						$ErrorTxt = "Device vDisk information"
						$vDisks = BuildPVSObject $GetWhat $GetParam $ErrorTxt
						If($Null -ne $vDisks)
						{
							ForEach($vDisk in $vDisks)
							{
								Line 3 "vDisk Name: $($vDisk.storeName)`\$($vDisk.diskLocatorName)"
							}
						}
						Line 3 "List local hard drive in boot menu: " -nonewline
						If($Device.localDiskEnabled -eq "1")
						{
							Line 0 "Yes"
						}
						Else
						{
							Line 0 "No"
						}
						
						DeviceStatus $Device
					}
					Else
					{
						Line 2 "No Target Devices found. Device Collection is empty."
						Line 0 ""
						$Script:EmptyDeviceCollections += $Collection.collectionName
					}
				}
			}
		}
	}

	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): "
}

Function DeviceStatus
{
	Param($xDevice)

	If($Null -eq $xDevice -or $xDevice.status -eq "" -or $xDevice.status -eq "0")
	{
		Line 3 "Target device inactive"
	}
	Else
	{
		Line 2 "Target device active"
		Line 3 "IP Address: " $xDevice.ip
		Line 3 "Server: $($xDevice.serverName)"
		Line 3 "Server IP: $($xDevice.serverIpConnection)"
		Line 3 "Server Port: $($xDevice.serverPortConnection)"
		Line 3 "vDisk: " $xDevice.diskLocatorName
		Line 3 "vDisk version: " $xDevice.diskVersion
		Line 3 "vDisk name: " $xDevice.diskFileName
		Line 3 "vDisk access: " -nonewline
		Switch ($xDevice.diskVersionAccess)
		{
			0 {Line 0 "Production"; Break}
			1 {Line 0 "Test"; Break}
			2 {Line 0 "Maintenance"; Break}
			3 {Line 0 "Personal vDisk"; Break}
			Default {Line 0 "vDisk access type could not be determined: $($xDevice.diskVersionAccess)"; Break}
		}
		If($PVSVersion -eq "7")
		{
			Line 3 "Local write cache disk:$($xDevice.localWriteCacheDiskSize)GB"
			Line 3 "Boot mode:" -nonewline
			Switch($xDevice.bdmBoot)
			{
				0 {Line 0 "PXE boot"; Break}
				1 {Line 0 "BDM disk"; Break}
				Default {Line 0 "Boot mode could not be determined: $($xDevice.bdmBoot)"; Break}
			}
		}
		Switch($xDevice.licenseType)
		{
			0 {Line 3 "No License"; Break}
			1 {Line 3 "Desktop License"; Break}
			2 {Line 3 "Server License"; Break}
			5 {Line 3 "OEM SmartClient License"; Break}
			6 {Line 3 "XenApp License"; Break}
			7 {Line 3 "XenDesktop License"; Break}
			Default {Line 0 "Device license type could not be determined: $($xDevice.licenseType)"; Break}
		}
		
		Line 3 "Logging level: " -nonewline
		Switch ($xDevice.logLevel)
		{
			0   {Line 0 "Off"; Break}
			1   {Line 0 "Fatal"; Break}
			2   {Line 0 "Error"; Break}
			3   {Line 0 "Warning"; Break}
			4   {Line 0 "Info"; Break}
			5   {Line 0 "Debug"; Break}
			6   {Line 0 "Trace"; Break}
			Default {Line 0 "Logging level could not be determined: $($xDevice.logLevel)"; Break}
		}
	}
	Line 0 ""
}

Function GetBootstrapInfo
{
	Param([object]$server)

	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing Bootstrap files"
	Line 2 "Bootstrap settings"
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing Bootstrap files for Server $($server.servername)"
	#first get all bootstrap files for the server
	$temp = $server.serverName
	$GetWhat = "ServerBootstrapNames"
	$GetParam = "serverName = $temp"
	$ErrorTxt = "Server Bootstrap Name information"
	$BootstrapNames = BuildPVSObject $GetWhat $GetParam $ErrorTxt

	#Now that the list of bootstrap names has been gathered
	#We have the mandatory parameter to get the bootstrap info
	#there should be at least one bootstrap filename
	If($Null -ne $Bootstrapnames)
	{
		#cannot use the BuildPVSObject Function here
		$serverbootstraps = @()
		ForEach($Bootstrapname in $Bootstrapnames)
		{
			#get serverbootstrap info
			$error.Clear()
			$tempserverbootstrap = Mcli-Get ServerBootstrap -p name="$($Bootstrapname.name)",servername="$($server.serverName)"
			If($error.Count -eq 0)
			{
				$serverbootstrap = $Null
				ForEach($record in $tempserverbootstrap)
				{
					If($record.length -gt 5 -and $record.substring(0,6) -eq "Record")
					{
						If($Null -ne $serverbootstrap)
						{
							$serverbootstraps +=  $serverbootstrap
						}
						$serverbootstrap = new-object System.Object
						#add the bootstrapname name value to the serverbootstrap object
						$property = "BootstrapName"
						$value = $Bootstrapname.name
						Add-Member -inputObject $serverbootstrap -MemberType NoteProperty -Name $property -Value $value
					}
					$index = $record.IndexOf(':')
					If($index -gt 0)
					{
						$property = $record.SubString(0, $index)
						$value = $record.SubString($index + 2)
						If($property -ne "Executing")
						{
							Add-Member -inputObject $serverbootstrap -MemberType NoteProperty -Name $property -Value $value
						}
					}
				}
				$serverbootstraps +=  $serverbootstrap
			}
			Else
			{
				Line 2 "Server Bootstrap information could not be retrieved"
				Line 2 "Error returned is " $error[0].FullyQualifiedErrorId.Split(',')[0].Trim()
			}
		}
		If($Null -ne $ServerBootstraps)
		{
			Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing Bootstrap file $($ServerBootstrap.Bootstrapname)"
			Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing General Tab"
			ForEach($ServerBootstrap in $ServerBootstraps)
			{
				Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Gather Bootstrap info for Appendix D"
				$obj1 = New-Object -TypeName PSObject
				
				$obj1 | Add-Member -MemberType NoteProperty -Name ServerName 	-Value $Server.serverName
				$obj1 | Add-Member -MemberType NoteProperty -Name BootstrapName	-Value $ServerBootstrap.Bootstrapname
				$obj1 | Add-Member -MemberType NoteProperty -Name IP1        	-Value $ServerBootstrap.bootserver1_Ip
				$obj1 | Add-Member -MemberType NoteProperty -Name IP2        	-Value $ServerBootstrap.bootserver2_Ip
				$obj1 | Add-Member -MemberType NoteProperty -Name IP3        	-Value $ServerBootstrap.bootserver3_Ip
				$obj1 | Add-Member -MemberType NoteProperty -Name IP4        	-Value $ServerBootstrap.bootserver4_Ip
				$Script:BootstrapItems +=  $obj1

				Line 3 "Bootstrap file: " $ServerBootstrap.Bootstrapname
				If($ServerBootstrap.bootserver1_Ip -ne "0.0.0.0")
				{
					Line 3 "IP Address: " $ServerBootstrap.bootserver1_Ip
					Line 3 "Subnet Mask: " $ServerBootstrap.bootserver1_Netmask
					Line 3 "Gateway: " $ServerBootstrap.bootserver1_Gateway
					Line 3 "Port: " $ServerBootstrap.bootserver1_Port
				}
				If($ServerBootstrap.bootserver2_Ip -ne "0.0.0.0")
				{
					Line 3 "IP Address: " $ServerBootstrap.bootserver2_Ip
					Line 3 "Subnet Mask: " $ServerBootstrap.bootserver2_Netmask
					Line 3 "Gateway: " $ServerBootstrap.bootserver2_Gateway
					Line 3 "Port: " $ServerBootstrap.bootserver2_Port
				}
				If($ServerBootstrap.bootserver3_Ip -ne "0.0.0.0")
				{
					Line 3 "IP Address: " $ServerBootstrap.bootserver3_Ip
					Line 3 "Subnet Mask: " $ServerBootstrap.bootserver3_Netmask
					Line 3 "Gateway: " $ServerBootstrap.bootserver3_Gateway
					Line 3 "Port: " $ServerBootstrap.bootserver3_Port
				}
				If($ServerBootstrap.bootserver4_Ip -ne "0.0.0.0")
				{
					Line 3 "IP Address: " $ServerBootstrap.bootserver4_Ip
					Line 3 "Subnet Mask: " $ServerBootstrap.bootserver4_Netmask
					Line 3 "Gateway: " $ServerBootstrap.bootserver4_Gateway
					Line 3 "Port: " $ServerBootstrap.bootserver4_Port
				}
				Line 0 ""
				Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing Options Tab"
				Line 3 "Verbose mode: " -nonewline
				If($ServerBootstrap.verboseMode -eq "1")
				{
					Line 0 "Yes"
				}
				Else
				{
					Line 0 "No"
				}
				Line 3 "Interrupt safe mode: " -nonewline
				If($ServerBootstrap.interruptSafeMode -eq "1")
				{
					Line 0 "Yes"
				}
				Else
				{
					Line 0 "No"
				}
				Line 3 "Advanced Memory Support: " -nonewline
				If($ServerBootstrap.paeMode -eq "1")
				{
					Line 0 "Yes"
				}
				Else
				{
					Line 0 "No"
				}
				Line 3 "Network recovery method: " -nonewline
				If($ServerBootstrap.bootFromHdOnFail -eq "0")
				{
					Line 0 "Restore network connection"
				}
				Else
				{
					Line 0 "Reboot to Hard Drive after $($ServerBootstrap.recoveryTime) seconds"
				}
				Line 3 "Login polling timeout: " -nonewline
				If($ServerBootstrap.pollingTimeout -eq "")
				{
					Line 0 "5000 (milliseconds)"
				}
				Else
				{
					Line 0 "$($ServerBootstrap.pollingTimeout) (milliseconds)"
				}
				Line 3 "Login general timeout: " -nonewline
				If($ServerBootstrap.generalTimeout -eq "")
				{
					Line 0 "5000 (milliseconds)"
				}
				Else
				{
					Line 0 "$($ServerBootstrap.generalTimeout) (milliseconds)"
				}
				Line 0 ""
			}
		}
	}
	Else
	{
		Line 2 "No Bootstrap names available"
	}
	Line 0 ""
}

Function GetPVSServiceInfo
{
	Param([string]$ComputerName)

	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing PVS Services for Server $($server.servername)"
	$Services = Get-WmiObject -ComputerName $ComputerName Win32_Service -EA 0 | Where-Object {$_.DisplayName -like "Citrix PVS*"} | Select-Object displayname, name, status, startmode, started, startname, state 
	
	If($? -and $Null -ne $Services)
	{
		ForEach($Service in $Services)
		{
			$obj1 = New-Object -TypeName PSObject
			
			$obj1 | Add-Member -MemberType NoteProperty -Name ServerName 	-Value $ComputerName
			$obj1 | Add-Member -MemberType NoteProperty -Name DisplayName	-Value $Service.DisplayName
			$obj1 | Add-Member -MemberType NoteProperty -Name Name  		-Value $Service.Name
			$obj1 | Add-Member -MemberType NoteProperty -Name Status  		-Value $Service.Status
			$obj1 | Add-Member -MemberType NoteProperty -Name StartMode  	-Value $Service.StartMode
			$obj1 | Add-Member -MemberType NoteProperty -Name Started  		-Value $Service.Started
			$obj1 | Add-Member -MemberType NoteProperty -Name StartName  	-Value $Service.StartName
			$obj1 | Add-Member -MemberType NoteProperty -Name State  		-Value $Service.State

			[array]$Actions = sc.exe \\$ComputerName qfailure $Service.Name
			
			If($Actions.Length -gt 0)
			{
				If(($Actions -like "*RESTART -- Delay*") -or ($Actions -like "*RUN PROCESS -- Delay*") -or ($Actions -like "*REBOOT -- Delay*"))
				{
					$cnt = 0
					ForEach($Item in $Actions)
					{
						Switch ($Item)
						{
							{$Item -like "*RESTART -- Delay*"}		{$cnt++; $obj1 | Add-Member -MemberType NoteProperty -Name $("FailureAction$($Cnt)")	-Value "Restart the Service"}
							{$Item -like "*RUN PROCESS -- Delay*"}	{$cnt++; $obj1 | Add-Member -MemberType NoteProperty -Name $("FailureAction$($Cnt)")	-Value "Run a Program"}
							{$Item -like "*REBOOT -- Delay*"}		{$cnt++; $obj1 | Add-Member -MemberType NoteProperty -Name $("FailureAction$($Cnt)")	-Value "Restart the Computer"}
						}
					}
				}
				Else
				{
					$obj1 | Add-Member -MemberType NoteProperty -Name FailureAction1	-Value "Take no Action"
					$obj1 | Add-Member -MemberType NoteProperty -Name FailureAction2	-Value "Take no Action"
					$obj1 | Add-Member -MemberType NoteProperty -Name FailureAction3	-Value "Take no Action"
				}
			}
			
			$Script:PVSServiceItems +=  $obj1
		}
	}
	Else
	{
		Line 2 "No PVS services found for $($ComputerName)"
	}
	Line 0 ""
}

Function GetBadStreamingIPAddresses
{
	Param([string]$ComputerName)
	#function updated by Andrew Williamson @ Fujitsu Services to handle servers with multiple NICs
	#further optiization by Michael B. Smith

	#loop through the configured streaming ip address and compare to the physical configured ip addresses
	#if a streaming ip address is not in the list of physical ip addresses, it is a bad streaming ip address
	ForEach ($Stream in ($Script:StreamingIPAddresses | Where-Object {$_.Servername -eq $ComputerName})) {
		$exists = $false
		:outerLoop ForEach ($ServerNIC in $Script:NICIPAddresses.Item($ComputerName)) 
		{
			ForEach ($IP in $ServerNIC) 
			{ 
				# there could be more than one IP
				If ($Stream.IPAddress -eq $IP) 
				{
					$Exists = $true
					break :outerLoop
				}
			}
		}
		if (!$exists) 
		{
			$obj1 = New-Object -TypeName PSObject
			$obj1 | Add-Member -MemberType NoteProperty -Name ServerName 	-Value $ComputerName
			$obj1 | Add-Member -MemberType NoteProperty -Name IPAddress		-Value $Stream.IPAddress
			$Script:BadIPs += $obj1
		}
	}
}

Function ProcessvDisksinFarm
{
	#process all vDisks in site
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing all vDisks in site"
	[int]$NumberofvDisks = 0
	$GetWhat = "DiskInfo"
	$GetParam = ""
	$ErrorTxt = "Disk information"
	$Disks = BuildPVSObject $GetWhat $GetParam $ErrorTxt

	Line 0 "vDisks in Farm"
	If($Null -ne $Disks)
	{
		ForEach($Disk in $Disks)
		{
			Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing vDisk $($Disk.diskLocatorName)"
			Line 1 $Disk.diskLocatorName
			If($Script:PVSVersion -eq "5")
			{
				#PVS 5.x
				Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing General Tab"
				Line 2 "Store: " $Disk.storeName
				Line 2 "Site: " $Disk.siteName
				Line 2 "Filename: " $Disk.diskLocatorName
				Line 2 "Size: " (($Disk.diskSize/1024)/1024)/1024 -nonewline
				Line 0 " MB"
				If(![String]::IsNullOrEmpty($Disk.serverName))
				{
					Line 2 "Use this server to provide the vDisk: " $Disk.serverName
				}
				Else
				{
					Line 2 "Subnet Affinity: " -nonewline
					Switch ($Disk.subnetAffinity)
					{
						0 {Line 0 "None"; Break}
						1 {Line 0 "Best Effort"; Break}
						2 {Line 0 "Fixed"; Break}
						Default {Line 2 "Subnet Affinity could not be determined: $($Disk.subnetAffinity)"; Break}
					}
					Line 2 "Rebalance Enabled: " -nonewline
					If($Disk.rebalanceEnabled -eq "1")
					{
						Line 0 "Yes"
						Line 2 "Trigger Percent: $($Disk.rebalanceTriggerPercent)"
					}
					Else
					{
						Line 0 "No"
					}
				}
				Line 2 "Allow use of this vDisk: " -nonewline
				If($Disk.enabled -eq "1")
				{
					Line 0 "Yes"
					If($Disk.deviceCount -gt 0)
					{
						$NumberofvDisks++
					}
				}
				Else
				{
					Line 0 "No"
				}
				Line 2 "Access mode: " -nonewline
				If($Disk.writeCacheType -eq "0")
				{
					Line 0 "Private Image (single device, read/write access)"
				}
				ElseIf($Disk.writeCacheType -eq "7")
				{
					Line 0 "Difference Disk Image"
				}
				Else
				{
					Line 0 "Standard Image (multi-device, read-only access)"
					Line 2 "Cache type: " -nonewline
					Switch ($Disk.writeCacheType)
					{
						0   {Line 0 "Private Image"; Break}
						1   {
								Line 0 "Cache on server"
								
								$obj1 = New-Object -TypeName PSObject
								
								$obj1 | Add-Member -MemberType NoteProperty -Name StoreName -Value $Disk.storeName
								$obj1 | Add-Member -MemberType NoteProperty -Name SiteName  -Value $Disk.siteName
								$obj1 | Add-Member -MemberType NoteProperty -Name vDiskName -Value $Disk.diskLocatorName
								$Script:CacheOnServer +=  $obj1
								Break
							}
						2   {Line 0 "Cache encrypted on server disk"; Break}
						3   {
							Line 0 "Cache in device RAM"
							Line 2 "Cache Size: $($Disk.writeCacheSize) MBs"; Break
							}
						4   {Line 0 "Cache on device's HD"; Break}
						5   {Line 0 "Cache encrypted on device's hard disk"; Break}
						6   {Line 0 "RAM Disk"; Break}
						7   {Line 0 "Difference Disk"; Break}
						Default {Line 0 "Cache type could not be determined: $($Disk.writeCacheType)"; Break}
					}
				}
				If($Disk.activationDateEnabled -eq "0")
				{
					Line 2 "Enable automatic updates for the vDisk: " -nonewline
					If($Disk.autoUpdateEnabled -eq "1")
					{
						Line 0 "Yes"
					}
					Else
					{
						Line 0 "No"
					}
					Line 2 "Apply vDisk updates as soon as they are detected by the server"
				}
				Else
				{
					Line 2 "Enable automatic updates for the vDisk: " -nonewline
					If($Disk.autoUpdateEnabled -eq "1")
					{
						Line 0 "Yes"
					}
					Else
					{
						Line 0 "No"
					}
					Line 2 "Schedule the next vDisk update to occur on: $($Disk.activeDate)"
				}
				Line 2 "Microsoft license type: " -nonewline
				Switch ($Disk.licenseMode)
				{
					0 {Line 0 "None"; Break}
					1 {Line 0 "Multiple Activation Key (MAK)"; Break}
					2 {Line 0 "Key Management Service (KMS)"; Break}
					Default {Line 0 "Volume License Mode could not be determined: $($Disk.licenseMode)"; Break}
				}
				#options tab
				Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing Options Tab"
				Line 2 "High availability (HA): " -nonewline
				If($Disk.haEnabled -eq "1")
				{
					Line 0 "Yes"
				}
				Else
				{
					Line 0 "No"
				}
				Line 2 "AD machine account password management: " -nonewline
				If($Disk.adPasswordEnabled -eq "1")
				{
					Line 0 "Yes"
				}
				Else
				{
					Line 0 "No"
				}
				
				Line 2 "Printer management: " -nonewline
				If($Disk.printerManagementEnabled -eq "1")
				{
					Line 0 "Yes"
				}
				Else
				{
					Line 0 "No"
				}
			}
			Else
			{
				#PVS 6.x or 7.x
				Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing vDisk Properties"
				Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing General Tab"
				Line 2 "Site: " $Disk.siteName
				Line 2 "Store: " $Disk.storeName
				Line 2 "Filename: " $Disk.diskLocatorName
				Line 2 "Size: " (($Disk.diskSize/1024)/1024)/1024 -nonewline
				Line 0 " MB"
				Line 2 "VHD block size: " $Disk.vhdBlockSize -nonewline
				Line 0 " KB"
				Line 2 "Access mode: " -nonewline
				If($Disk.writeCacheType -eq "0")
				{
					Line 0 "Private Image (single device, read/write access)"
				}
				Else
				{
					Line 0 "Standard Image (multi-device, read-only access)"
					Line 2 "Cache type: " -nonewline
					Switch ($Disk.writeCacheType)
					{
						0   {Line 0 "Private Image"; Break}
						1   {
								Line 0 "Cache on server"
								
								$obj1 = New-Object -TypeName PSObject
								
								$obj1 | Add-Member -MemberType NoteProperty -Name StoreName -Value $Disk.storeName
								$obj1 | Add-Member -MemberType NoteProperty -Name SiteName  -Value $Disk.siteName
								$obj1 | Add-Member -MemberType NoteProperty -Name vDiskName -Value $Disk.diskLocatorName
								$Script:CacheOnServer +=  $obj1
								Break
							}
						3   {
							Line 0 "Cache in device RAM"
							Line 2 "Cache Size: $($Disk.writeCacheSize) MBs"; Break
							}
						4   {Line 0 "Cache on device's hard disk"; Break}
						6   {Line 0 "RAM Disk"; Break}
						7   {Line 0 "Difference Disk"; Break}
						9   {Line 0 "Cache in device RAM with overflow on hard disk"; Break}
						Default {Line 0 "Cache type could not be determined: $($Disk.writeCacheType)"; Break}
					}
				}
				If(![String]::IsNullOrEmpty($Disk.menuText))
				{
					Line 2 "BIOS boot menu text: " $Disk.menuText
				}
				Line 2 "Enable AD machine acct pwd mgmt: " -nonewline
				If($Disk.adPasswordEnabled -eq "1")
				{
					Line 0 "Yes"
				}
				Else
				{
					Line 0 "No"
				}
				
				Line 2 "Enable printer management: " -nonewline
				If($Disk.printerManagementEnabled -eq "1")
				{
					Line 0 "Yes"
				}
				Else
				{
					Line 0 "No"
				}
				Line 2 "Enable streaming of this vDisk: " -nonewline
				If($Disk.Enabled -eq "1")
				{
					Line 0 "Yes"
					If($Disk.deviceCount -gt 0)
					{
						$NumberofvDisks++
					}
				}
				Else
				{
					Line 0 "No"
				}
				Line 2 "Microsoft license type: " -nonewline
				Switch ($Disk.licenseMode)
				{
					0 {Line 0 "None"; Break}
					1 {Line 0 "Multiple Activation Key (MAK)"; Break}
					2 {Line 0 "Key Management Service (KMS)"; Break}
					Default {Line 0 "Volume License Mode could not be determined: $($Disk.licenseMode)"; Break}
				}

				Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing Auto Update Tab"
				If($Disk.activationDateEnabled -eq "0")
				{
					Line 2 "Enable automatic updates for the vDisk: " -nonewline
					If($Disk.autoUpdateEnabled -eq "1")
					{
						Line 0 "Yes"
					}
					Else
					{
						Line 0 "No"
					}
					Line 2 "Apply vDisk updates as soon as they are detected by the server"
				}
				Else
				{
					Line 2 "Enable automatic updates for the vDisk: " -nonewline
					If($Disk.autoUpdateEnabled -eq "1")
					{
						Line 0 "Yes"
					}
					Else
					{
						Line 0 "No"
					}
					Line 2 "Schedule the next vDisk update to occur on: $($Disk.activeDate)"
				}
				#process Versions menu
				#get versions info
				#thanks to the PVS Product team for their help in understanding the Versions information
				Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing vDisk Versions"
				$error.Clear()
				$MCLIGetResult = Mcli-Get DiskVersion -p diskLocatorName="$($Disk.diskLocatorName)",storeName="$($disk.storeName)",siteName="$($disk.siteName)"
				If($error.Count -eq 0)
				{
					#build versions object
					$PluralObject = @()
					$SingleObject = $Null
					ForEach($record in $MCLIGetResult)
					{
						If($record.length -gt 5 -and $record.substring(0,6) -eq "Record")
						{
							If($Null -ne $SingleObject)
							{
								$PluralObject += $SingleObject
							}
							$SingleObject = new-object System.Object
						}

						$index = $record.IndexOf(':')
						If($index -gt 0)
						{
							$property = $record.SubString(0, $index)
							$value    = $record.SubString($index + 2)
							If($property -ne "Executing")
							{
								Add-Member -inputObject $SingleObject -MemberType NoteProperty -Name $property -Value $value
							}
						}
					}
					$PluralObject += $SingleObject
					$DiskVersions = $PluralObject
					
					If($Null -ne $DiskVersions)
					{
						#get the current booting version
						#by default, the $DiskVersions object is in version number order lowest to highest
						#the initial or base version is 0 and always exists
						[string]$BootingVersion = "0"
						[bool]$BootOverride = $False
						ForEach($DiskVersion in $DiskVersions)
						{
							If($DiskVersion.access -eq "3")
							{
								#override i.e. manually selected boot version
								$BootingVersion = $DiskVersion.version
								$BootOverride = $True
								Break
							}
							ElseIf($DiskVersion.access -eq "0" -and $DiskVersion.IsPending -eq "0" )
							{
								$BootingVersion = $DiskVersion.version
								$BootOverride = $False
							}
						}
						
						Line 2 "Boot production devices from version: " -NoNewLine
						If($BootOverride)
						{
							Line 0 $BootingVersion
						}
						Else
						{
							Line 0 "Newest released"
						}
						Line 0 ""
						
						$VersionFlag = $False
						ForEach($DiskVersion in $DiskVersions)
						{
							Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing vDisk Version $($DiskVersion.version)"
							Line 2 "Version: " -NoNewLine
							If($DiskVersion.version -eq $BootingVersion)
							{
								Line 0 "$($DiskVersion.version) (Current booting version)"
							}
							Else
							{
								Line 0 $DiskVersion.version
							}
							If($DiskVersion.version -gt $Script:farm.maxVersions -and $VersionFlag -eq $False)
							{
								$VersionFlag = $True
								Line 2 "Version of vDisk is $($DiskVersion.version) which is greater than the limit of $($Script:farm.maxVersions). Consider merging."
								$Script:VersionsToMerge += $Disk.diskLocatorName
								
							}
							Line 2 "Created: " $DiskVersion.createDate
							If(![String]::IsNullOrEmpty($DiskVersion.scheduledDate))
							{
								Line 2 "Released: " $DiskVersion.scheduledDate
							}
							Line 2 "Devices: " $DiskVersion.deviceCount
							Line 2 "Access: " -NoNewLine
							Switch ($DiskVersion.access)
							{
								"0" {Line 0 "Production"; Break}
								"1" {Line 0 "Maintenance"; Break}
								"2" {Line 0 "Maintenance Highest Version"; Break}
								"3" {Line 0 "Override"; Break}
								"4" {Line 0 "Merge"; Break}
								"5" {Line 0 "Merge Maintenance"; Break}
								"6" {Line 0 "Merge Test"; Break}
								"7" {Line 0 "Test"; Break}
								Default {Line 0 "Access could not be determined: $($DiskVersion.access)"; Break}
							}
							Line 2 "Type: " -NoNewLine
							Switch ($DiskVersion.type)
							{
								"0" {Line 0 "Base"; Break}
								"1" {Line 0 "Manual"; Break}
								"2" {Line 0 "Automatic"; Break}
								"3" {Line 0 "Merge"; Break}
								"4" {Line 0 "Merge Base"; Break}
								Default {Line 0 "Type could not be determined: $($DiskVersion.type)"; Break}
							}
							If(![String]::IsNullOrEmpty($DiskVersion.description))
							{
								Line 2 "Properties: " $DiskVersion.description
							}
							Line 2 "Can Delete: "  -NoNewLine
							Switch ($DiskVersion.canDelete)
							{
								0 {Line 0 "No"; Break}
								1 {Line 0 "Yes"; Break}
							}
							Line 2 "Can Merge: "  -NoNewLine
							Switch ($DiskVersion.canMerge)
							{
								0 {Line 0 "No"; Break}
								1 {Line 0 "Yes"; Break}
							}
							Line 2 "Can Merge Base: "  -NoNewLine
							Switch ($DiskVersion.canMergeBase)
							{
								0 {Line 0 "No"; Break}
								1 {Line 0 "Yes"; Break}
							}
							Line 2 "Can Promote: "  -NoNewLine
							Switch ($DiskVersion.canPromote)
							{
								0 {Line 0 "No"; Break}
								1 {Line 0 "Yes"; Break}
							}
							Line 2 "Can Revert back to Test: "  -NoNewLine
							Switch ($DiskVersion.canRevertTest)
							{
								0 {Line 0 "No"; Break}
								1 {Line 0 "Yes"; Break}
							}
							Line 2 "Can Revert back to Maintenance: "  -NoNewLine
							Switch ($DiskVersion.canRevertMaintenance)
							{
								0 {Line 0 "No"; Break}
								1 {Line 0 "Yes"; Break}
							}
							Line 2 "Can Set Scheduled Date: "  -NoNewLine
							Switch ($DiskVersion.canSetScheduledDate)
							{
								0 {Line 0 "No"; Break}
								1 {Line 0 "Yes"; Break}
							}
							Line 2 "Can Override: "  -NoNewLine
							Switch ($DiskVersion.canOverride)
							{
								0 {Line 0 "No"; Break}
								1 {Line 0 "Yes"; Break}
							}
							Line 2 "Is Pending: "  -NoNewLine
							Switch ($DiskVersion.isPending)
							{
								0 {Line 0 "No, version Scheduled Date has occurred"; Break}
								1 {Line 0 "Yes, version Scheduled Date has not occurred"; Break}
							}
							Line 2 "Replication Status: " -NoNewLine
							Switch ($DiskVersion.goodInventoryStatus)
							{
								0 {Line 0 "Not available on all servers"; Break}
								1 {Line 0 "Available on all servers"; Break}
								Default {Line 0 "Replication status could not be determined: $($DiskVersion.goodInventoryStatus)"; Break}
							}
							Line 2 "Disk Filename: " $DiskVersion.diskFileName
							Line 0 ""
						}
					}
				}
				Else
				{
					Line 0 "Disk Version information could not be retrieved"
					Line 0 "Error returned is " $error[0].FullyQualifiedErrorId.Split(',')[0].Trim()
				}
				
				#process vDisk Load Balancing Menu
				Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing vDisk Load Balancing Menu"
				If(![String]::IsNullOrEmpty($Disk.serverName))
				{
					Line 2 "Use this server to provide the vDisk: " $Disk.serverName
				}
				Else
				{
					Line 2 "Subnet Affinity: " -nonewline
					Switch ($Disk.subnetAffinity)
					{
						0 {Line 0 "None"; Break}
						1 {Line 0 "Best Effort"; Break}
						2 {Line 0 "Fixed"; Break}
						Default {Line 0 "Subnet Affinity could not be determined: $($Disk.subnetAffinity)"; Break}
					}
					Line 2 "Rebalance Enabled: " -nonewline
					If($Disk.rebalanceEnabled -eq "1")
					{
						Line 0 "Yes"
						Line 2 "Trigger Percent: $($Disk.rebalanceTriggerPercent)"
					}
					Else
					{
						Line 0 "No"
					}
				}
			}
			Line 0 ""
		}
	}

	Line 1 "Number of vDisks that are Enabled and have active connections: " $NumberofvDisks
	Line 0 ""
	# http://blogs.citrix.com/2013/07/03/pvs-internals-2-how-to-properly-size-your-memory/
	[decimal]$RecRAM = ((2 + ($NumberofvDisks * 2)) * 1.15)
	$RecRAM = "{0:N0}" -f $RecRAM
	Line 1 "Recommended RAM for each PVS Server using XenDesktop vDisks: $($RecRAM)GB"
	[decimal]$RecRAM = ((2 + ($NumberofvDisks * 4)) * 1.15)
	$RecRAM = "{0:N0}" -f $RecRAM
	Line 1 "Recommended RAM for each PVS Server using XenApp vDisks: $($RecRAM)GB"
	Line 0 ""
	Line 1 "This script is not able to tell if a vDisk is running XenDesktop or XenApp."
	Line 1 "The RAM calculation is done based on both scenarios. The original formula is:"
	Line 1 "2GB + (#XA_vDisk * 4GB) + (#XD_vDisk * 2GB) + 15% (Buffer)"
	Line 1 'PVS Internals 2 - How to properly size your memory by Martin Zugec'
	Line 1 'https://www.citrix.com/blogs/2013/07/03/pvs-internals-2-how-to-properly-size-your-memory/'
	Line 0 ""
}

Function ProcessStores
{
	#process the stores now
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing Stores"
	Line 0 "Stores Properties"
	$GetWhat = "Store"
	$GetParam = ""
	$ErrorTxt = "Farm Store information"
	$Stores = BuildPVSObject $GetWhat $GetParam $ErrorTxt
	If($Null -ne $Stores)
	{
		ForEach($Store in $Stores)
		{
			Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing Store $($Store.StoreName)"
			Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing General Tab"
			Line 1 "Name: " $Store.StoreName
			
			Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing Servers Tab"
			Line 1 "Servers"
			#find the servers (and the site) that serve this store
			$GetWhat = "Server"
			$GetParam = ""
			$ErrorTxt = "Server information"
			$Servers = BuildPVSObject $GetWhat $GetParam $ErrorTxt
			$StoreServers = @()
			If($Null -ne $Servers)
			{
				ForEach($Server in $Servers)
				{
					Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing Server $($Server.serverName)"
					$Temp = $Server.serverName
					$GetWhat = "ServerStore"
					$GetParam = "serverName = $Temp"
					$ErrorTxt = "Server Store information"
					$ServerStore = BuildPVSObject $GetWhat $GetParam $ErrorTxt
                    $Providers = $ServerStore | Where-Object {$_.StoreName -eq $Store.Storename}
                    If($Providers)
					{
                       ForEach ($Provider in $Providers)
					   {
                          $StoreServers += $Provider.ServerName
                       }
                    }
				}	
			}
			Line 2 "Servers that provide this store:"
			ForEach($StoreServer in $StoreServers)
			{
				Line 3 $StoreServer
			}

			Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Processing Paths Tab"
			Line 1 "Paths"

			If(Test-Path $Store.path -EA 0)
			{
				Line 2 "Default store path: $($Store.path)"
			}
			Else
			{
				Line 2 "Default store path: $($Store.path) (Invalid path)"
			}
			
			If(![String]::IsNullOrEmpty($Store.cachePath))
			{
				Line 2 "Default write-cache paths: "
				$WCPaths = @($Store.cachePath.Split(","))
				ForEach($WCPath in $WCPaths)
				{
					If(Test-Path $WCPath -EA 0)
					{
						Line 3 $WCPath
					}
					Else
					{
						Line 3 "$($WCPath) (Invalid path)"
					}
					#Line 3 $WCPath
				}
			}
			Line 0 ""
		}
	}
	Else
	{
		Line 1 "There are no Stores configured"
	}
	Line 0 ""
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): "
}

Function OutputAppendixA
{
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Create Appendix A Advanced Server Items (Server/Network)"
	#sort the array by servername
	$Script:AdvancedItems1 = $Script:AdvancedItems1 | Sort-Object ServerName

	Line 0 "Appendix A - Advanced Server Items (Server/Network)"
	Line 0 ""
	Line 1 "Server Name      Threads  Buffers  Server   Local       Remote      Ethernet  IO     Enable      "
	Line 1 "                 per      per      Cache    Concurrent  Concurrent  MTU       Burst  Non-blocking"
	Line 1 "                 Port     Thread   Timeout  IO Limit    IO Limit              Size   IO          "
	Line 1 "================================================================================================="

	ForEach($Item in $Script:AdvancedItems1)
	{
		Line 1 ( "{0,-16} {1,-8} {2,-8} {3,-8} {4,-11} {5,-11} {6,-9} {7,-6} {8,-8}" -f `
		$Item.serverName, $Item.threadsPerPort, $Item.buffersPerThread, $Item.serverCacheTimeout, `
		$Item.localConcurrentIoLimit, $Item.remoteConcurrentIoLimit, $Item.maxTransmissionUnits, $Item.ioBurstSize, `
		$Item.nonBlockingIoEnabled )
	}
	Line 0 ""

	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Finished Creating Appendix A - Advanced Server Items (Server/Network)"
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): "
}

Function OutputAppendixB
{
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Create Appendix B Advanced Server Items (Pacing/Device)"
	#sort the array by servername
	$Script:AdvancedItems2 = $Script:AdvancedItems2 | Sort-Object ServerName

	Line 0 "Appendix B - Advanced Server Items (Pacing/Device)"
	Line 0 ""
	Line 1 "Server Name      Boot     Maximum  Maximum  vDisk     License"
	Line 1 "                 Pause    Boot     Devices  Creation  Timeout"
	Line 1 "                 Seconds  Time     Booting  Pacing           "
	Line 1 "============================================================="
	###### "123451234512345  9999999  9999999  9999999  99999999  9999999

	ForEach($Item in $Script:AdvancedItems2)
	{
		Line 1 ( "{0,-16} {1,-8} {2,-8} {3,-8} {4,-9} {5,-8}" -f `
		$Item.serverName, $Item.bootPauseSeconds, $Item.maxBootSeconds, $Item.maxBootDevicesAllowed, `
		$Item.vDiskCreatePacing, $Item.licenseTimeout )
	}
	Line 0 ""

	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Finished Creating Appendix B - Advanced Server Items (Pacing/Device)"
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): "
}

Function OutputAppendixC
{
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Create Appendix C Config Wizard Items"

	#sort the array by servername
	$Script:ConfigWizItems = $Script:ConfigWizItems | Sort-Object ServerName
	
	Line 0 "Appendix C - Configuration Wizard Settings"
	Line 0 ""
	Line 1 "Server Name      DHCP        PXE       TFTP    User                                               " 
	Line 1 "                 Services    Services  Option  Account                                            "
	Line 1 "================================================================================================"

	If($Script:ConfigWizItems)
	{
		ForEach($Item in $Script:ConfigWizItems)
		{
			Line 1 ( "{0,-16} {1,-11} {2,-9} {3,-7} {4,-50}" -f `
			$Item.serverName, $Item.DHCPServicesValue, $Item.PXEServicesValue, $Item.TFTPOptionValue, `
			$Item.UserAccount )
		}
	}
	Else
	{
		Line 1 "<None found>"
	}
	Line 0 ""
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Finished Creating Appendix C - Config Wizard Items"
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): "
}

Function OutputAppendixD
{
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Create Appendix D Server Bootstrap Items"

	#sort the array by bootstrapname and servername
	$Script:BootstrapItems = $Script:BootstrapItems | Sort-Object BootstrapName, ServerName
	
	Line 0 "Appendix D - Server Bootstrap Items"
	Line 0 ""
	Line 1 "Bootstrap Name   Server Name      IP1              IP2              IP3              IP4" 
	Line 1 "===================================================================================================="
    ########123456789012345  XXXXXXXXXXXXXXXX 123.123.123.123  123.123.123.123  123.123.123.123  123.123.123.123
	If($Script:BootstrapItems)
	{
		ForEach($Item in $Script:BootstrapItems)
		{
			Line 1 ( "{0,-16} {1,-16} {2,-16} {3,-16} {4,-16} {5,-16}" -f `
			$Item.BootstrapName, $Item.serverName, $Item.IP1, $Item.IP2, $Item.IP3, $Item.IP4 )
		}
	}
	Else
	{
		Line 1 "<None found>"
	}
	Line 0 ""

	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Finished Creating Appendix D - Server Bootstrap Items"
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): "
}

Function OutputAppendixE
{
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Create Appendix E DisableTaskOffload Setting"

	#sort the array by bootstrapname and servername
	$Script:TaskOffloadItems = $Script:TaskOffloadItems | Sort-Object ServerName
	
	Line 0 "Appendix E - DisableTaskOffload Settings"
	Line 0 ""
	Line 0 "Best Practices for Configuring Provisioning Services Server on a Network"
	Line 0 "http://support.citrix.com/article/CTX117374"
	Line 0 ""
	Line 1 "Server Name      DisableTaskOffload Setting" 
	Line 1 "==========================================="
	If($Script:TaskOffloadItems)
	{
		ForEach($Item in $Script:TaskOffloadItems)
		{
			Line 1 ( "{0,-16} {1,-16}" -f $Item.serverName, $Item.TaskOffloadValue )
		}
	}
	Else
	{
		Line 1 "<None found>"
	}
	Line 0 ""

	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Finished Creating Appendix E - DisableTaskOffload Setting"
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): "
}

Function OutputAppendixF
{
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Create Appendix F PVS Services"

	#sort the array by displayname and servername
	$Script:PVSServiceItems = $Script:PVSServiceItems | Sort-Object DisplayName, ServerName
	
	Line 0 "Appendix F - Server PVS Service Items"
	Line 0 ""
	Line 1 "Display Name                      Server Name      Service Name  Status Startup Type Started State   Log on as" 
	Line 1 "========================================================================================================================================"
    ########123456789012345678901234567890123 123456789012345  1234567890123 123456 123456789012 1234567 
	#displayname, servername, name, status, startmode, started, startname, state 
	If($Script:PVSServiceItems)
	{
		ForEach($Item in $Script:PVSServiceItems)
		{
			Line 1 ( "{0,-33} {1,-16} {2,-13} {3,-6} {4,-12} {5,-7} {6,-7} {7,-35}" -f `
			$Item.DisplayName, $Item.serverName, $Item.Name, $Item.Status, $Item.StartMode, `
			$Item.Started, $Item.State, $Item.StartName )
		}
	}
	Else
	{
		Line 1 "<None found>"
	}
	Line 0 ""

	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Finished Creating Appendix F - PVS Services"
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): "
}

Function OutputAppendixF2
{
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Create Appendix F2 PVS Services Failure Actions"

	#sort the array by displayname and servername
	$Script:PVSServiceItems = $Script:PVSServiceItems | Sort-Object DisplayName, ServerName
	
	Line 0 "Appendix F2 - Server PVS Service Items Failure Actions"
	Line 0 ""
	Line 1 "Display Name                      Server Name      Service Name  Failure Action 1     Failure Action 2     Failure Action 3    " 
	Line 1 "==============================================================================================================================="
	If($Script:PVSServiceItems)
	{
		ForEach($Item in $Script:PVSServiceItems)
		{
			Line 1 ( "{0,-33} {1,-16} {2,-13} {3,-20} {4,-20} {5,-20}" -f `
			$Item.DisplayName, $Item.serverName, $Item.Name, $Item.FailureAction1, $Item.FailureAction2, $Item.FailureAction3 )
		}
	}
	Else
	{
		Line 1 "<None found>"
	}
	Line 0 ""

	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Finished Creating Appendix F2 - PVS Services Failure Actions"
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): "
}

Function OutputAppendixG
{
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Create Appendix G vDisks to Merge"

	#sort the array
	$Script:VersionsToMerge = $Script:VersionsToMerge | Sort-Object
	
	Line 0 "Appendix G - vDisks to Consider Merging"
	Line 0 ""
	Line 1 "vDisk Name" 
	Line 1 "========================================"
	If($Script:VersionsToMerge)
	{
		ForEach($Item in $Script:VersionsToMerge)
		{
			Line 1 ( "{0,-40}" -f $Item )
		}
	}
	Else
	{
		Line 1 "<None found>"
	}
	Line 0 ""

	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Finished Creating Appendix G - vDisks to Merge"
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): "
}

Function OutputAppendixH
{
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Create Appendix H Empty Device Collections"

	#sort the array
	$Script:EmptyDeviceCollections = $Script:EmptyDeviceCollections | Sort-Object
	
	Line 0 "Appendix H - Empty Device Collections"
	Line 0 ""
	Line 1 "Device Collection Name" 
	Line 1 "=================================================="
	If($Script:EmptyDeviceCollections)
	{
		ForEach($Item in $Script:EmptyDeviceCollections)
		{
			Line 1 ( "{0,-50}" -f $Item )
		}
	}
	Else
	{
		Line 1 "<None found>"
	}
	Line 0 ""

	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Finished Creating Appendix G - Empty Device Collections"
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): "
}

Function ProcessvDisksWithNoAssociation
{
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Finding vDisks with no Target Device Associations"
	$UnassociatedvDisks = @()
	$GetWhat = "diskLocator"
	$GetParam = ""
	$ErrorTxt = "Disk Locator information"
	$DiskLocators = BuildPVSObject $GetWhat $GetParam $ErrorTxt
	
	If($Null -eq $DiskLocators)
	{
		Write-Host -foregroundcolor Red -backgroundcolor Black "VERBOSE: $(Get-Date): No DiskLocators Found"
		OutputAppendixI $Null
	}
	Else
	{
		ForEach($DiskLocator in $DiskLocators)
		{
			#get the diskLocatorId
			$DiskLocatorId = $DiskLocator.diskLocatorId
			
			#now pass the disklocatorid to get device
			#if nothing found, the vDisk is unassociated
			$temp = $DiskLocatorId
			$GetWhat = "device"
			$GetParam = "diskLocatorId = $temp"
			$ErrorTxt = "Device for DiskLocatorId $DiskLocatorId information"
			$Results = BuildPVSObject $GetWhat $GetParam $ErrorTxt
			
			If($Null -ne $Results)
			{
				#device found, vDisk is associated
			}
			Else
			{
				#no device found that uses this vDisk
				$UnassociatedvDisks += $DiskLocator.diskLocatorName
			}
		}
		
		If($UnassociatedvDisks.Count -gt 0)
		{
			Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Found $($UnassociatedvDisks.Count) vDisks with no Target Device Associations"
			OutputAppendixI $UnassociatedvDisks
		}
		Else
		{
			Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): All vDisks have Target Device Associations"
			Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): "
			OutputAppendixI $Null
		}
	}
}

Function OutputAppendixI
{
	Param([array]$vDisks)

	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Create Appendix I Unassociated vDisks"

	Line 0 "Appendix I - vDisks with no Target Device Associations"
	Line 0 ""
	Line 1 "vDisk Name" 
	Line 1 "========================================"
	
	If($vDisks)
	{
		#sort the array
		$vDisks = $vDisks | Sort-Object
	
		ForEach($Item in $vDisks)
		{
			Line 1 ( "{0,-40}" -f $Item )
		}
	}
	Else
	{
		Line 1 "<None found>"
	}
	
	Line 0 ""

	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Finished Creating Appendix I - Unassociated vDisks"
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): "
}

Function OutputAppendixJ
{
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Create Appendix J Bad Streaming IP Addresses"

	#sort the array by bootstrapname and servername
	$Script:BadIPs = $Script:BadIPs | Sort-Object ServerName, IPAddress
	
	Line 0 "Appendix J - Bad Streaming IP Addresses"
	Line 0 "Streaming IP addresses that do not exist on the server"
	Line 0 ""
	Line 1 "Server Name      Streaming IP Address" 
	Line 1 "====================================="
	If($Script:BadIPs) 
	{
		ForEach($Item in $Script:BadIPs)
		{
			Line 1 ( "{0,-16} {1,-16}" -f $Item.serverName, $Item.IPAddress )
		}
	}
	Else
	{
		Line 1 "<None found>"
	}
	Line 0 ""

	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Finished Creating Appendix J Bad Streaming IP Addresses"
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): "
}

Function OutputAppendixK
{
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Create Appendix K Misc Registry Items"

	#sort the array by regkey, regvalue and servername
	$Script:MiscRegistryItems = $Script:MiscRegistryItems | Sort-Object RegKey, RegValue, ServerName
	
	Line 0 "Appendix K - Misc Registry Items"
	Line 0 "Miscellaneous Registry Items That May or May Not Exist on Servers"
	Line 0 "These items may or may not be needed"
	Line 0 "This Appendix is strictly for server comparison only"
	Line 0 ""
	Line 1 "Registry Key                                                      Registry Value                 Data            Server Name    " 
	Line 1 "================================================================================================================================"
	
	$Save = ""
	$First = $True
	If($Script:MiscRegistryItems)
	{
		ForEach($Item in $Script:MiscRegistryItems)
		{
			If(!$First -and $Save -ne "$($Item.RegKey.ToString())$($Item.RegValue.ToString())")
			{
				Line 0 ""
			}

			Line 1 ( "{0,-65} {1,-30} {2,-15} {3,-15}" -f $Item.RegKey, $Item.RegValue, $Item.Value, $Item.serverName )
			$Save = "$($Item.RegKey.ToString())$($Item.RegValue.ToString())"
			If($First)
			{
				$First = $False
			}
		}
	}
	Else
	{
		Line 1 "<None found>"
	}
	Line 0 ""

	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Finished Creating Appendix K Misc Registry Items"
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): "
}

Function OutputAppendixL
{
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Create Appendix L vDisks Configured for Server Side Caching"
	#sort the array 
	$Script:CacheOnServer = $Script:CacheOnServer | Sort-Object StoreName,SiteName,vDiskName

	Line 0 "Appendix L - vDisks Configured for Server Side Caching"
	Line 0 ""
	Line 1 "Store Name                Site Name                 vDisk Name               "
	Line 1 "============================================================================="
	       #1234567890123456789012345 1234567890123456789012345 1234567890123456789012345

	ForEach($Item in $Script:CacheOnServer)
	{
		Line 1 ( "{0,-25} {1,-25} {2,-25}" -f `
		$Item.StoreName, $Item.SiteName, $Item.vDiskName )
	}
	Line 0 ""

	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Finished Creating Appendix L vDisks Configured for Server Side Caching"
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): "
}

#script begins

$script:startTime = get-date

$global:output = ""

Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Checking for McliPSSnapin"
If(!(Check-NeededPSSnapins "McliPSSnapIn")){
	#We're missing Citrix Snapins that we need
	Write-Error "Missing Citrix PowerShell Snap-ins Detected, check the console above for more information. Script will now close."
	Exit
}

SetupRemoting

VerifyPVSServices

GetPVSVersion

GetPVSFarm

ProcessPVSFarm

ProcessPVSSite

ProcessvDisksinFarm

ProcessStores

OutputAppendixA

OutputAppendixB

OutputAppendixC

OutputAppendixD

OutputAppendixE

OutputAppendixF

OutputAppendixF2

OutputAppendixG

OutputAppendixH

#outputs AppendixI
ProcessvDisksWithNoAssociation

OutputAppendixJ

OutputAppendixK

OutputAppendixL

Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Finishing up document"
#end of document processing

SaveandCloseTextDocument

Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Script has completed"
Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): "

$GotFile = $False

If(Test-Path "$($Script:FileName1)")
{
	Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): $($Script:FileName1) is ready for use"
	$GotFile = $True
}
Else
{
	Write-Warning "$(Get-Date): Unable to save the output file, $($Script:FileName1)"
	Write-Error "Unable to save the output file, $($Script:FileName1)"
}

#email output file if requested
If($GotFile -and ![System.String]::IsNullOrEmpty( $SmtpServer ))
{
	$emailAttachment = $Script:FileName1

	SendEmail $emailAttachment
}

Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): "

#http://poshtips.com/measuring-elapsed-time-in-powershell/
Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Script started: $($Script:StartTime)"
Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Script ended: $(Get-Date)"
$runtime = $(Get-Date) - $Script:StartTime
$Str = [string]::format("{0} days, {1} hours, {2} minutes, {3}.{4} seconds", `
	$runtime.Days, `
	$runtime.Hours, `
	$runtime.Minutes, `
	$runtime.Seconds,
	$runtime.Milliseconds)
Write-Host -foregroundcolor Yellow -backgroundcolor Black "VERBOSE: $(Get-Date): Elapsed time: $($Str)"
$runtime = $Null
$Str = $Null

# SIG # Begin signature block
# MIIhUgYJKoZIhvcNAQcCoIIhQzCCIT8CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUnvZt+3NEukUxdxkFTZexTD+g
# paygghy8MIIDtzCCAp+gAwIBAgIQDOfg5RfYRv6P5WD8G/AwOTANBgkqhkiG9w0B
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
# CisGAQQBgjcCAQQwIwYJKoZIhvcNAQkEMRYEFBuR6Gc7oy36EykB+8oJOurRXgZu
# MA0GCSqGSIb3DQEBAQUABIIBABAUhuP8Nqlaur4D39kms9chGIA/wg6aKbGJJyIm
# LLK0pirUGG9Vquy9zowcFDb0kqMhzG6Qop/ECyZ63x1lFGHDkCSnS+9vsbvYtknd
# F3xOs6AOuheKraZNmKRO/KNKgQNw7pSY6JdvLNBUIZRH+NksEgirJ2qdQrDPDFdV
# JbxjeqsY1yZbdzuNaT9Akh6ctSyZrMqSXb54QuYwgcNVasu8xWXWWDQBeSJxDmH4
# E9rmbqXxXbzlsp9wdXLU7OcOeDg45u4H1jaareVjn2/mJQfegQGM3XUxGQ9Ub+RT
# 5hQHDsZjz9zReRwLSNAUPpwVzYipWY6kxZPhWL0cJUkAnO6hggIPMIICCwYJKoZI
# hvcNAQkGMYIB/DCCAfgCAQEwdjBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGln
# aUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhE
# aWdpQ2VydCBBc3N1cmVkIElEIENBLTECEAMBmgI6/1ixa9bV6uYX8GYwCQYFKw4D
# AhoFAKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8X
# DTE4MDQxMjIwMDEzNlowIwYJKoZIhvcNAQkEMRYEFK+VoMH0CQitRQd9Tzw4Zfch
# eIpMMA0GCSqGSIb3DQEBAQUABIIBADduu3gzg4FZn+1LHa18nea0I40vTPUs32Z7
# GljKDnjtYHbsNZbKFGTpxXx7Dw3TdPx4j77Ocy72vv3/BSNVi+g/n5SOFAgvhYpy
# VGhMTsPTMzlvmJIoO1O4+CQSu+QUriLV9bZ8vcaMpYF9auRXCI9bUpjgdoynVtA+
# Focz25KU0GXlY5fIZI5CRmfZux0f38o+knOvYwswEzI6g/0swrOx13PICakD3lC0
# 7fipfiLx0psEZl89smBNMoeqgJu5d+ikgJ9m1/8IUk/dr2aGsQdu+/YQZdN82Jgs
# GkQQ8NX8oKsyFqpJdCKTHjW9TMXvDrQnG2rfIycFa/7Bh1lUUnc=
# SIG # End signature block
