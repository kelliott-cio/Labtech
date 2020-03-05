import-module activedirectory

$export = Get-ADGroup -Filter {(name -like "CTX_Hosted-MSAccess-SPLA")}  | Get-ADGroupMember -Recursive | Where {$_.objectClass -eq "user" } | Get-ADUser -properties * | where {($_.enabled -eq $true) -or ($_.enabled -eq $null)} |  ? {($_.description -notlike '*Built-In*')} |select SamAccountName,name,emailaddress,lastlogondate,physicaldeliveryofficename  -unique

Filter MaybeExport-CSV {
   if ($export)
    {
      Export-CSV -InputObject $export -Path c:\windows\temp\test.csv -notypeinformation -Append}
    }
MaybeExport-csv









import-module activedirectory

Get-ADGroup -Filter {(name -like "@adgroup@")}  | Get-ADGroupMember -Recursive | Where { $_.objectClass -eq "user" } | Get-ADUser -properties * | where {($_.enabled -eq $true) -or ($_.enabled -eq $null)} |  ? {($_.description -notlike '*Built-In*')} |select SamAccountName,name,emailaddress,lastlogondate,physicaldeliveryofficename  -unique | export-csv @path@@enccleanedfilename@



import-module activedirectory

$export = Get-ADGroup -Filter {(name -like "@adgroup@")}  | Get-ADGroupMember -Recursive | Where {$_.objectClass -eq "user" } | Get-ADUser -properties * | where {($_.enabled -eq $true) -or ($_.enabled -eq $null)} |  ? {($_.description -notlike '*Built-In*')} |select SamAccountName,name,emailaddress,lastlogondate,physicaldeliveryofficename  -unique

Filter MaybeExport-CSV {
   if ($export)
    {
       $export | Export-CSV  -Path @path@@enccleanedfilename@}
    }
MaybeExport-csv


import-module activedirectory

$export = Get-ADGroup -Filter {(name -like "CTX_Hosted-Project-SPLA")}  | Get-ADGroupMember -Recursive | Where {$_.objectClass -eq "user" } | Get-ADUser -properties * | where {($_.enabled -eq $true) -or ($_.enabled -eq $null)} |  ? {($_.description -notlike '*Built-In*')} |select SamAccountName,name,emailaddress,lastlogondate,physicaldeliveryofficename  -unique

Filter MaybeExport-CSV {
   if ($export)
    {
      $export | Export-CSV  -Path c:\windows\temp\CTX_Hosted-Project-SPLA.csv}
    }

MaybeExport-csv


import-module activedirectory

Get-ADGroup -Filter {(name -like "*ctx.citrix*") -or (name -like "*ctx_*") -or (name -like "AllTS*") -or (name -like "Terminal Server Users*") -or (name -like "*rdp Users*") -or (name -like "*rds farm Users*") -or (name -like "*HERA Remote Desktop Users*")} | Get-ADGroupMember -Recursive | Where { $_.objectClass -eq "user" } | Get-ADUser -properties * | where {$_.enabled -eq $false} |  ? {($_.description -notlike '*Built-In*')} |select SamAccountName,name,emailaddress,lastlogondate,physicaldeliveryofficename  -unique | export-csv @path@@enccleanedfilename@



import-module activedirectory

$export = Get-ADGroup -Filter {(name -like "CTX_Hosted-RDS-SPLA") or (name -like "*ctx.citrix*") -or (name -like "*ctx_*") -or (name -like "AllTS*") -or (name -like "Terminal Server Users*") -or (name -like "*rdp Users*") -or (name -like "*rds farm Users*") -or (name -like "*HERA Remote Desktop Users*")} | Get-ADGroupMember -Recursive | Where { $_.objectClass -eq "user" } | Get-ADUser -properties * |  where {($_.enabled -eq $true) -or ($_.enabled -eq $null)} |  ? {($_.description -notlike '*Built-In*')} |select SamAccountName,name,emailaddress,lastlogondate,physicaldeliveryofficename  -unique 

Filter MaybeExport-CSV {
   if ($export)
    {
      $export | export-csv @path@@enccleanedfilename@}
    }

MaybeExport-csv