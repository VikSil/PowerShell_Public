param(
	[string]$config = "C:\InstallationFolder\ProcessMonitor\config_file.txt",
	[string]$mode   = "normal"
)

# Email configuration 
$smtpServer = "MAILSERVER.com"
$clientname = "CLIENTNAME"
$emailFrom 	= "EMAILFROM@DOMAIN.com"
$emailTo = "RECIPIENTS HERE"


$debug = $False

$now = @(Get-Date)

$successBody = "" 
$success = 0

$failBody = ""
$fail = 0

$skippedBody = ""
$skip

$emailBody = "<html><body>"
$emailBody += "Checks run at $now<br>`n"

$checks = Get-Content $config

ForEach($line in $checks)
{
	if(($line.StartsWith("#")) -or ($line.length -lt 2))
	{
		Continue
	}

	$settings = $line.split(",")
	if(!($settings.length -eq 4))
	{
		Write-Host "Error: Config must have 4 entries per row"
		Continue
	}
	
	$startTime = $settings[0]
	$endTime = $settings[1]
	$type = $settings[2]
	$details = $settings[3]
	
	$statusMessage = ""

	if($now -ge $startTime -le $endTime)
	{
		Write-Host "Info: Running $type check for $details @$now (between $startTime-$endTime)"
		switch($type)
		{

			checkinfile {
				# This expects a path and search term separated by a ^
				# i.e. c:\progra~1\InstalDir\LogFiles\*.log^failure

				if (($details.split("^").length) -eq 2){
					Write-Host "Info: CheckInFile check"
					
					$date = Get-Date -Format "yyyyMMdd"
					$filename = $details.split("^")[0]
                    $filename = $filename.replace("<date>",$date)
					$pattern = $details.split("^")[1]
					
                    $results = @()
                    $FreshError = 0
                    $files = Get-ChildItem $filename # filename can include a wildcard, needs to handle _1, _2 etc. suffixes
                    foreach($file in $files)
                    {
					    Write-Host "Info: Searching `"$file`" for `"$pattern`""
					    $results += Select-String $file -Pattern $pattern -SimpleMatch


#the following cycle checks chekinfile errors 
                        foreach($i in $results) #loops through all occurances of the error
                        {
                         
                             $timing = $i.Line.substring(0,8)
                             $current_hour = Get-Date -format "HH:mm:ss"
                             $TimeDiff = New-TimeSpan $timing $current_hour # solution from https://community.spiceworks.com/topic/436406-time-difference-in-powershell
                             if (($TimeDiff.Hours -eq 0) -and ($TimeDiff.Minute -lt 18)) #only report an error that have occured in the last 18 minutes
                             {
                                Write-Host "recent error"
                                
                                #This is ad-hoc solution for specific string pattern in file
                                if ($pattern = "QUANTITY ERROR")#if this bug check if happened for a new order.
                                {
                                    Write-Host "FOUND QTY ERROR"
                                    $nextline = $i.Context.PostContext|Select-String -Pattern "is not equal to allocated quantity"#gets the next line after the error
                                    foreach($j in $nextline)#there is only one line picked after the error line, but have to loop throught it anyway
                                    {
                                        $orderID = $j.Line.Substring($j.Line.IndexOf("for Order")+10,4) #get the errored order ID 
                                        Write-Host "Order id is:"$orderID
                                        $OrderTime = $j.Line.Substring(0,8) #get the exact time when the error was logged
                                        $orderstring = " for Order "+$orderID
                                        Write-Host "String to search for: "$orderstring
                                        $olderrors = Select-String $filename -Pattern $orderstring #check the logfile for all occurances of this order
                                        $FreshError=1 # assume it is a new problem unless proven otherwise
                                        $numoferrors = $olderrors.Matches.count
                                        Write-Host "number of errors: " $numoferrors
                                        if ($olderrors.Matches.count -gt 1){#only check for old occurances of the same error if the total number of errors is more than one
                                         Write-Host "Subloop"
                                        foreach($k in $olderrors) #loops through all occurances of the order
                                        {
                                     
                                            $oldtime = $k.Line.substring(0,8)  #check the time of the occurance 
                                            Write-Host  "oldtime "+$oldtime 
                                            $TimeDiff2 = New-TimeSpan $oldtime $OrderTime 
                                            Write-Host "Timediff2" $TimeDiff2

                                            if (([System.Math]::Abs($TimeDiff2.Hours) -gt 0) -or ([System.Math]::Abs($TimeDiff2.Minutes) -ge 18))
                                            #if the occurance was more than or exactly 18 munutes ago then it's a repeat error
                                            {
                                                $FreshError =0
                                                Write-Host "Will not report this order"                                       
                                            }

                                        }
                                        }
                                    }
                                }#end qunatity error bug ad-hoc check
                                else #if general checkinfile error happened within 18 minutes - report it
                                {
                                    $FreshError=1
                                }
                            }
                        }
                        
                    }


					if(($results.Count -gt 0)  -and $FreshError ) #uncomment the 2nd variable if using the check for the last hour
					{
						$failBody += "Fail (checkinfile):`"$pattern`" found in `"$file`"<br>`n"
						$fail += 1
					}
					else
					{
						$successBody += "Success (checkinfile):`"$pattern`" not found in `"$file`"<br>`n" 
						$success += 1
					}
				}
			}
            
            checknotinfile {
				# As above, but alerts when not in file

				if (($details.split("^").length) -eq 2){
					Write-Host "Info: CheckNotInFile check"
					
					$date = Get-Date -Format "yyyyMMdd"
					$filename = $details.split("^")[0]
					$filename = $filename.replace("<date>",$date)
					$pattern = $details.split("^")[1]
					
                    $results = @()

                    $files = Get-ChildItem $filename # filename can include a wildcard, needs to handle _1, _2 etc. suffixes
                    foreach($file in $files)
                    {
					    Write-Host "Info: Searching `"$file`" for `"$pattern`""
					    $results += Select-String $file -Pattern $pattern -SimpleMatch
                    }
					if($results -eq $null)
					{
						$failBody += "Fail (checknotinfile):`"$pattern`" not found in `"$file`"<br>`n"
						$fail += 1
					}
					else
					{
						$successBody += "Success (checknotinfile):`"$pattern`" found in `"$file`"<br>`n" 
						$success += 1
					}
				}
			}

            checkFIX2mins {
				# Alerts when the last FIX message was logged more than 2 minutes ago (i.e. FIX Server is down, no heartbeats)
				if ($type -eq "checkFIX2mins"){
					Write-Host "Info: CheckFIX2mins check"
					
					$date = Get-Date -Format "yyyyMMdd"
					$filename = $details.replace("<date>",$date)
                    					
					Write-Host "Info: Searching $filename for time of last FIX message"
					$lastFIXline = Get-Content $filename | Select -Last 1
                    $lastFIXtime = $lastFIXline.substring(0,8)
                    $lastFIXtime = [DateTime]::ParseExact($lastFIXtime,"HH:mm:ss",$null)
                    					
                    Write-Host "Comparing time of last FIX message ($lastFIXtime) to current time ($currenttime)"
                    $currenttime = Get-Date -format HH:mm:ss
                    $FIXtime = New-TimeSpan $lastFIXtime $currenttime
                    $FIXsecs = $FIXtime.TotalSeconds
                    Write-Host "Seconds since last FIX message: "$FIXsecs

					if($FIXsecs -gt 120)
					{
						$failBody += "Fail (checkFIX2mins): last FIX message ($lastFIXtime) received more than 2 mins ago (checked @$currenttime) - $filename<br>`n"
						$fail += 1
					}
					else
					{
						$successBody += "Success (checkFIX2mins): last FIX message ($lastFIXtime) received within the last 2 mins (checked @$currenttime) - $filename<br>`n"
						$success += 1
					}
				}
			}

            checkprinter { #check that Bullzip is the default printer to output reports
                $defaultprinter = Get-WmiObject -Query "SELECT * from Win32_Printer WHERE Default=$true"
                
                if ($defaultprinter.Name -ne 'Bullzip PDF Printer') 
                {
                    $failBody += "Fail (checkprinter): Bullzip PDF is not currently the default printer - Resetting Automatically`n"
                    $fail += 1
					$newprinter = Get-WmiObject -Query "Select * from Win32_Printer Where Name = 'Bullzip PDF Printer'"
					$newprinter.SetDefaultPrinter()
                }
                else
                {
                    $successBody += "Success (checkprinter): Bullzip PDF is currently the default printer`n"
                    $success += 1
                }   
            }

			default {
				Write-Host "Error:Check type not supported"
			}
		}
	}
	else
	{
		Write-Host "Info: Skipping $type check for $details @ $now (outside of $startTime-$endTime)"
		$skippedBody += "Skip: Skipping $type check for $details @ $now (outside of $startTime-$endTime)<br>`n"
		$skip += 1
	}
}

