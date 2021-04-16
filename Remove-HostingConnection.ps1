#Requires -Version 3.0

#region help text

<#
.SYNOPSIS
	Removes a hosting connection in a Citrix XenDesktop 7.xx Site.
.DESCRIPTION
	Removes either:
	
		A hosting connection and all resource connections in a Citrix 
		XenDesktop 7.xx Site if there are any active provisioning tasks, or
		
		A resource connection within a hosting connection that has the active task(s).
	
	This script requires at least PowerShell version 3 but runs best in version 5.

	You do NOT have to run this script on a Controller. This script was developed 
	and run from a Windows 10 VM.
	
	You can run this script remotely using the -AdminAddress (AA) parameter.
	
	This script supports all versions of XenApp/XenDesktop 7.xx. 
	
	Logs all actions to the Configuration Logging database.
	
	If there are no active tasks for the hosting connection selected, 
	then NOTHING is removed from the Site. The script will state there were
	no active tasks found and end.
	
	Supports WhatIf and Confirm thanks to @adbertram for his clear and simple articles.
	https://4sysops.com/archives/the-powershell-whatif-parameter/
	https://4sysops.com/archives/confirm-confirmpreference-and-confirmimpact-in-powershell/
	
	Thanks to Michael B. Smith for the code review. @essentialexch on Twitter
	
	******************************************************************************
	*   WARNING             WARNING      	       WARNING             WARNING   *
	******************************************************************************
	
	Do not run this script when there are valid active provisioning tasks processing.

	Because of the way the Get-ProvTask cmdlet works, this script retrieves the
	first task where the Active property is TRUE, regardless of whether the task
	is a current task or an old task left in the system.

	This script will remove the first active task it finds and then, depending on
	the -ResourceConnectionOnly switch, will attempt to delete all resource 
	connections in the specified hosting connection and then attempt to delete the 
	specified hosting connection.
	
	******************************************************************************
	*   WARNING             WARNING      	       WARNING             WARNING   *
	******************************************************************************
	
.PARAMETER AdminAddress
	Specifies the address of a XenDesktop controller the PowerShell snapins will connect to. 
	This can be provided as a hostname or an IP address. 
	This parameter defaults to LocalHost.
	This parameter has an alias of AA.
.PARAMETER ResourceConnectionOnly
	Specifies that only the resource connection that has the active task(s) 
	should be deleted.
	Do NOT delete the hosting connection or the Broker's hypervisor connection.
	This parameter defaults to False which means all resource and hosting 
	connections are deleted that have an active task.
	This parameter has an alias of RCO.
.EXAMPLE
	PS C:\PSScript > .\Remove-HostingConnection.ps1
	
	The computer running the script for the AdminAddress (LocalHost by default).
	Change LocalHost to the name of the computer ($env:ComputerName).
	Verify the computer is a Delivery Controller. If not, end the script.
	Display a list of all hosting connections in the Site.
	Once a hosting connection is selected, all provisioning tasks are stopped 
	and removed.
	Objects are removed in this order: provisioning tasks, resource connections, 
	the hosting connection.
.EXAMPLE
	PS C:\PSScript > .\Remove-HostingConnection.ps1 -AdminAddress DDC715
	
	DDC715 for the AdminAddress.
	Verify DDC715 is a Delivery Controller. If not, end the script.
	Display a list of all hosting connections in the Site.
	Once a hosting connection is selected, all provisioning tasks are stopped 
	and removed.
	Objects are removed in this order: provisioning tasks, resource connections, 
	the hosting connection.
.EXAMPLE
	PS C:\PSScript > .\Remove-HostingConnection.ps1 -ResourceConnectionOnly
	
	The computer running the script for the AdminAddress (LocalHost by default).
	Change LocalHost to the name of the computer ($env:ComputerName).
	Verify the computer is a Delivery Controller. If not, end the script.
	Display a list of all hosting connections in the Site.
	Once a hosting connection is selected, all provisioning tasks are stopped 
	and removed.
	Once all provisioning tasks are removed, only the resource connection 
	is removed.
