#----------------------------------------
#Define the connection parameters below
#----------------------------------------
$SQLserverName = "SQLSERVERNAME" 
$database = "DBNAME"
$rootpath = "C:\Program Files\InstallationFolder\LogFiles\"

#--------------------------------------

# MailServer Configuration
$smtpServer = "MAILSERVERNAME"
$msg = new-object Net.Mail.MailMessage
$smtp = new-object Net.Mail.SmtpClient($smtpServer, 25)

#--------------------------------------
#Script parameters

$logdir = "C:\Program Files\InstallationFolder\LogFiles\"
$logfile = "LOGFILENAME.log"
#--------------------------------------


#the below query is for demonstration purposes only - all proprietary DB structures have been renamed 
$query = "select p.positionID, div.instID, div.eXDate, hpos.qty, div.divID, div.amountGross from dividend div, historicalPositions hpos, positions p
where div.eXDate >dateadd(DD, -1, dateadd(YY,datediff(yy,0,getdate()),0))
and div.eXDate <=CONVERT(DATE, getdate())
and (amountGross != 0 and amountNet != 0)
and cast(hpos.positionDate as date) in (
									 SELECT  DATEADD(DAY, CASE DATENAME(WEEKDAY,cast(div.eXDate as date)) 
									 WHEN 'Sunday' THEN -2 
									 WHEN 'Monday' THEN -3 
									 ELSE -1 END, DATEDIFF(DAY, 0, cast(div.eXDate as date)))
									)									
and hpos.qty !=0 
and hpos.positionID = p.positionID
and p.positionID not in (391, 586, 767,788, 801, 802, 728, 763, 754, 747)
and p.instID = div.instID
and not exists(select cashflowID from cashflow cflow
			   where cast(cflow.tradeDate as date) = cast(div.eXDate as date)
			   and cflow.cashflowIDType = 1
			   and cflow.positionID = hpos.positionID
			   )
order by 3 desc"

try{


    "$(Get-Date -format 'u') Running query" | out-file $logdir$logfile -append
    
    $MissingDivs = Invoke-Sqlcmd -Query $query -ServerInstance $SQLserverName -Database $database –ErrorAction Stop | export-csv $logdir"LogFileName.csv" #output results to file

    "$(Get-Date -format 'u') Query complete" | out-file $logdir$logfile -append

    $file = $logdir+"LogFileName.csv"
    $lines = Get-Content $file | Measure-Object –Line #find how many lines there are in the output file

    "$(Get-Date -format 'u') The number of lines in the file:",$lines | out-file $logdir$logfile -append

    if ($lines.Lines -gt 0){
    #if any missed dividends found in the file - send an e-mail

    # Email Configuration
    $smtpServer = "PUT MAILSERVER NAME HERE"
    $msg = new-object Net.Mail.MailMessage
    $smtp = new-object Net.Mail.SmtpClient($smtpServer, 587)
    $msg.From = "SENDEREMAIL@DOMAIN.com"
    $msg.To.Add("RECEIVEREMAIL@DOMAIN.com")
    $msg.Subject = "ALERT!! Dividends cashflows missing"
    $msg.Body = "Hi Support, 

    This is an automated notification that some dividend(s) were not posted on Ex Date even though the day before Ex Date position was still open. Please refer to the attached file for details. 
    
    Please check before reaching out to the client:
    1) If Ex Date fell on a weekend, was the dividend posted on Friday or Monday? This would be false positive and position needs to be excluded from check.
    2) Has the dividend been manually posted on a different date?
    3) Has the instrument been recently changed and was a new backdated dividend loaded in from BBG?

    Position can be excluded from this check by adding them to NOT IN clause in script C:\Program Files\InstallationFolder\ThisScript.ps1 on SERVERNAME
    
    
    "

#--------------------------------------

    #prepare attachment with all positions
  
    $msg.Attachments.Add($file)

    # Send Email
    "$(Get-Date -format 'u') Sending e-mail" | out-file $logdir$logfile -append
    $smtp.Send($msg) 

    }

}

catch {
    
    "$(Get-Date -format 'u') Something went wrong" | out-file $logdir$logfile -append
    $ErrorMessage = $_.Exception.Message | out-file $logdir$logfile -append
    $FailedItem = $_.Exception.ItemName | out-file $logdir$logfile -append

    # Email Configuration
    $smtpServer = "PUT MAILSERVER NAME HERE"
    $msg = new-object Net.Mail.MailMessage
    $smtp = new-object Net.Mail.SmtpClient($smtpServer, 587)
    $msg.From = "SENDEREMAIL@DOMAIN.com"
    $msg.To.Add("RECEIVEREMAIL@DOMAIN.com")
    $msg.Subject = "ALERT!! Dividend cashflow check failed"
    $msg.Body = "Hi Support, 

    An error occured while checking for missed dividends. The error was output to LogFileName.log in "+$logdir+". Please chceck."

    # Send Email
    "$(Get-Date -format 'u') Sending e-mail" | out-file $logdir$logfile -append
    $smtp.Send($msg) 

    Break;

}
finally {
 

}