if($fail -gt 0)
{
	$emailBody += "&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;Failed checks!<br>********************************************************************************<br>"

	$emailBody += "<br>`n" + $failBody

	$emailBody += "********************************************************************************<br>"
}

if($success -gt 0)
{
	$emailBody += "&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;Successful checks<br>********************************************************************************<br>"

	$emailBody += "<br>`n" + $successBody 

	$emailBody += "********************************************************************************<br>"
}

if($skip -gt 0)
{
	$emailBody += "&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;Skipped checks<br>********************************************************************************<br>"

	$emailBody += "<br>`n" + $skippedBody 

	$emailBody += "********************************************************************************<br>"
}



$emailBody += "</body></html>"

$sendEmail = $False

switch($mode)
{
	normal
	{
		if($fail -gt 0)
		{	
			$emailSubject = "$clientname`: Minor Fails $fail/$($fail+$success) checks $now"
			$sendEmail = $True
		}
	}
	
	status
	{
		$emailSubject = "$clientname`: Status email $now"
		$sendEmail = $True
	}
}

if($sendEmail)
{

    if($debug)
	{
		Write-Host "Debug: Email from: $emailFrom"
		Write-Host "Debug: Email to:   $emailTo"
		Write-Host "Debug: Email subject: $emailSubject"
		Write-Host "Debug: Email body: $emailBody"
	}
	else
	{
        Write-Host "Info: Sending email"
        $msg = New-Object System.Net.Mail.MailMessage $emailFrom, $emailTo
        $msg.Subject = $emailSubject
        $msg.IsBodyHtml = $True
        $msg.Body = $emailBody

        $SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25) 
        $SMTPClient.EnableSsl = $False 
        $SMTPClient.UseDefaultCredentials = $False

	}
}