.EXAMPLE
	PS C:\PSScript > .\Remove-HostingConnection.ps1 -RCO -AA DDC715
	
	DDC715 for the AdminAddress.
	Verify DDC715 is a Delivery Controller. If not, end the script.
	Display a list of all hosting connections in the Site.
	Once a hosting connection is selected, all provisioning tasks are stopped 
	and removed.
	Once all provisioning tasks are removed, only the resource connection is 
	removed.
.INPUTS
	None.  You cannot pipe objects to this script.
.OUTPUTS
	No objects are output from this script.
.LINK
	http://carlwebster.com/unable-delete-citrix-xenappxendesktop-7-xx-hosting-connection-resource-currently-active-background-action/
	http://carlwebster.com/new-powershell-script-remove-hostingconnection-v1-0/
.NOTES
	NAME: Remove-HostingConnection.ps1
	VERSION: 1.01
	AUTHOR: Carl Webster, Sr. Solutions Architect for Choice Solutions, LLC
	LASTEDIT: November 6, 2017
#>

#endregion

#region script parameters
[CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = "Medium")]

Param(
	[parameter(Mandatory=$False)] 
	[ValidateNotNullOrEmpty()]
	[Alias("AA")]
	[string]$AdminAddress="LocalHost",

	[parameter(Mandatory=$False)] 
	[ValidateNotNullOrEmpty()]
	[Alias("RCO")]
	[switch]$ResourceConnectionOnly=$False

	)
#endregion

#region script change log	
#webster@carlwebster.com
#@carlwebster on Twitter
#Sr. Solutions Architect for Choice Solutions, LLC
#http://www.CarlWebster.com
#Created on September 26, 2017

# Version 1.0 released to the community on November 2, 2017
#
# Version 1.01 6-Nov-2017
#	When -WhatIf or -Confirm with No or -Confirm with No to All is used, do not log non-actions as failures
#
#endregion

#region script setup
Set-StrictMode -Version 2

#force on
$SaveEAPreference = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'
$ConfirmPreference = "High"

