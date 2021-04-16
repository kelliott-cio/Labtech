## Based on a script by Robbie Vance at 
## http://pleasework.robbievance.net/howto-get-webroot-endpoints-using-unity-rest-api-and-powershell/

## And additional work done by:
## AMorgan Dec 2017.

## Modified by Shane Cooper Feb 2018
## This example builds on that, and loops through multiple sites to get endpoint info for each.
## It then exports all endpoints to csv, sorted by Site,MAC, and LastSeen date, to help with finding duplicates.
## The sort properties can be changed
## Additional endpoint properties can be included. They're listed on Line 82.
## The CSV name outputs with the Parent GSM key code for reference



##########------------------------------####
## These variables are specific to your console and credentials these variables.
# global GSM keycode (same for all admins and sites)
$GsmKey = 'SAC2-LTSW-A278-299A-5258'

# An administrator user for your Webroot portal -- this is typically the same user you use to login to the main portal
$WebrootUser = 'it_operations@ciotech.us'
 
# This is typically the same password used to log into the main portal
$WebrootPassword = 'D,k3i6;Gb,DNsM4'
 
# This must have previously been generated from the Webroot GSM for the site you wish to view
$APIClientID = 'client_IDwWs48x@ciotech.us'
$APIPassword = 'P@9{7=bda6}^94X'
##########------------------------------####


######################################
### These are common variables that you don't need to change
# The base URL for which all REST operations will be performed against
$BaseURL = 'https://unityapi.webrootcloudav.com'

# You must first get a token which will be good for 300 seconds of future queries.  We do that from here
$TokenURL = "$BaseURL/auth/token"
 
# Once we have the token, we must get the SiteID of the site with the keycode we wish to view Endpoints from
$SiteIDURL = "$BaseURL/service/api/console/gsm/$GsmKey/sites"
 
# All Rest Credentials must be first converted to a base64 string so they can be transmitted in this format
$Credentials = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($APIClientID+":"+$APIPassword ))
 
write-host "Get token" -ForegroundColor Green
$Params = @{
            "ErrorAction" = "Stop"
            "URI" = $TokenURL
            "Headers" = @{"Authorization" = "Basic "+ $Credentials}
            "Body" = @{
                          "username" = $WebrootUser
                          "password" = $WebrootPassword
                          "grant_type" = 'password'
                          "scope" = 'Console.GSM'
                        }
            "Method" = 'post'
            "ContentType" = 'application/x-www-form-urlencoded'
            }
 
$AccessToken = (Invoke-RestMethod @Params).access_token

write-host "Get sites data" -ForegroundColor Green
$Params = @{
            "ErrorAction" = "Stop"
            "URI" = $SiteIDURL
            "ContentType" = "application/json"
            "Headers" = @{"Authorization" = "Bearer "+ $AccessToken}
            "Method" = "Get"
        }

# Note: the code below does not filter-out deactivated sites, which caused errors to be returned for these at end of script and is harmless.

(Invoke-RestMethod @Params).Sites | 
	ForEach-Object {
		$mySiteName = $_.SiteName
		write-host ""
		write-host "Getting endpoint info for site $mySiteName"
		$mySiteID = $_.SiteId
		$EndpointIDURL = "$BaseURL/service/api/console/gsm/$GsmKey/sites/$mySiteId/endpoints"

		$Params2 = @{
            "ErrorAction" = "Stop"
            "URI" = $EndpointIDURL
            "ContentType" = "application/json"
            "Headers" = @{"Authorization" = "Bearer "+ $AccessToken}
            "Method" = "Get"
        }
		# List all endpoints for this site, showing only desired properties.  Add SiteName as extra property to each item in object.
		# Note: You can include additional objects as desired. They are: [GroupName,FirstSeen,AgentVersion,LicenseKey,VM,PolicyName,LastInfected,InternalIP,ADDomain,ADOU,Workgroup,CurrentUser,WindowsFullOS,LastPublicIP]
		(Invoke-RestMethod @Params2).Endpoints | foreach-object {$_|add-member -type noteproperty -name SiteName -value $mySiteName;$_} | Select-Object -Property SiteName,HostName,MACAddress,LastSeen,EndpointId,AgentVersion,WindowsFullOS | Sort-Object SiteName,MACAddress,LastSeen | Export-Csv -Append -Path $GsmKey"_All-Endpoints.csv"


	}
write-host ""
write-host "--------------------------------"
write-host "Script Finished"
exit
