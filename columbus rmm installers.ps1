#################
###South Carolina
#################

$LTservice = Get-Service -Name ltservice -ErrorAction SilentlyContinue
$SCservice = Get-Service -Name "ScreenConnect Client (60a06214111b8797)" -ErrorAction SilentlyContinue
$locationid = 498
$token = 'dd7a866d62718de032b421ee65f6c628'

if($LTservice -eq $null)
{
    Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
} else {
    # Service already exists
    if($SCservice -eq $null)
    {
        Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Uninstall-Automate; Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
    }
    else{
        # Service fully deployed
    }
}



#############
###New Jersey
#############

$LTservice = Get-Service -Name ltservice -ErrorAction SilentlyContinue
$SCservice = Get-Service -Name "ScreenConnect Client (60a06214111b8797)" -ErrorAction SilentlyContinue
$locationid = 503
$token = '5dd5ff58dadcea50727064d3d4e9b3f2'

if($LTservice -eq $null)
{
    Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
} else {
    # Service already exists
    if($SCservice -eq $null)
    {
        Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Uninstall-Automate; Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
    }
    else{
        # Service fully deployed
    }
}

############
###Minnesota
############

$LTservice = Get-Service -Name ltservice -ErrorAction SilentlyContinue
$SCservice = Get-Service -Name "ScreenConnect Client (60a06214111b8797)" -ErrorAction SilentlyContinue
$locationid = 493
$token = '4065b68776902e53edc37004849e484c'

if($LTservice -eq $null)
{
    Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
} else {
    # Service already exists
    if($SCservice -eq $null)
    {
        Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Uninstall-Automate; Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
    }
    else{
        # Service fully deployed
    }
}



############
###Kentucky
############



$LTservice = Get-Service -Name ltservice -ErrorAction SilentlyContinue
$SCservice = Get-Service -Name "ScreenConnect Client (60a06214111b8797)" -ErrorAction SilentlyContinue
$locationid = 495
$token = '3e59aef231e73385078a421325e3a424'

if($LTservice -eq $null)
{
    Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
} else {
    # Service already exists
    if($SCservice -eq $null)
    {
        Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Uninstall-Automate; Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
    }
    else{
        # Service fully deployed
    }
}




#################
###Indiana North
#################



$LTservice = Get-Service -Name ltservice -ErrorAction SilentlyContinue
$SCservice = Get-Service -Name "ScreenConnect Client (60a06214111b8797)" -ErrorAction SilentlyContinue
$locationid = 496
$token = '310419f5bd6268d7ecc44419df69dac4'

if($LTservice -eq $null)
{
    Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
} else {
    # Service already exists
    if($SCservice -eq $null)
    {
        Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Uninstall-Automate; Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
    }
    else{
        # Service fully deployed
    }
}



################
###Indiana South
################



$LTservice = Get-Service -Name ltservice -ErrorAction SilentlyContinue
$SCservice = Get-Service -Name "ScreenConnect Client (60a06214111b8797)" -ErrorAction SilentlyContinue
$locationid = 497
$token = 'e0f2f760c3338a8ff116657835fa272b'

if($LTservice -eq $null)
{
    Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
} else {
    # Service already exists
    if($SCservice -eq $null)
    {
        Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Uninstall-Automate; Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
    }
    else{
        # Service fully deployed
    }
}


####################
###Southwest Georgia
####################


$LTservice = Get-Service -Name ltservice -ErrorAction SilentlyContinue
$SCservice = Get-Service -Name "ScreenConnect Client (60a06214111b8797)" -ErrorAction SilentlyContinue
$locationid = 500
$token = 'af3e260b029251574b0b6b2e2125886b'

if($LTservice -eq $null)
{
    Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
} else {
    # Service already exists
    if($SCservice -eq $null)
    {
        Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Uninstall-Automate; Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
    }
    else{
        # Service fully deployed
    }
}

#####################
###East Coast Georgia
#####################

$LTservice = Get-Service -Name ltservice -ErrorAction SilentlyContinue
$SCservice = Get-Service -Name "ScreenConnect Client (60a06214111b8797)" -ErrorAction SilentlyContinue
$locationid = 499
$token = 'ad3bf588df4052538f6b540e5e7147eb'

if($LTservice -eq $null)
{
    Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
} else {
    # Service already exists
    if($SCservice -eq $null)
    {
        Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Uninstall-Automate; Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
    }
    else{
        # Service fully deployed
    }
}




#####################
###East Coast Georgia
#####################

$LTservice = Get-Service -Name ltservice -ErrorAction SilentlyContinue
$SCservice = Get-Service -Name "ScreenConnect Client (60a06214111b8797)" -ErrorAction SilentlyContinue
$locationid = 499
$token = 'ad3bf588df4052538f6b540e5e7147eb'

if($LTservice -eq $null)
{
    Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
} else {
    # Service already exists
    if($SCservice -eq $null)
    {
        Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Uninstall-Automate; Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
    }
    else{
        # Service fully deployed
    }
}


#####################
###Florida Tallahasee
#####################