Function TestAdminAddress
{
	Param([string]$Cname)
	
	#if computer name is an IP address, get host name from DNS
	#http://blogs.technet.com/b/gary/archive/2009/08/29/resolve-ip-addresses-to-hostname-using-powershell.aspx
	#help from Michael B. Smith
	$ip = $CName -as [System.Net.IpAddress]
	If($ip)
	{
		$Result = [System.Net.Dns]::gethostentry($ip)
		
		If($? -and $Null -ne $Result)
		{
			$CName = $Result.HostName
			Write-Host -ForegroundColor Yellow "Delivery Controller has been renamed from $ip to $CName"
		}
		Else
		{
			$ErrorActionPreference = $SaveEAPreference
			Write-Error "`n`n`t`tUnable to resolve $CName to a hostname.`n`n`t`tRerun the script using -AdminAddress with a valid Delivery Controller name.`n`n`t`tScript cannot continue.`n`n"
			Exit
		}
	}

	#if computer name is localhost, get actual computer name
	If($CName -eq "localhost")
	{
		$CName = $env:ComputerName
		Write-Host -ForegroundColor Yellow "Delivery Controller has been renamed from localhost to $CName"
		Write-Host -ForegroundColor Yellow "Testing to see if $CName is a Delivery Controller"
		$result = Get-BrokerServiceStatus -adminaddress $cname
		If($? -and $result.ServiceStatus -eq "Ok")
		{
			#the computer is a Delivery Controller
			Write-Host -ForegroundColor Yellow "Computer $CName is a Delivery Controller"
			Return $CName
		}
		
		#the computer is not a Delivery Controller
		Write-Host -ForegroundColor Yellow "Computer $CName is not a Delivery Controller"
		$ErrorActionPreference = $SaveEAPreference
		Write-Error "`n`n`t`tComputer $CName is not a Delivery Controller.`n`n`t`tRerun the script using -AdminAddress with a valid Delivery Controller name.`n`n`t`tScript cannot continue.`n`n"
		Exit
	}

	If(![String]::IsNullOrEmpty($CName)) 
	{
		#get computer name
		#first test to make sure the computer is reachable
		Write-Host -ForegroundColor Yellow "Testing to see if $CName is online and reachable"
		If(Test-Connection -ComputerName $CName -quiet)
		{
			Write-Host -ForegroundColor Yellow "Server $CName is online."
			Write-Host -ForegroundColor Yellow "Testing to see if $CName is a Delivery Controller"
			
			$result = Get-BrokerServiceStatus -adminaddress $cname
			If($? -and $result.ServiceStatus -eq "Ok")
			{
				#the computer is a Delivery Controller
				Write-Host -ForegroundColor Yellow "Computer $CName is a Delivery Controller"
				Return $CName
			}
			
			#the computer is not a Delivery Controller
			Write-Host -ForegroundColor Yellow "Computer $CName is not a Delivery Controller"
			$ErrorActionPreference = $SaveEAPreference
			Write-Error "`n`n`t`tComputer $CName is not a Delivery Controller.`n`n`t`tRerun the script using -AdminAddress with a valid Delivery Controller name.`n`n`t`tScript cannot continue.`n`n"
			Exit
		}
		Else
		{
			Write-Host -ForegroundColor Yellow "Server $CName is offline"
			$ErrorActionPreference = $SaveEAPreference
			Write-Error "`n`n`t`tDelivery Controller $CName is offline.`n`t`tScript cannot continue.`n`n"
			Exit
		}
	}

	Return $CName
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
	$loadedSnapins += get-pssnapin | % {$_.name}
	$registeredSnapins += get-pssnapin -Registered | % {$_.name}

	ForEach($Snapin in $Snapins)
	{
		#check if the snapin is loaded
		If(!($LoadedSnapins -contains $snapin))
		{
			#Check if the snapin is missing
			If(!($RegisteredSnapins -contains $Snapin))
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
				Add-PSSnapin -Name $snapin -EA 0 *>$Null
			}
		}
	}

	If($FoundMissingSnapin)
	{
		Write-Warning "Missing Windows PowerShell snap-ins Detected:"
		$missingSnapins | % {Write-Warning "($_)"}
		Return $False
	}
	Else
	{
		Return $True
	}
}

If(!(Check-NeededPSSnapins "Citrix.Broker.Admin.V2",
"Citrix.ConfigurationLogging.Admin.V1",
"Citrix.Host.Admin.V2",
"Citrix.MachineCreation.Admin.V2"))

{
	#We're missing Citrix Snapins that we need
	$ErrorActionPreference = $SaveEAPreference
	Write-Error "`nMissing Citrix PowerShell Snap-ins Detected, check the console above for more information. 
	`nAre you sure you are running this script against a XenDesktop 7.x Controller? 
	`n`nIf you are running the script remotely, did you install Studio or the PowerShell snapins on $env:computername?
	`n
	`nThe script requires the following snapins:
	`n
	`n
	Citrix.Broker.Admin.V2
	Citrix.ConfigurationLogging.Admin.V1
	Citrix.Host.Admin.V2
	Citrix.MachineCreation.Admin.V2
	`n
	`n`nThe script will now close.
	`n`n"
	Exit
}
#endregion

#region test AdminAddress
$AdminAddress = TestAdminAddress $AdminAddress
#endregion

#region script part 1
Write-Host
$Results = Get-BrokerHypervisorConnection -AdminAddress $AdminAddress

If(!$?)
{
	Write-Error "Unable to retrieve hosting connections. Script will now close."
	Exit
}

If($Null -eq $Results)
{
	Write-Warning "There were no hosting connections found. Script will now close."
	Exit
}

$HostingConnections = $results |% { $_.Name }

