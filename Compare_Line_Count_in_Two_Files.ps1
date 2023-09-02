
$logfile = "C:\Program Files\InstallationFolder\LogFolder\LogFileName.txt"

#directory with report files
$w_exp_dir = "C:\Program Files\InstallationFolder\Reports\Sent"
#get the latest report
$w_exp = Get-ChildItem -Path $w_exp_dir | Sort-Object LastAccessTime -Descending | Select-Object -First 1
#log which file was processed
Add-Content $logfile  "`n$(Get-Date) The file is: $($w_exp.Fullname)"
#find the number of lines in the file
$w_lines = Get-Content $w_exp.FullName | Measure-Object –Line
#log it 
Add-Content $logfile  "`n$(Get-Date) The report has $($w_lines.Lines) lines in it"

#get the latest trade export
$t_exp = "C:\Program Files\InstallationFolder\TradeExports\FX_Trades.csv"
#log it
Add-Content $logfile  "`nComparing against the trade export file: $t_exp"
#find the number of lines in the trade export 
$t_lines = Get-Content $t_exp | Measure-Object –Line
#log it 
Add-Content $logfile  "`n$(Get-Date) The trade export has $($t_lines.Lines) lines in it"



#send e-mail if the number of lines in report and trade export don't match
if ($w_lines.Lines -ne $t_lines.Lines){
Add-Content $logfile  "`nSending e-mail"
Add-Content $logfile  "`n"
Add-Content $logfile  "`nFor the record, this was the data in the trade export file"
Add-Content $logfile  "`n"
Add-Content $logfile "`n$(Get-Content $t_exp)"
Add-Content $logfile  "`n"

#Server Configuration
$smtpServer = "PUT MAILSERVER NAME HERE"
$msg =  New-Object Net.Mail.MailMessage
$smtp = New-Object Net.Mail.SmtpClient($smtpServer, 25)

#Email Configuration
$msg.From = "SENDEREMAIL@DOMAIN.com"
$msg.To.Add("RECEIVEREMAIL@DOMAIN.com")

$msg.Subject = "Some trades missed from report"
$msg.Body = "Hello,

EXPLAIN WHAT HAPPENED,
HOW TO FIX IT,
WHERE THE LOG FILES ARE. 

"

   $smtp.Send($msg)

}



