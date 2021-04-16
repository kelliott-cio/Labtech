$url = "https://patch.manageengine.com/link.do?actionToCall=download&encapiKey=wSsVR60krxDzCK14mWaudOlskF9TAFyiEhh02AOnvSepSKqR8Mduw0SaBAP1HKJLFTFrFTdBpbIpm0hT1DEO2dsszA4JXiiF9mqRe1U4J3x1oO%2FrxWKYXGk%3D"
$url += "&os=windows"
$outputPath = "$env:windir\temp\DCAgent.exe"
Invoke-WebRequest $url -OutFile $outputPath
Start-Process -filepath $outputPath -Wait -ArgumentList "/silent"