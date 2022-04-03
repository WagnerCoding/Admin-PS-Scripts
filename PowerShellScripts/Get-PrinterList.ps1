$Machine = Read-Host "Enter Target Computer Name"
$Domain = Read-Host "Enter relevant domain for user logon"
$Username = Read-Host "Enter username with required privileges for command execution" 

Invoke-Command -ComputerName $Machine -Credential <domain>\<username to run command as> -ScriptBlock {
     Install-Module ImportExcel -Force
     Import-Module ImportExcel
     $Date = Get-Date -UFormat "%a, %b %d, %Y Time %H.%M.%S"
     Get-Printer | Select-Object -Property Name, PrinterStatus, DriverName, PortName | Export-Excel -Path "<path to folder for output file>\$Env:Computername.xlsx" -AutoSize -TableName "$Env:Computername_Printers" -WorksheetName "$Date"
     }
