#This script pulls files from remote folder to trade loader folder via FTP


param(
    [string]$Profile = "Tradeload"
)


#depending on which parameter is passed in, different directories are used

switch($Profile) {
    Positionload {
        [string]$remotePath = "/ftproot/Positions/Input/"
        [string]$archivepath = "/ftproot/Positions/Archive/"
        [string]$localPath = "C:\Program Files\InstallationFolder\Positionload\Input\"
    }
    Tradeload {
        [string]$remotePath = "/ftproot/Trades/Input/"
        [string]$archivepath = "/ftproot/Trades/Archive/"
        [string]$localPath = "C:\Program Files\InstallationFolder\Tradeload\Input\"
    }
    Vols {
        [string]$remotePath = "/ftproot/Volatility/Input/"
        [string]$archivepath = "/ftproot/Volatility/Archive/"
        [string]$localPath = "C:\Program Files\InstallationFolder\Volatilityload\Input\"
    }
}



$logfile = "V:\LogFiles\Tradeloader_FTP_"+$Profile+"_"+[DateTime]::Now.ToString("yyyy-MM-dd")+".log"

try {
    
   
    # Load WinSCP .NET assembly
    Add-Type -Path "C:\Program Files (x86)\WinSCP\WinSCPnet.dll"
    "$(Get-Date -format 'u') Loaded WinSCPnet.dll "| out-file $logfile -append 
 
    # Setup session options
    $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
        Protocol = [WinSCP.Protocol]::Sftp
        HostName = "hostname.com"
        UserName = "username"
        Password = "password" 
        SshHostKeyFingerprint = "PUT SSH FINGERPRINT HERE, IT LOOKS SMTHN LIKE THIS: ssh-ed25519 256 EKi0LAfWA5Gnc7onjImlw9YxpqtwZad5UwSddknP9bg=" 
        #fingerprint can be found when connected to the server via GUI in Session->Server/Protocol information
        #you need the first two lines in 'Server host key fingerprints' box
    }
 
    $session = New-Object WinSCP.Session

    # Connect
    $session.Open($sessionOptions)
    "$(Get-Date -format 'u') Connection Open:", $session.Opened | out-file $logfile -append

    #get the list of objects on the remote side of FTP
    $directoryInfo = $session.ListDirectory($remotePath)
    "$(Get-Date -format 'u') Retrieved content of the folder:", $directoryInfo | out-file $logfile -append

    #will loop through the objects on the remote side
    foreach($file in $directoryInfo.Files){
        if ($file.FullName -like '*.csv*')  { #only process .csv files
            "$(Get-Date -format 'u') Processing file: ",$file.FullName | out-file $logfile -append
            
            #download file to appropriate input directory for tradeloader to pick it up
            $session.GetFiles([WinSCP.RemotePath]::EscapeFileMask($file.FullName), $localPath).Check()
             "$(Get-Date -format 'u') File was downloaded to ",$localpath| out-file $logfile -append

            #move the file to archive on the remote side of FTP            
            [string]$newname = $file.Name+[DateTime]::Now.ToString("yyyy-MM-dd_HH-mm-ss") #add timestamp to name
            $newpath = $archivepath + $newname #set archiving path
             "$(Get-Date -format 'u') File will be archived to: ",$newpath| out-file $logfile -append
            $session.MoveFile($file.FullName, $newpath) #moving file to archive
            "$(Get-Date -format 'u') Archiving done"| out-file $logfile -append
        }

    }
}

catch {
    #If script falls over - output exception details to file
    "$(Get-Date -format 'u') Script fell over. Here is what was caught:" | out-file $logfile -append
    $ErrorMessage = $_.Exception.Message | out-file $logfile -append
    $FailedItem = $_.Exception.ItemName | out-file $logfile -append
    Break;

}


finally {
    # Disconnect, clean up
    "$(Get-Date -format 'u') Closing session"| out-file $logfile -append
    $session.Dispose()

}

