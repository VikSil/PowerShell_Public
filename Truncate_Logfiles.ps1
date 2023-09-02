$logdir = "C:\Program Files\InstallationFolder\Logs"

foreach ($file in Get-ChildItem $logdir)
{
   $lines = (gc $file.FullName | Measure-Object -Line).lines
    
    if ($lines -gt 10000) {
        $lines = $lines - 10000
    }

     (gc $file.FullName | select -skip $lines )| sc $file.FullName

}