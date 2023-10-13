Install-Module -Name ImportExcel -RequiredVersion 5.4.2
 
$Date = Get-Date -UFormat "%a, %b %d, %Y Time %H.%M.%S"
mkdir C:\Audits
Get-ADUser -filter { Enabled -eq $True -and PasswordNeverExpires -eq $False } -Properties "DisplayName", "msDS-UserPasswordExpiryTimeComputed" | Select-Object -Property "Displayname", @{Name = "ExpiryDate"; Expression = { [datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed") } } | Sort-Object -property ExpiryDate | Export-Excel -Path "C:\Audits\ADPasswordExpiryAudit.xlsx" -AutoSize -TableName ADPasswordExpiryAudit -WorksheetName "$Date" ; Import-Excel -Path "C:\Audits\ADPasswordExpiryAudit.xlsx" | Out-Gridview -wait
