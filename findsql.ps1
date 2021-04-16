function get-sql() {
    $inst = (get-itemproperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances
}
function get-sqlpath() {
    $p = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').$i
}

function get-sqleditions() {
    foreach ($i in $var)
        {
            (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$p\Setup").Edition
            (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$p\Setup").Version
        }
}

$var = get-sql
$output = @()
foreach ($_ in $var)
$output += get-sqleditions
$output -join ','