$LTservice = Get-Service -Name ltservice -ErrorAction SilentlyContinue
$SCservice = Get-Service -Name "ScreenConnect Client (60a06214111b8797)" -ErrorAction SilentlyContinue
$locationid = 502
$token = '038a781d56a2d3e4ae7a2c893cc1bddb'

if($LTservice -eq $null)
{
    Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
} else {
    # Service already exists
    if($SCservice -eq $null)
    {
        Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Uninstall-Automate; Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
    }
    else{
        # Service fully deployed
    }
}


#####################
###Florida ST Pete
#####################

$LTservice = Get-Service -Name ltservice -ErrorAction SilentlyContinue
$SCservice = Get-Service -Name "ScreenConnect Client (60a06214111b8797)" -ErrorAction SilentlyContinue
$locationid = 505
$token = '81aca30eb939f3961044729149f1b9ae'

if($LTservice -eq $null)
{
    Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
} else {
    # Service already exists
    if($SCservice -eq $null)
    {
        Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Uninstall-Automate; Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
    }
    else{
        # Service fully deployed
    }
}

#####################
###Florida Tampa
#####################

$LTservice = Get-Service -Name ltservice -ErrorAction SilentlyContinue
$SCservice = Get-Service -Name "ScreenConnect Client (60a06214111b8797)" -ErrorAction SilentlyContinue
$locationid = 501
$token = '24349b08a8134140d66baeb54fe07b2a'

if($LTservice -eq $null)
{
    Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
} else {
    # Service already exists
    if($SCservice -eq $null)
    {
        Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Uninstall-Automate; Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
    }
    else{
        # Service fully deployed
    }
}



#####################
###Florida Rendon
#####################

$LTservice = Get-Service -Name ltservice -ErrorAction SilentlyContinue
$SCservice = Get-Service -Name "ScreenConnect Client (60a06214111b8797)" -ErrorAction SilentlyContinue
$locationid = 506
$token = '556e219a8196e53601ae49e42b1b7798'

if($LTservice -eq $null)
{
    Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
} else {
    # Service already exists
    if($SCservice -eq $null)
    {
        Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Uninstall-Automate; Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
    }
    else{
        # Service fully deployed
    }
}



#####################
###Florida Central
#####################

$LTservice = Get-Service -Name ltservice -ErrorAction SilentlyContinue
$SCservice = Get-Service -Name "ScreenConnect Client (60a06214111b8797)" -ErrorAction SilentlyContinue
$locationid = 504
$token = '79fd11b773d0bcb944f8f3e29ad04ee5'

if($LTservice -eq $null)
{
    Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
} else {
    # Service already exists
    if($SCservice -eq $null)
    {
        Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Uninstall-Automate; Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
    }
    else{
        # Service fully deployed
    }
}


#####################
###Delaware
#####################

$LTservice = Get-Service -Name ltservice -ErrorAction SilentlyContinue
$SCservice = Get-Service -Name "ScreenConnect Client (60a06214111b8797)" -ErrorAction SilentlyContinue
$locationid = 494
$token = '0a5a67df1b848900aa7f4d4341c51e91'

if($LTservice -eq $null)
{
    Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
} else {
    # Service already exists
    if($SCservice -eq $null)
    {
        Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Uninstall-Automate; Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
    }
    else{
        # Service fully deployed
    }
}


#####################
###Atlanta
#####################

$LTservice = Get-Service -Name ltservice -ErrorAction SilentlyContinue
$SCservice = Get-Service -Name "ScreenConnect Client (60a06214111b8797)" -ErrorAction SilentlyContinue
$locationid = 482
$token = 'c09081c2b3378544bed35895386c3f0b'

if($LTservice -eq $null)
{
    Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
} else {
    # Service already exists
    if($SCservice -eq $null)
    {
        Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Uninstall-Automate; Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
    }
    else{
        # Service fully deployed
    }
}


#####################
###Unknown/other
#####################

$LTservice = Get-Service -Name ltservice -ErrorAction SilentlyContinue
$SCservice = Get-Service -Name "ScreenConnect Client (60a06214111b8797)" -ErrorAction SilentlyContinue
$locationid = 486
$token = '0e417e1d4907cb43652a173762a91a5f'

if($LTservice -eq $null)
{
    Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
} else {
    # Service already exists
    if($SCservice -eq $null)
    {
        Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Uninstall-Automate; Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
    }
    else{
        # Service fully deployed
    }
}


#####################
###Wayne
#####################

$LTservice = Get-Service -Name ltservice -ErrorAction SilentlyContinue
$SCservice = Get-Service -Name "ScreenConnect Client (60a06214111b8797)" -ErrorAction SilentlyContinue
$locationid = 492
$token = '8dfc855d48f5937763347eaac720f4a3'

if($LTservice -eq $null)
{
    Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
} else {
    # Service already exists
    if($SCservice -eq $null)
    {
        Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Braingears/PowerShell/master/Automate-Module.psm1'); Uninstall-Automate; Install-Automate -Server 'rmm.ciotech.us' -LocationID $locationid -Token $token -Transcript
    }
    else{
        # Service fully deployed
    }
}



