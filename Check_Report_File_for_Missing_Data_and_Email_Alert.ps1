# SMTP Server Configuration
$smtpServer = "eu-smtp-outbound-1.mimecast.com" 
$msg = new-object Net.Mail.MailMessage
$SMTP = new-object Net.Mail.SmtpClient($smtpServer, 25)
$SMTP.EnableSsl = $false 
$SMTP.Credentials = New-Object System.Net.NetworkCredential("PUT_MIMECAST_USER_EMAIL_HERE", "PUT_PASSWORD_HERE");

# Email Configuration
$msg.From = "SENDEREMAIL@DOMAIN.com"
$msg.To.Add("RECEIVEREMAIL@DOMAIN.com")
$msg.Subject = "Check files"
$msg.Body = "Hi,

This is an automated alert about files missing some data.
FOLLOWED BY INSTRUCTIONS ON HOW TO FIX THE ISSUE."


#define dir
$reportDir = "C:\Program Files\InstalationFolder\Reports\DataForTimeSeries"
#define string - if there are empty quotes in the file, that means that data is missing
$EmptyQuotes = ',"",'
#define file naming pattern - today's date
$pattern = get-date  -format "yyyy-MM-dd"
#variable for whether there is an erraneous file
$EmptyFile = $FALSE


foreach ($file in Get-ChildItem $reportDir) #for each file in the directory 
{ 
  if ($file.Name -match $pattern) #if name has pattern in it, then check contents
  { 
    $fileContents = Get-Content $file.PSPath #dump the contents of the file into an array declared on the fly
    $EmptyFile = $fileContents | %{$_ -match $EmptyQuotes} #check if there is at least one element in the content array containing the substring
    
    #IDEAS FOR IMPROVEMENT
    #breaking here would be nice
    #populating empty file names to the e-mail would be nice
  }    
 
}

if ($EmptyFile -eq $TRUE) #send an e-mail if at least one of today's files is empty
{
 Write-Host "Sending Email"
 $smtp.Send($msg)
}