If($? -and $Null -ne $HostingConnections)
{
	Write-Host "List of hosting connections:"
	Write-Host ""
	ForEach($Connection in $HostingConnections)
	{
		Write-Host "`t$Connection"
	}
	#$HostingConnections
	Write-Host ""

	If($ResourceConnectionOnly -eq $True)
	{
		$RemoveThis = Read-Host "Which hosting connection has the resource connection you want to remove"
	}
	Else
	{
		$RemoveThis = Read-Host "Which hosting connection do you want to remove"
	}

	If($HostingConnections -Contains $RemoveThis)
	{
		If($ResourceConnectionOnly -eq $True)
		{
			Write-Host "This script will remove all active tasks and a single resource connection for $RemoveThis"
		}
		Else
		{
			Write-Host "This script will remove all active tasks and hosting connections for $RemoveThis"
		}
	}
	Else
	{
		Write-Host "Invalid hosting connection entered. Script will exit."
		Exit
	}
}
#endregion

#region script part 2
#clear errors in case of issues
$Error.Clear()

Write-Host -ForegroundColor Yellow "Retrieving Host Connection $RemoveThis"
$HostingUnits = Get-ChildItem -AdminAddress $AdminAddress -path 'xdhyp:\hostingunits' | Where-Object {$_.HypervisorConnection.HypervisorConnectionName -eq $RemoveThis} 

If(!$?)
{
	#we should never get here
	Write-Host "Unable to retrieve hosting connections. You shouldn't be here! Script will close."
	Write-Host "If you get this message, please email webster@carlwebster.com" -ForegroundColor Red
	$error
	Exit
}

If($Null -eq $HostingUnits)
{
	#we should never get here
	Write-Host "There were no hosting connections found. You shouldn't be here! Script will close."
	Write-Host "If you get this message, please email webster@carlwebster.com" -ForegroundColor Red
	$error
	Exit
}

#save the HostingUnitUid to use later
$SavedHostingUnitUid = ""
#Get-ProvTask with Active -eq True only returns one result regardless of the number of active tasks
Write-Host -ForegroundColor Yellow "Retrieving Active Provisioning Tasks"

If($HostingUnits -is[array])
{
	#multiple hosting connections found
	ForEach($HostingUnit in $HostingUnits)
	{
		$ActiveTask = $Null
		$Results = Get-ProvTask -AdminAddress $AdminAddress | Where-Object {$_.HostingUnitUid -eq $HostingUnit.HostingUnitUid -and $_.Active -eq $True} 4>$Null

		[bool]$ActionStatus = $?
		
		#only one hosting connection should have an active task since you can only select one via the Studio wizard
		If($ActionStatus -and $Null -ne $Results)
		{
			$ActiveTask += $Results
			$SavedHostingUnitUid = $HostingUnit.HostingUnitUid
		}
	}
}
Else
{
	#only one hosting connection found
	$ActiveTask = Get-ProvTask -AdminAddress $AdminAddress | Where-Object {$_.HostingUnitUid -eq $HostingUnits.HostingUnitUid -and $_.Active -eq $True} 4>$Null
	[bool]$ActionStatus = $?
	
	$SavedHostingUnitUid = $HostingUnits.HostingUnitUid
}
#endregion

#region script part 3
If($Null -eq $ActiveTask)
{
	Write-Warning "There were no active tasks found. Script will close."
	Exit
}

If(!$ActionStatus)
{
	Write-Error "Unable to retrieve active tasks. Script will close."
	Exit
}

