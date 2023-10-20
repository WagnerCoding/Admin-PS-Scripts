     Install-Module ImportExcel -Force
     Import-Module ImportExcel
     $Date = Get-Date -UFormat "%a, %b %d, %Y Time %H.%M.%S"
     Get-Printer | Select-Object -Property Name, PrinterStatus, DriverName, PortName | Export-Excel -Path "C:\Printers\$Env:Computername.xlsx" -AutoSize -TableName "$Env:Computername_Printers" -WorksheetName "$Date"
