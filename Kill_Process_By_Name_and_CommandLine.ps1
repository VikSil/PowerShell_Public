$procName = 'notepad.exe'
$cmdLine  = "*notepad*"


$process = gcim win32_process| Where-Object {$_.ProcessName -eq $procName -and $_.CommandLine -like $cmdLine } 

taskkill /pid $process.processid