While($ActionStatus -and $Null -ne $ActiveTask)
{
	#Get-ProvTask $True only returns one task regardless of the number of tasks that exist
	Write-Host -ForegroundColor Yellow "Active task $($ActiveTask.TaskId) found"

	###############
	#STOP THE TASK#
	###############
	
	If($PSCmdlet.ShouldProcess($ActiveTask.TaskId,'Stop Provisioning Task'))
	{
		Try
		{
			$Succeeded = $False #will indicate if the high-level operation was successful
			
			# Log high-level operation start.
			$HighLevelOp = Start-LogHighLevelOperation -Text "Stop-ProvTask TaskId $($ActiveTask.TaskId)" `
			-Source "Remove-HostingConnection Script" `
			-OperationType AdminActivity `
			-TargetTypes "TaskId $($ActiveTask.TaskId)" `
			-AdminAddress $AdminAddress
			
			Stop-ProvTask -TaskId $ActiveTask.TaskId -LoggingId $HighLevelOp.Id -AdminAddress $AdminAddress -EA 0 4>$Null
			
			If($?)
			{
				$Succeeded = $True
				Write-Host -ForegroundColor Yellow "Stopped task $($ActiveTask.TaskId)"
			}
		}
		
		Catch
		{
			Write-Warning "Unable to stop task $($ActiveTask.TaskId)"
		}
		
		Finally
		{
			# Log high-level operation stop, and indicate its success
			Stop-LogHighLevelOperation -HighLevelOperationId $HighLevelOp.Id -IsSuccessful $Succeeded -AdminAddress $AdminAddress
		}
	}
	
	#################
	#REMOVE THE TASK#
	#################

	If($PSCmdlet.ShouldProcess($ActiveTask.TaskId,'Remove Provisioning Task'))
	{
		Try
		{
			$Succeeded = $False #will indicate if the high-level operation was successful

			# Log high-level operation start.
			$HighLevelOp = Start-LogHighLevelOperation -Text "Remove-ProvTask TaskId $($ActiveTask.TaskId)" `
			-Source "Remove-HostingConnection Script" `
			-OperationType AdminActivity `
			-TargetTypes "TaskId $($ActiveTask.TaskId)" `
			-AdminAddress $AdminAddress
			
			Remove-ProvTask -TaskId $ActiveTask.TaskId -LoggingId $HighLevelOp.Id -AdminAddress $AdminAddress -EA 0 4>$Null

			If($?)
			{
				$Succeeded = $True
				Write-Host -ForegroundColor Yellow "Removed task $($ActiveTask.TaskId)"
			}
		}
		
		Catch
		{
			Write-Warning "Unable to remove task $($ActiveTask.TaskId)"
		}
		
		Finally
		{
			# Log high-level operation stop, and indicate its success
			Stop-LogHighLevelOperation -HighLevelOperationId $HighLevelOp.Id -IsSuccessful $Succeeded -AdminAddress $AdminAddress
		}
	}
	
	#keep looping until all active tasks are found, stopped and removed
	$ActiveTask = Get-ProvTask -AdminAddress $AdminAddress | Where-Object {$_.hostingunit -eq $RemoveThis.HostingUnitUid -and $_.Active -eq $True}
	[bool]$ActionStatus = $?
}

#all tasks have been stopped and removed so now the hosting and resource connections can be removed

#get all resource connections as there can be more than one per hosting connection
$ResourceConnections = $HostingUnits

If($? -and $Null -ne $ResourceConnections)
{
	ForEach($ResourceConnection in $ResourceConnections)
	{
		If(($ResourceConnectionOnly -eq $False) -or ($ResourceConnectionOnly -eq $True -and $ResourceConnection.HostingUnitUid -eq $SavedHostingUnitUid))
		{
			################################
			#REMOVE THE RESOURCE CONNECTION#
			################################
			
			
			If($PSCmdlet.ShouldProcess("xdhyp:\HostingUnits\$ResourceConnection",'Remove resource connection'))
			{
				Try
				{
					$Succeeded = $False #will indicate if the high-level operation was successful

					# Log high-level operation start.
					$HighLevelOp = Start-LogHighLevelOperation -Text "Remove-Item xdhyp:\HostingUnits\$ResourceConnection" `
					-Source "Remove-HostingConnection Script" `
					-OperationType ConfigurationChange `
					-TargetTypes "xdhyp:\HostingUnits\$ResourceConnection" `
					-AdminAddress $AdminAddress
					
					Remove-Item -AdminAddress $AdminAddress -path "xdhyp:\HostingUnits\$ResourceConnection" -LoggingId $HighLevelOp.Id -EA 0		
					
					If($?)
					{
						$Succeeded = $True
						Write-Host -ForegroundColor Yellow "Removed resource connection item xdhyp:\HostingUnits\$ResourceConnection"
					}
				}
				
				Catch
				{
					Write-Warning "Unable to remove resource connection item xdhyp:\HostingUnits\$ResourceConnection"
				}
				
				Finally
				{
					# Log high-level operation stop, and indicate its success
					Stop-LogHighLevelOperation -HighLevelOperationId $HighLevelOp.Id -IsSuccessful $Succeeded -AdminAddress $AdminAddress
				}
			}
		}
	}
}
ElseIf($? -and $Null -eq $ResourceConnections)
{
	Write-Host "There were no Resource Connections found"
}
Else
{
	Write-Host "Unable to retrieve Resource Connections"
}

