<#  ==============================================================================================================================================
Brad Biehl - Premier Field Engineering (Microsoft)
Last Update: 06/13/2015
Blog: 
    http://infrastructureanonymous.com/
Additional Information: 
    http://infrastructureanonymous.com/2015/05/29/directory-service-restore-mode-password-and-automation/
    http://infrastructureanonymous.com/2015/05/19/distributed-automation-using-native-tools-and-scripts/

sync-dsrm-task_v##.ps1: Sets the DSRM account password on a Domain Controller by synchronizing from an Active Directory User.

    Usage: 
    ======
    .\sync-dsrm-task_v##.ps1 [-account <account>] [-verboseOutput] [-logToFile]

    Parameters:
    ===========
    -account: This parameter is used to identify the AD account to use as the source for the password sync.
    -forceCreate: If the folder specified in the path argument does not exist, it will be created if possible.
    -verboseOutput: Enables Verbose logging with will log additional output from PS prompt. Default setting as 0 and is normally used when troubleshooting.
    -logToFile: Logs will be written to a text log file. IMPORTANT: Be careful of enabling this argument as no controls are in place to prevent runaway growth of the file. This is intended for troubleshooting purposes.
    
    How to use:
    ===========
    - Domain Admin or Administrators group membership, unless run as a Scheduled Task in Local System context on a DC (preferred).
    - Must be run locally on the Domain Controller.


    Requirements:
    =============  
    - Administrative rights
    - PowerShell 2.0
    
    Release Notes: 
    ==============
    - Separated logToFile and verboseOutput arguments
    - Added EventSourceReady check
    - Various cosmetic fixes  
    - Updated to [switch] parameters
    - Improvements to error handling
    - Additional prerequisite checks added
    - Removed log's filename from Parameters
    - IMPORTANT: Changed logFile argument to logPath.


Disclaimer:
===========
This sample script is not supported under any Microsoft standard support program or service. 
The sample script is provided AS IS without warranty of any kind. Microsoft further disclaims 
all implied warranties including, without limitation, any implied warranties of merchantability 
or of fitness for a particular purpose. The entire risk arising out of the use or performance of 
the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, 
or anyone else involved in the creation, production, or delivery of the scripts be liable for any 
damages whatsoever (including, without limitation, damages for loss of business profits, business 
interruption, loss of business information, or other pecuniary loss) arising out of the use of or 
inability to use the sample scripts or documentation, even if Microsoft has been advised of the 
possibility of such damages


 ========================================================================================================================================================
#>
param (
[Parameter(Mandatory=$false)][string] $account="svc_dsrm",
[Parameter(Mandatory=$false)][string] $logPath="$env:SYSTEMROOT\debug",
[Parameter(Mandatory=$false)][switch] $forceCreate,
[Parameter(Mandatory=$false)][switch] $logToFile,
[Parameter(Mandatory=$false)][switch] $verboseOutput
)

#########################BEGIN FUNCTIONS#########################

Function Verify-Elevation(){
    If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
    {
        Write-VerboseLogs "[ERROR]|You do not have sufficient Administrative rights to run this script!`nPlease re-run this script as an Administrator!"
        $false
    }
    else{
        Write-VerboseLogs "[INFO]|Administrative rights verified."
        $true
    }
} 

Function Verify-PSVersion(){
    If (-NOT ($PSMajorVersion -ge 2)){
        Write-VerboseLogs "[ERROR]|PowerShell must be Version 2.0 or above to run this script!`nUpdate PowerShell to continue."
        $false
    }
    else{
        Write-VerboseLogs "[INFO]|PowerShell version was detected as $PSMajorVersion"
        $true    
    }
} 

Function Configure-EventLogs(){
    if (-not([System.Diagnostics.EventLog]::SourceExists($EventSource)) -or -not([System.Diagnostics.EventLog]::Exists($EventLog)))
    {
        try{
            Write-VerboseLogs "[INFO]|Event log source is missing. `n Attempting to create source $EventSource for log $EventLog."
            New-EventLog -LogName $EventLog -Source $EventSource
            $script:EventSourceReady=$true
        }
        catch{Write-VerboseLogs "[WARNING]|Failed to create Event Source $EventSource for Event Log $EventLog. `n Exiting script"}
    }
    else{
        Write-VerboseLogs "[INFO]|Event log source and log already exist."
        $script:EventSourceReady=$true
    }
}

