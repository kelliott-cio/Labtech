$range = "%LocalAddress%"

$octs = $range.split(".")
$octsRange = "$($octs[0]).$($octs[1]).$($octs[2])"
$subn = 1..254

add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(

            ServicePoint srvPoint, X509Certificate certificate,

            WebRequest request, int certificateProblem) {
            return true;
    }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
try {
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'SSL3,Tls'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'SSL3,Tls,Tls11'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'SSL3,Tls,Tls11,Tls12'
}
catch {
 $tls12 = $false
}
$soapBody = '<soap:Envelope xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Header><operationID>00000001-00000001</operationID></soap:Header><soap:Body><RetrieveServiceContent xmlns="urn:internalvim25"><_this xsi:type="ManagedObjectReference" type="ServiceInstance">ServiceInstance</_this></RetrieveServiceContent></soap:Body></soap:Envelope>'
$tempFile = [System.IO.Path]::Combine($env:Windir, "ltsvc\temp-out.csv")
$outFile = [System.IO.Path]::Combine($env:Windir, "ltsvc\esx-out.csv")


function Test-TCPPort {
    param([string]$testHost, [int]$Port)

    if ((Get-WmiObject "Win32_PingStatus" -Filter "Timeout = 10 and Address='$testHost'").ResponseTime -eq $null){
        return $false
    }

    $Socket = New-Object Net.Sockets.TcpClient
    try {
        $Socket.Connect($testHost, $Port)
    }
    catch {
        $success = $false
    }
    if ($Socket.Connected) {
        $success = $true
        if ($psversiontable.CLRVersion.Major -lt 3) {
        $Socket.GetStream().Close(); }
        $Socket.Close()
    }
    else {
        $success = $false
    }
    if ($psversiontable.CLRVersion.Major -gt 2) {
    $Socket.Dispose() | Out-Null }
    $Socket = $null
    return $success
}

function Get-ESXInfo {
    param([string]$hostname)
    $webClient = New-Object System.Net.WebClient
    try {
        $soapResponse = $webClient.UploadString("https://$hostname/sdk", $soapBody)
    }
    catch {
        return $false
    }

    if ($soapResponse.Length -eq 0) {
        return $false
    }

    try {
        $xmlResponse = [xml]$soapResponse
    }
    catch {
        return $false
    }

    $hash = @{}
    $hash.version = $xmlResponse.Envelope.Body.RetrieveServiceContentResponse.returnval.about.Version
    $hash.fullname = $xmlResponse.Envelope.Body.RetrieveServiceContentResponse.returnval.about.fullName
    $hash.hostname = $hostname
    return $hash

    # $hashObj = New-Object -TypeName PSObject -Property $hash
    # return $hashObj
}

$resultArray = New-Object System.Collections.ArrayList

Write-Verbose "Starting scan for $octsRange"

foreach ($ip in $subn) {
    $ipAddress = "$octsRange.$ip"
    Write-Verbose "Scanning $ipAddress"
    if (-Not (Test-TCPPort $ipAddress 443)) {
        Write-Verbose "Skipping $ipAddress. Not listening on port 443."
        continue
    }
    $esxInfo = Get-ESXInfo $ipAddress
    if (-Not $esxInfo) {
        continue
    }
    Write-Verbose "Found host $ipAddress"
    $hashObj = New-Object -TypeName PSObject -Property $esxInfo
    $resultArray.Add($hashObj) | Out-Null
}
$finalOutput = $resultArray | select-object fullname,version,hostname 
$finalOutput = $finalOutput | where-object {$_.fullname -notmatch 'fullname'}
$finalOutput = $finalOutput | where-object {$_.fullname -notmatch 'vCenter'}
$finalOutput = $finalOutput | where-object {$_.fullname -notmatch 'Workstation'}
$finalOutput = $finalOutput | where-object {$_.fullname -ne ''}
if ($finalOutput -ne $null) {
$finalOutput | convertto-csv -NoTypeInformation | foreach-object {$_ -replace'","','|'} | foreach-object {$_ -replace '"','|'} 
}
else {
write-output ''
}