#If $ResourceConnectionOnly is $True then do NOT delete the hosting connection or broker hypervisor connection
If($ResourceConnectionOnly -eq $False)
{
	###############################
	#REMOVE THE HOSTING CONNECTION#
	###############################

	
	If($PSCmdlet.ShouldProcess("xdhyp:\Connections\$RemoveThis",'Remove hosting connection'))
	{
		Try
		{
			$Succeeded = $False #will indicate if the high-level operation was successful

			# Log high-level operation start.
			$HighLevelOp = Start-LogHighLevelOperation -Text "Remove-Item xdhyp:\Connections\$RemoveThis" `
			-Source "Remove-HostingConnection Script" `
			-OperationType ConfigurationChange `
			-TargetTypes "xdhyp:\Connections\$RemoveThis" `
			-AdminAddress $AdminAddress
			
			Remove-Item -AdminAddress $AdminAddress -path "xdhyp:\Connections\$RemoveThis" -LoggingId $HighLevelOp.Id -EA 0		
			
			If($?)
			{
				$Succeeded = $True
				Write-Host -ForegroundColor Yellow "Removed hosting connection item xdhyp:\Connections\$RemoveThis"
			}
		}
		
		Catch
		{
			Write-Warning "Unable to remove hosting connection item xdhyp:\Connections\$RemoveThis"
		}
		
		Finally
		{
			# Log high-level operation stop, and indicate its success
			Stop-LogHighLevelOperation -HighLevelOperationId $HighLevelOp.Id -IsSuccessful $Succeeded -AdminAddress $AdminAddress
		}
	}
	
	#########################################
	#REMOVE THE BROKER HYPERVISOR CONNECTION#
	#########################################

	
	If($PSCmdlet.ShouldProcess($RemoveThis,'Remove broker hypervisor connection'))
	{
		Try
		{
			$Succeeded = $False #will indicate if the high-level operation was successful

			# Log high-level operation start.
			$HighLevelOp = Start-LogHighLevelOperation -Text "Remove-BrokerHypervisorConnection $RemoveThis" `
			-Source "Remove-HostingConnection Script" `
			-OperationType ConfigurationChange `
			-TargetTypes "$RemoveThis" `
			-AdminAddress $AdminAddress
			Remove-BrokerHypervisorConnection -Name $RemoveThis -AdminAddress $AdminAddress -LoggingId $HighLevelOp.Id -EA 0	
		
			If($?)
			{
				$Succeeded = $True
				Write-Host -ForegroundColor Yellow "Removed Broker Hypervisor Connection $RemoveThis"
			}
		}
		
		Catch
		{
			Write-Warning "Unable to remove Broker Hypervisor Connection $RemoveThis"
		}
		
		Finally
		{
			# Log high-level operation stop, and indicate its success
			Stop-LogHighLevelOperation -HighLevelOperationId $HighLevelOp.Id -IsSuccessful $Succeeded -AdminAddress $AdminAddress
		}
	}
}
##################
#SCRIPT COMPLETED#
##################

Write-Host "Script completed"
#endregion
