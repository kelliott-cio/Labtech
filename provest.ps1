$url = "https://cwa.connectwise.com/tools/sentinelone/SentinelOneAgent-Windows.exe"
$outpath = "$PSScriptRoot/SentinelOneAgent-Windows.exe"
Invoke-WebRequest -Uri $url -OutFile $outpath
$args = @("/q","/SITE_TOKEN=eyJ1cmwiOiAiaHR0cHM6Ly91c2VhMS1wYXg4LnNlbnRpbmVsb25lLm5ldCIsICJzaXRlX2tleSI6ICI0YTU0ODdkYmY3ZjVkYmMxIn0=")
Start-Process -Filepath "$PSScriptRoot/SentinelOneAgent-Windows.exe" -ArgumentList $args