### Authenticate to Automate API
Connect-AutomateAPI
### Set variables
$Server = "your.automatedomain.com"
$LocationId = '1'
$InstallerType = '1' # 1 MSI, 2 EXE, 3 Linux (x86), 4 Linux (x86_64), 5 MacOS
### Build API Request
$AutomateAPIURI = ('https://' + $Server + '/cwa/api/v1')
$Body = @{}
$Body.Add("LocationId", $LocationId)
$Body.Add("InstallerType", $InstallerType)
$RESTRequest = @{
    'URI' = ($AutomateAPIURI + '/RemoteAgent/Installers')
    'Headers' = $script:CWAToken
    'Method' = 'POST'
    'ContentType' = 'application/json'
    'Body' = $Body | ConvertTo-Json -Compress
}
### Invoke API Request
$CWAInstallerToken = Invoke-RestMethod @RESTRequest
$CWAInstallURL = ('https://' + $Server + '/Labtech/Deployment.aspx?InstallerToken=' + $CWAInstallerToken)
Write-Output $CWAInstallURL