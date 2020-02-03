add-type -path 'C:\Program Files (x86)\MySQL\MySQL Connector Net 8.0.18\Assemblies\v4.5.2\MySql.Data.dll'
$Connection = [MySql.Data.MySqlClient.MySqlConnection]@{ConnectionString='server=<your internal labtech server IP>;uid=<labtech username>;pwd=<labtech password>;database=labtech'}
$From = "<your alert email>"
$To = "<your on call email>"
$Cc = "<on call email 2>", "<on call email 3>"
$Subject = "Labtech SQL Server Down"
$Body = "Labtech SQL Server appears to be down."
$SMTPServer = "<Your mail server>"
$SMTPPort = "587"
$Connection.Open()
$MYSQLCommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$MYSQLDataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter
$MYSQLDataSet = New-Object System.Data.DataSet
$MYSQLCommand.Connection=$Connection
$MYSQLCommand.CommandTEXT='SELECT majorversion from config'
$MYSQLDataAdapter.SelectCommand=$MYSQLCommand
$Connection.Close()
while($true) {
try 
  {
    $Connection.Open()
    $NumberOfDataSets=$MYSQLDataAdapter.Fill($MYSQLDataSet)
    $MYSQLDataSet.tables[0]
  }
catch 
  {
    Send-MailMessage -From $From -to $To -Cc $Cc -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -Credential (New-Object System.Management.Automation.PSCredential("<your alert email>", (ConvertTo-SecureString '<your alert email password>' -AsPlainText -Force)))
  }
finally 
  {
    $Connection.Close()
    $MYSQLDataSet = New-Object System.Data.DataSet
    Start-Sleep -s 600
  }
}