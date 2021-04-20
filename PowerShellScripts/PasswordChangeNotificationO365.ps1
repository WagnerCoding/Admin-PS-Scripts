.$profile
#################################################################################################################
# 
# Version 1.0 September 2016
# Fernando Pérez 
# Based on Robert Pearman (WSSMB MVP)
# 
# Script to Automated Email using Office 365 account to remind users Passwords Expiracy.
# Office 365 require SSL
# Requires: Windows PowerShell Module for Active Directory
#
#
##################################################################################################################
# Please Configure the following variables....
$smtpServer="smtp.office365.com" # Office 365 official smtp server
$expireindays = 21 # number of days for password to expire 
$from = "Support <support@mountainfamily.org>" # email from 
$logging = "Enabled" # Set to Disabled to Disable Logging
$logFile = "\\mfhc-fs01\Share\IT\Useful_Tools\PSTools\Scripts\PasswordExpiryNotificationEmails\21DaysOut\PasswordChangeNotificationLog-21Day($date).csv" # ie. c:\Scripts\PasswordChangeNotification.csv
$testing = "Disabled" # Set to Disabled to Email Users
$testRecipient = "lwagner@mountainfamily.org" 
$date = Get-Date -format ddMMyyyy
#
###################################################################################################################

# Add EMAIL Function
Function EMAIL{

	Param(
		$emailSmtpServer = $smtpServer,   #change to your SMTP server
		$emailSmtpServerPort = 587,
		$emailSmtpUser = "lwagner@mountainfamily.org",   #Email account you want to send from
		$emailSmtpPass = "$p",   #Password for Send from email account
		$emailFrom = "lwagner@mountainfamily.org",   #Email account you want to send from
		$emailTo,
		$emailAttachment,
		$emailSubject,
		$emailBody
	)
	Process{
	
	$emailMessage = New-Object System.Net.Mail.MailMessage( $emailFrom , $emailTo )
	$emailMessage.Subject = $emailSubject
	$emailMessage.IsBodyHtml = $true
	$emailMessage.Priority = [System.Net.Mail.MailPriority]::High
	$emailMessage.Body = $emailBody
 
	$SMTPClient = New-Object System.Net.Mail.SmtpClient( $emailSmtpServer , $emailSmtpServerPort )
	$SMTPClient.EnableSsl = $true
	$SMTPClient.Credentials = New-Object System.Net.NetworkCredential( $emailSmtpUser , $emailSmtpPass );
 
	$SMTPClient.Send( $emailMessage )
	}
}

# Check Logging Settings
if (($logging) -eq "Enabled")
{
    # Test Log File Path
    $logfilePath = (Test-Path $logFile)
    if (($logFilePath) -ne "True")
    {
        # Create CSV File and Headers
        New-Item $logfile -ItemType File
        Add-Content $logfile "Date,Name,EmailAddress,DaystoExpire,ExpiresOn"
    }
} # End Logging Check

# Get Users From AD who are Enabled, Passwords Expire and are Not Currently Expired
Import-Module ActiveDirectory
$users = get-aduser -filter * -properties Name, PasswordNeverExpires, PasswordExpired, PasswordLastSet, UserPrincipalName |where {$_.Enabled -eq "True"} | where { $_.PasswordNeverExpires -eq $false } | where { $_.passwordexpired -eq $false }
$DefaultmaxPasswordAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge

# Process Each User for Password Expiry
foreach ($user in $users)
{
    $Name = $user.Name
    $emailaddress = $user.userprincipalname
    $passwordSetDate = $user.PasswordLastSet
    $PasswordPol = (Get-AduserResultantPasswordPolicy $user)
    # Check for Fine Grained Password
    if (($PasswordPol) -ne $null)
    {
        $maxPasswordAge = ($PasswordPol).MaxPasswordAge
    }
    else
    {
        # No FGP set to Domain Default
        $maxPasswordAge = $DefaultmaxPasswordAge
    }
  
    $expireson = $passwordsetdate + $maxPasswordAge
    $today = (get-date)
    $daystoexpire = (New-TimeSpan -Start $today -End $Expireson).Days
        
    # Set Greeting based on Number of Days to Expiry.

    # Check Number of Days to Expiry
    $messageDays = $daystoexpire

    if (($messageDays) -ge "1")
    {
        $messageDays = "in " + "$daystoexpire" + " days"
    }
    else
    {
        $messageDays = "today."
    }

    # Email Subject Set Here
    $subject="Your password will expire $messageDays"
  
    # Email Body Set Here, Note You can use HTML, including Images.
    $body ="    
	<p>Dear $name,<br></P><br>
    <p>Your Password will expire $messageDays.<br>
    If you have received this email, your MFHC Windows login password will expire very soon. To minimize disruption to your workflow, please go about initiating a password change when you have a free moment within the next $messageDays using one of the methods listed below: <br>
    </P><br><br>
    <P>Method 1 (if connected to MFHCAir) :<br>
    1.	While logged in, press ctrl+alt+del on your keyboard. <br>
    2.	Click 'Change a Password' <br>
    3.	Type your current password in the box labeled 'Old Password' <br>
    4.	Type your new password in the box labeled 'New Password' <br>
    5.	Retype new password in the box labeled 'Confirm Password' <br>
    6.	Press 'Enter' <br>
        a.	If you receive an error, make adjustments to your desired new password, then try again. <br> 
        b.	If you receive a message informing you the password was changed, you are done. <br> 

    <P>Method 2 (If method 1 couldn’t be completed successfully, or your connection is over VPN): <br> 
    1. Double check that the VPN is connected. (Reach out to the IT team if you are having trouble connectng to the VPN) <br>
    2.	While logged in, press ctrl+alt+del on your keyboard. <br>
    3.	Click 'Change a Password' <br>
    4.	Type your current password in the box labeled 'Old Password' <br>
    5.	Type your new password in the box labeled 'New Password'<br>
    6.	Retype new password in the box labeled 'Confirm Password' <br>
    7.	Press 'Enter' <br>
        a.	If you receive an error, make adjustments to your desired new password, then try again. <br> 
        b.	If you receive a message informing you the password was changed, you are done. <br>
    </P><br>
    <P> Thank you, <br> 
    <br>
    Lucas Wagner <br> 
    IT Help Desk Specialist <br>
    <br>
    P.O. Box 339 <br>
    Glenwood Springs, CO 81601 <br>
    Office: 970.989.1129 <br>
    Internal Extension: 7138 <br>
    Call IT: 970.945.2840 ext. 6011 <br>
    lwagner@mountainfamily.org <br>
    Web English: https://mountainfamily.org <br>
    Web Español: https//mountainfamily.org/es/ <br>
    <P>"

   
    # If Testing Is Enabled - Email Administrator
    if (($testing) -eq "Enabled")
    {
        $emailaddress = $testRecipient
    } # End Testing

    # If a user has no email address listed
    if (($emailaddress) -eq $null)
    {
        $emailaddress = "youremailaddress@domain.com"    
    }# End No Valid Email

    # Send Email Message
    if (($daystoexpire -ge "0") -and ($daystoexpire -lt $expireindays))
    {
         # If Logging is Enabled Log Details
        if (($logging) -eq "Enabled")
        {
            Add-Content $logfile "$date,$Name,$emailaddress,$daystoExpire,$expireson" 
        }

		EMAIL -emailTo $emailaddress -emailSubject $subject -emailBody $body

    } # End Send Message
    
} # End User Processing



# End