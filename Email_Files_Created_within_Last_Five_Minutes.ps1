# Server Configuration
$smtpServer = "PUT MAILSERVER NAME HERE"
$msg = new-object Net.Mail.MailMessage
$smtp = new-object Net.Mail.SmtpClient($smtpServer, 587)


# Email Configuration
$msg.From = "SENDEREMAIL@DOMAIN.com"
$msg.To.Add("RECEIVEREMAIL@DOMAIN.com")
$msg.Subject = "Files created within last five minutes from "+@(Get-Date)
$msg.Body = ""

# Attachments
$reportDir = "C:\Program Files\InstallationFolder\FileFolder\"
$HasAttachment = $FALSE
foreach ($file in Get-ChildItem $reportDir)
{
	#only emails files created in the last 5 minutes
	if ($file.CreationTime -gt ((get-date).AddMinutes(-5)))
	{
	    $att = New-Object System.Net.Mail.Attachment($reportDir + $file)
        Write-Host "Attachment: "$file
        $msg.Attachments.Add($att)
        $HasAttachment = $TRUE		
	}
}

# Send Email
if ($HasAttachment -eq $TRUE) # Only send email if there are attachments
{
    Write-Host "Sending Email"
    $smtp.Send($msg)
}