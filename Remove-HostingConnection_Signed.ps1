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

# SIG # Begin signature block
# MIIf8QYJKoZIhvcNAQcCoIIf4jCCH94CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUTeD0lJyyP1odNfmOF1NQZ+UP
# UeKgghtYMIIDtzCCAp+gAwIBAgIQDOfg5RfYRv6P5WD8G/AwOTANBgkqhkiG9w0B
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
# 8jCCBSYwggQOoAMCAQICEAZrq+ZgEvYk2tXPfU766DQwDQYJKoZIhvcNAQELBQAw
# cjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQ
# d3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVk
# IElEIENvZGUgU2lnbmluZyBDQTAeFw0xNzEwMDEwMDAwMDBaFw0xODEwMDMxMjAw
# MDBaMGMxCzAJBgNVBAYTAlVTMRIwEAYDVQQIEwlUZW5uZXNzZWUxEjAQBgNVBAcT
# CVR1bGxhaG9tYTEVMBMGA1UEChMMQ2FybCBXZWJzdGVyMRUwEwYDVQQDEwxDYXJs
# IFdlYnN0ZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDDhpiUpOGG
# NUoWqxiyNJRiYfsWpRtlAX3ZudYlkDB8KW6SgKZRpgLqEjGamaDczD5Uvv/qDYPD
# T0MUdzlqfP/TaC4abvFdhqTEcqv705s6bCaP1N09efJwuhix4AE7nULC4qhVRUx+
# uORJiuzUsQkk/+P5esEG3ipaW/AKWPb+f7UOb/Tv+G9AVMSq0lfZhTJQ5oPmRxly
# FPPK+FuP6EZiQKfnh7PpTm9SOYnO5v9JqqQHtDdR0nJ3qEUeKnpQOGDiATR3onv2
# OR2HWHFeHA7zXPF3gZEPAdyexcl0hxJX838+M1w/jPUKQXit7q8RQHOg26o6OF3v
# nZG7rLRKNc9NAgMBAAGjggHFMIIBwTAfBgNVHSMEGDAWgBRaxLl7KgqjpepxA8Bg
# +S32ZXUOWDAdBgNVHQ4EFgQUuxAsZml/p3qsZGfrBATAf5qBRZIwDgYDVR0PAQH/
# BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHcGA1UdHwRwMG4wNaAzoDGGL2h0
# dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9zaGEyLWFzc3VyZWQtY3MtZzEuY3JsMDWg
# M6Axhi9odHRwOi8vY3JsNC5kaWdpY2VydC5jb20vc2hhMi1hc3N1cmVkLWNzLWcx
# LmNybDBMBgNVHSAERTBDMDcGCWCGSAGG/WwDATAqMCgGCCsGAQUFBwIBFhxodHRw
# czovL3d3dy5kaWdpY2VydC5jb20vQ1BTMAgGBmeBDAEEATCBhAYIKwYBBQUHAQEE
# eDB2MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wTgYIKwYB
# BQUHMAKGQmh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFNIQTJB
# c3N1cmVkSURDb2RlU2lnbmluZ0NBLmNydDAMBgNVHRMBAf8EAjAAMA0GCSqGSIb3
# DQEBCwUAA4IBAQAkPvBfW65xxwdqIaiTg/Vp0WzfvQODfKSFP+gDYQDt4llY0o/h
# hPgSzq2cJEPeG6jm91Vhk4ugFg+s8WjpppDnwqfCTPRZbfQD+eeu+4305j2r9mlD
# cSk6fSqI1+FNgOAFyDXT85zNouO2pC3QGYk1E5h/n7DwN28W7W0XVa/Wf8BOPNxG
# uQDDXECjTgsJOTMBFToIP5StpmmrnEgU5MUqfnnFTSB+6ElgzbEOWW/tvmuBqDOo
# rztFNRwtKjMMwSdnzKEXpMksr1R2x+A6BUC4zzP2zEtt9WTyo0D0zblE1eBzsRbg
# oU1gRBOIgQBml4fl3RElJ8BsS2AOnsAP8uRIMIIFMDCCBBigAwIBAgIQBAkYG1/V
# u2Z1U0O1b5VQCDANBgkqhkiG9w0BAQsFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UE
# ChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYD
# VQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcNMTMxMDIyMTIwMDAw
# WhcNMjgxMDIyMTIwMDAwWjByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNl
# cnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdp
# Q2VydCBTSEEyIEFzc3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEA+NOzHH8OEa9ndwfTCzFJGc/Q+0WZsTrbRPV/
# 5aid2zLXcep2nQUut4/6kkPApfmJ1DcZ17aq8JyGpdglrA55KDp+6dFn08b7KSfH
# 03sjlOSRI5aQd4L5oYQjZhJUM1B0sSgmuyRpwsJS8hRniolF1C2ho+mILCCVrhxK
# hwjfDPXiTWAYvqrEsq5wMWYzcT6scKKrzn/pfMuSoeU7MRzP6vIK5Fe7SrXpdOYr
# /mzLfnQ5Ng2Q7+S1TqSp6moKq4TzrGdOtcT3jNEgJSPrCGQ+UpbB8g8S9MWOD8Gi
# 6CxR93O8vYWxYoNzQYIH5DiLanMg0A9kczyen6Yzqf0Z3yWT0QIDAQABo4IBzTCC
# AckwEgYDVR0TAQH/BAgwBgEB/wIBADAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAww
# CgYIKwYBBQUHAwMweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8v
# b2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRp
# Z2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwgYEGA1UdHwR6
# MHgwOqA4oDaGNGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3Vy
# ZWRJRFJvb3RDQS5jcmwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9E
# aWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwTwYDVR0gBEgwRjA4BgpghkgBhv1s
# AAIEMCowKAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMw
# CgYIYIZIAYb9bAMwHQYDVR0OBBYEFFrEuXsqCqOl6nEDwGD5LfZldQ5YMB8GA1Ud
# IwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA0GCSqGSIb3DQEBCwUAA4IBAQA+
# 7A1aJLPzItEVyCx8JSl2qB1dHC06GsTvMGHXfgtg/cM9D8Svi/3vKt8gVTew4fbR
# knUPUbRupY5a4l4kgU4QpO4/cY5jDhNLrddfRHnzNhQGivecRk5c/5CxGwcOkRX7
# uq+1UcKNJK4kxscnKqEpKBo6cSgCPC6Ro8AlEeKcFEehemhor5unXCBc2XGxDI+7
# qPjFEmifz0DLQESlE/DmZAwlCEIysjaKJAL+L3J+HNdJRZboWR3p+nRka7LrZkPa
# s7CM1ekN3fYBIM6ZMWM9CBoYs4GbT8aTEAb8B4H6i9r5gkn3Ym6hU/oSlBiFLpKR
# 6mhsRDKyZqHnGKSaZFHvMIIGajCCBVKgAwIBAgIQAwGaAjr/WLFr1tXq5hfwZjAN
# BgkqhkiG9w0BAQUFADBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQg
# SW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2Vy
# dCBBc3N1cmVkIElEIENBLTEwHhcNMTQxMDIyMDAwMDAwWhcNMjQxMDIyMDAwMDAw
# WjBHMQswCQYDVQQGEwJVUzERMA8GA1UEChMIRGlnaUNlcnQxJTAjBgNVBAMTHERp
# Z2lDZXJ0IFRpbWVzdGFtcCBSZXNwb25kZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IB
# DwAwggEKAoIBAQCjZF38fLPggjXg4PbGKuZJdTvMbuBTqZ8fZFnmfGt/a4ydVfiS
# 457VWmNbAklQ2YPOb2bu3cuF6V+l+dSHdIhEOxnJ5fWRn8YUOawk6qhLLJGJzF4o
# 9GS2ULf1ErNzlgpno75hn67z/RJ4dQ6mWxT9RSOOhkRVfRiGBYxVh3lIRvfKDo2n
# 3k5f4qi2LVkCYYhhchhoubh87ubnNC8xd4EwH7s2AY3vJ+P3mvBMMWSN4+v6GYeo
# fs/sjAw2W3rBerh4x8kGLkYQyI3oBGDbvHN0+k7Y/qpA8bLOcEaD6dpAoVk62RUJ
# V5lWMJPzyWHM0AjMa+xiQpGsAsDvpPCJEY93AgMBAAGjggM1MIIDMTAOBgNVHQ8B
# Af8EBAMCB4AwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDCC
# Ab8GA1UdIASCAbYwggGyMIIBoQYJYIZIAYb9bAcBMIIBkjAoBggrBgEFBQcCARYc
# aHR0cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzCCAWQGCCsGAQUFBwICMIIBVh6C
# AVIAQQBuAHkAIAB1AHMAZQAgAG8AZgAgAHQAaABpAHMAIABDAGUAcgB0AGkAZgBp
# AGMAYQB0AGUAIABjAG8AbgBzAHQAaQB0AHUAdABlAHMAIABhAGMAYwBlAHAAdABh
# AG4AYwBlACAAbwBmACAAdABoAGUAIABEAGkAZwBpAEMAZQByAHQAIABDAFAALwBD
# AFAAUwAgAGEAbgBkACAAdABoAGUAIABSAGUAbAB5AGkAbgBnACAAUABhAHIAdAB5
# ACAAQQBnAHIAZQBlAG0AZQBuAHQAIAB3AGgAaQBjAGgAIABsAGkAbQBpAHQAIABs
# AGkAYQBiAGkAbABpAHQAeQAgAGEAbgBkACAAYQByAGUAIABpAG4AYwBvAHIAcABv
# AHIAYQB0AGUAZAAgAGgAZQByAGUAaQBuACAAYgB5ACAAcgBlAGYAZQByAGUAbgBj
# AGUALjALBglghkgBhv1sAxUwHwYDVR0jBBgwFoAUFQASKxOYspkH7R7for5XDStn
# As0wHQYDVR0OBBYEFGFaTSS2STKdSip5GoNL9B6Jwcp9MH0GA1UdHwR2MHQwOKA2
# oDSGMmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRENB
# LTEuY3JsMDigNqA0hjJodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRB
# c3N1cmVkSURDQS0xLmNybDB3BggrBgEFBQcBAQRrMGkwJAYIKwYBBQUHMAGGGGh0
# dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBBBggrBgEFBQcwAoY1aHR0cDovL2NhY2Vy
# dHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEQ0EtMS5jcnQwDQYJKoZI
# hvcNAQEFBQADggEBAJ0lfhszTbImgVybhs4jIA+Ah+WI//+x1GosMe06FxlxF82p
# G7xaFjkAneNshORaQPveBgGMN/qbsZ0kfv4gpFetW7easGAm6mlXIV00Lx9xsIOU
# GQVrNZAQoHuXx/Y/5+IRQaa9YtnwJz04HShvOlIJ8OxwYtNiS7Dgc6aSwNOOMdgv
# 420XEwbu5AO2FKvzj0OncZ0h3RTKFV2SQdr5D4HRmXQNJsQOfxu19aDxxncGKBXp
# 2JPlVRbwuwqrHNtcSCdmyKOLChzlldquxC5ZoGHd2vNtomHpigtt7BIYvfdVVEAD
# kitrwlHCCkivsNRu4PQUCjob4489yq9qjXvc2EQwggbNMIIFtaADAgECAhAG/fkD
# lgOt6gAK6z8nu7obMA0GCSqGSIb3DQEBBQUAMGUxCzAJBgNVBAYTAlVTMRUwEwYD
# VQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAi
# BgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0wNjExMTAwMDAw
# MDBaFw0yMTExMTAwMDAwMDBaMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdp
# Q2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERp
# Z2lDZXJ0IEFzc3VyZWQgSUQgQ0EtMTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
# AQoCggEBAOiCLZn5ysJClaWAc0Bw0p5WVFypxNJBBo/JM/xNRZFcgZ/tLJz4Flnf
# nrUkFcKYubR3SdyJxArar8tea+2tsHEx6886QAxGTZPsi3o2CAOrDDT+GEmC/sfH
# MUiAfB6iD5IOUMnGh+s2P9gww/+m9/uizW9zI/6sVgWQ8DIhFonGcIj5BZd9o8dD
# 3QLoOz3tsUGj7T++25VIxO4es/K8DCuZ0MZdEkKB4YNugnM/JksUkK5ZZgrEjb7S
# zgaurYRvSISbT0C58Uzyr5j79s5AXVz2qPEvr+yJIvJrGGWxwXOt1/HYzx4KdFxC
# uGh+t9V3CidWfA9ipD8yFGCV/QcEogkCAwEAAaOCA3owggN2MA4GA1UdDwEB/wQE
# AwIBhjA7BgNVHSUENDAyBggrBgEFBQcDAQYIKwYBBQUHAwIGCCsGAQUFBwMDBggr
# BgEFBQcDBAYIKwYBBQUHAwgwggHSBgNVHSAEggHJMIIBxTCCAbQGCmCGSAGG/WwA
# AQQwggGkMDoGCCsGAQUFBwIBFi5odHRwOi8vd3d3LmRpZ2ljZXJ0LmNvbS9zc2wt
# Y3BzLXJlcG9zaXRvcnkuaHRtMIIBZAYIKwYBBQUHAgIwggFWHoIBUgBBAG4AeQAg
# AHUAcwBlACAAbwBmACAAdABoAGkAcwAgAEMAZQByAHQAaQBmAGkAYwBhAHQAZQAg
# AGMAbwBuAHMAdABpAHQAdQB0AGUAcwAgAGEAYwBjAGUAcAB0AGEAbgBjAGUAIABv
# AGYAIAB0AGgAZQAgAEQAaQBnAGkAQwBlAHIAdAAgAEMAUAAvAEMAUABTACAAYQBu
# AGQAIAB0AGgAZQAgAFIAZQBsAHkAaQBuAGcAIABQAGEAcgB0AHkAIABBAGcAcgBl
# AGUAbQBlAG4AdAAgAHcAaABpAGMAaAAgAGwAaQBtAGkAdAAgAGwAaQBhAGIAaQBs
# AGkAdAB5ACAAYQBuAGQAIABhAHIAZQAgAGkAbgBjAG8AcgBwAG8AcgBhAHQAZQBk
# ACAAaABlAHIAZQBpAG4AIABiAHkAIAByAGUAZgBlAHIAZQBuAGMAZQAuMAsGCWCG
# SAGG/WwDFTASBgNVHRMBAf8ECDAGAQH/AgEAMHkGCCsGAQUFBwEBBG0wazAkBggr
# BgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdo
# dHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290
# Q0EuY3J0MIGBBgNVHR8EejB4MDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3Js
# NC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMB0GA1Ud
# DgQWBBQVABIrE5iymQftHt+ivlcNK2cCzTAfBgNVHSMEGDAWgBRF66Kv9JLLgjEt
# UYunpyGd823IDzANBgkqhkiG9w0BAQUFAAOCAQEARlA+ybcoJKc4HbZbKa9Sz1Lp
# MUerVlx71Q0LQbPv7HUfdDjyslxhopyVw1Dkgrkj0bo6hnKtOHisdV0XFzRyR4WU
# VtHruzaEd8wkpfMEGVWp5+Pnq2LN+4stkMLA0rWUvV5PsQXSDj0aqRRbpoYxYqio
# M+SbOafE9c4deHaUJXPkKqvPnHZL7V/CSxbkS3BMAIke/MV5vEwSV/5f4R68Al2o
# /vsHOE8Nxl2RuQ9nRc3Wg+3nkg2NsWmMT/tZ4CMP0qquAHzunEIOz5HXJ7cW7g/D
# vXwKoO4sCFWFIrjrGBpN/CohrUkxg0eVd3HcsRtLSxwQnHcUwZ1PL1qVCCkQJjGC
# BAMwggP/AgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJ
# bmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERpZ2lDZXJ0
# IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0ECEAZrq+ZgEvYk2tXPfU76
# 6DQwCQYFKw4DAhoFAKBAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMCMGCSqG
# SIb3DQEJBDEWBBSdaLNdRRuyU4NgAN3aZVkyQJl3qDANBgkqhkiG9w0BAQEFAASC
# AQBfZYuD2vTHUluxkP9sMnGWHrLowFr9xTXlI/1uNfDVjoHmEJn3z2Jnf+rwTdDQ
# vPsY7qPfOtH/gkE56c7UD9iyeWByB1sFG7PywQueDQb6O26/1BoO9ovBL62Q3UH2
# LKK2cn+nRkAUK9mQyHGAX/TQjY1xwxXxoNCOlhlzSirS2Y7XyH2l35ViiTZzXPHL
# 7nRnGqjydmJJ2d3vZhXYukvRvxLRLrQoz2HJypgB3X8+nsk3xUp0rcbjfqnhzE10
# fEO3kNeH7pigUtbrxo9yqEwGHNF6cVz5DZ3It2kmq7LtqYUGeckr+ueuORhT50Af
# fKvXdA909xeVFrjFU0/Q6mBEoYICDzCCAgsGCSqGSIb3DQEJBjGCAfwwggH4AgEB
# MHYwYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UE
# CxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgQXNzdXJlZCBJ
# RCBDQS0xAhADAZoCOv9YsWvW1ermF/BmMAkGBSsOAwIaBQCgXTAYBgkqhkiG9w0B
# CQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0xNzExMDYxOTM0MTlaMCMG
# CSqGSIb3DQEJBDEWBBQy5ZS7Koe5YBlA33tZidukaQCT5DANBgkqhkiG9w0BAQEF
# AASCAQAE0gdxNC1SbCZl2veVqNkKzqRjtE4+AJ2q7/6Rq7FGUta796C4uq0q31Vj
# +w84DYrm7FDHJqMKfnYsoNVZFNFaVDG3jL4abYFInp1WKmZ3SHU6LFH7NdwHhfXV
# buRo0homn54Ofwdu1VdPn3aQZU6J7KV++EeucO2e0XBopHwM3hN5FzQa5ktF5uen
# 43apdYRqKrb3ddLoG4YjW9zG6iEUjBo4zoUZUK8J3SfVNOYceMd9g/tyXMzsSGiU
# R1A/gentYATaMqSMJZelZFwxBa+yBtgwdk47rw4rTEmxbf/zwo9xc/0/ek1+IOrb
# I9iUwe3YWCGeXhRhJ2UpKZcIMa5k
# SIG # End signature block