Function Fix-Path($path){
    if(-not $path.EndsWith("\")){"$path\"}
    else{$path}
}

Function Verify-DestinationPath(){
    if($logToFile){     
        if (-not(test-path $logPath)){    
            if($forceCreate){
                try{
                    New-Item $logPath -ItemType directory -ErrorAction Stop
                    $script:logReady=$true                
                    Write-VerboseLogs "[INFO]|Path did not exist, but was successfully created: $logPath"
                    $true
                }
                catch{
                    $ErrorMessage=$_.Exception.Message
                    Write-VerboseLogs "[ERROR]|Operation failed. `n`nFailed to create $logPath with Force argument set. `nError message was: `n$ErrorMessage"
                    $false
                }
            }
            else{
                Write-VerboseLogs "[ERROR]|Path must exist for script to continue or Force argument set to $true. `n`nVerification failed for path: $logPath"
                $false
            }
        }
        else{
            $script:logReady=$true 
            Write-VerboseLogs "[INFO]|Verification of log path successful: $logPath"
            $true
        }  
    }
    else{
        Write-VerboseLogs "[INFO]|Skipped write check for log path as LogToFile is disabled."
        $true
    } 
}

#Write Event logs
Function Write-VerboseLogs ($argText){
    $currentTimeStamp=(Get-Date).ToString()
    $messageType=$argText.Split("|")[0]
    $messageText=$argText.Split("|")[1]   
    $outputText="$currentTimeStamp $messageType $messageText"

    switch ($messageType)
    {
        "[ERROR]" {
            Write-Host $outputText -ForegroundColor Red
            if($EventSourceReady){Write-eventlog -logname $EventLog -Source $EventSource -Message $messageText -EventId 7813 -EntryType Error}
            if($logToFile -and $logReady){Write-Output $outputText | Out-File $script:logFile -Append}}
        "[WARNING]" {
            Write-Host $outputText -ForegroundColor Yellow
            if($EventSourceReady){Write-eventlog -logname $EventLog -Source $EventSource -Message $messageText -EventId 6813 -EntryType Warning}
            if($logToFile -and $logReady){Write-Output $outputText | Out-File $script:logFile -Append}}
        "[SUMMARY]" {
            Write-Host $outputText -ForegroundColor Green
            if($EventSourceReady){Write-eventlog -logname $EventLog -Source $EventSource -Message $messageText -EventId 4813 -EntryType Information}
            if($logToFile -and $logReady){Write-Output $outputText | Out-File $script:logFile -Append}}
        "[INFO]" {
            if($verboseOutput){Write-Host $outputText -ForegroundColor White
                if($logToFile -and $logReady){Write-Output $outputText | Out-File $script:logFile -Append}}}
        Default {Write-Host "Invalid output sent to write-VerboseLogs:`n $outputText" -ForegroundColor Magenta}
    }
}

Function Check-User(){
    Write-VerboseLogs "[INFO]|Verifying presence of user: $account"
    Try{
        $dsrm=Get-ADUser $account
        $true
    }
    Catch{
        $ErrorMessage=$_.Exception.Message
        Write-VerboseLogs "[ERROR]|An error was encountered when enumerating the AD user $account. The error was: `n $ErrorMessage"
        $false
    }
}

Function Perform-DsrmSync(){
    $outMessage=""
    $ErrorMessage=""
    $parms="""set dsrm password"" ""sync from domain account $account"" q q"

    Write-VerboseLogs "[INFO]|Backup parameters: $parms"
    try{
        $proc=new-object System.Diagnostics.Process
        $proc.StartInfo.Filename="ntdsutil.exe"
        $proc.StartInfo.Arguments="$parms"
        $proc.StartInfo.RedirectStandardOutput=$True
        $proc.StartInfo.UseShellExecute=$false
        $proc.start() | Out-Null
        $proc.WaitForExit()
        [string] $outMessage=$proc.StandardOutput.ReadToEnd()

        Write-VerboseLogs "[INFO]|DSRM Sync Command output was: $outMessage"

        if($outMessage -like "*Password has been synchronized successfully.*"){
            Write-VerboseLogs "[SUMMARY]|Completed DSRM Sync. `n`nSync command output: `n`n$outMessage"
    
        }
        Else{
            Write-VerboseLogs "[ERROR]|An error was encountered during DSRM Sync. `n`nDSRM Sync error output: `n`n$outMessage"
        }
    }
    catch{
        $ErrorMessage=$_.Exception.Message
        Write-VerboseLogs "[ERROR]|An error was encountered during DSRM Sync. `n`nDSRM Sync error output: `n`n$ErrorMessage"   
    }
}


#########################END FUNCTIONS#########################

#Script version should be updated with every release
$scriptVersion="1.1"
$EventSourceReady=$false
$logReady=$false 
$logPath = fix-path $logPath
$logFile=$logPath + "sync-dsrm-task_debug.log"
$PSMajorVersion=$PSVersionTable.PSVersion.Major


if((Verify-DestinationPath) -and (Verify-Elevation) -and (Verify-PSVersion)){
    #Create event log source for use in script
    $EventSource="DSRM Password Sync - DA"
    $EventLog='Distributed Automation' 
    Configure-EventLogs

    #Begin with first event log to announce starting parameters
    Write-VerboseLogs "[SUMMARY]|DSRM Password Sync operation started.`n`tScript Version:`t$scriptVersion `n`tPS Version:`t$PSMajorVersion `n`n`tSync Account:`t$account `n`tLog Path:`t$logFile `n`tVerbose Out:`t$verboseOutput `n`tLog to File:`t$logToFile `n`tForce Create:`t$forceCreate"

    #Verify specified DSRM user account is present in Active Directory
    if(Check-User){Perform-DsrmSync}
}