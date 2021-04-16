<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.128
	 Created on:   	13/11/2016 15:04
	 Created by:   	Maurice Daly	
	 Filename:     	UpdateUPN.ps1
	===========================================================================
	.DESCRIPTION
		Reads the contents of a CSV specified during the runtime command,
		then updates all users contained with their new UPN.
		within.
	.EXAMPLE
		UpdateUPN.ps1 -SourceFile "C:\Users.CSV"
		
		Source CSV must contain headings OLDUPN and NEWUPN to function

	Use : This script is provided as it and I accept no responsibility for
	any issues arising from its use.

	Twitter : @modaly_it
	Blog : https://modalyitblog.com/
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
	[parameter(Mandatory = $true, HelpMessage = "Location of CSV file containing both old and new UPNs", Position = 1)]
	[ValidateNotNullOrEmpty()]
	[ValidateScript({ Test-Path $_ })]
	[string]$SourceFile
)

# Import UPN detals
$UPNDetails = Import-Csv -Path $SourceFile

# Import Active Directory commandlets
Import-Module -Name ActiveDirectory

# Loop for each user
foreach ($User in $UPNDetails)
{
	# Get AD user details using old UPN and the update
	$UserDetails = Get-ADUser -filter * | Where-Object { $_.UserPrincipalName -eq $User.OldUPN }
	Write-Output "Changing UPN $($User.OldUPN) to $($User.NewUPN)"
	Set-ADUser -Identity $UserDetails.Name -UserPrincipalName ($UserDetails.UserPrincipalName -replace $User.OldUPN,$User.NewUPN)
}
