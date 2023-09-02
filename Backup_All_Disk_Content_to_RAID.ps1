<#
The script compares files currently in the origin disk and backup disk.
Files that are not present in the backup disk will be copied over from the origin disk.
Files that are no longer in the origin disk will be deleted from backup disk.


A few ideas on how to improve this script:
*make it delete the old log file
*make it output  asummary of what was added and what was deleted


#>


$copyFrom = 'CurrentStuff'
$copyTo = 'RAID'

try{
    
    $RaidExists = $false
    $PrimaryExists = $false

    foreach ($drive in Get-volume) #for each disk drive
    {
        Write-Host $drive.FileSystemLabel
        Write-Host $drive.DriveLetter

        if($drive.FileSystemLabel -eq $copyTo){#Finds the drive letter of RAID disk and sets location for logging
            Write-Host $drive.DriveLetter

            $RAIDRoot = $drive.DriveLetter +":"
            $today_in_ISO = Get-Date -format 'yyyy-MM-dd'
            $logfile = $RAIDRoot+"\Backup_"+$copyFrom+"_"+$today_in_ISO+".log"
            $PrimaryRootBackup = $RAIDRoot+"\" + $copyFrom+ "\"
            $RaidExists = $true
        }
        
        if($drive.FileSystemLabel -eq $copyFrom){#Finds the drive letter of Primary disk
            Write-Host $drive.DriveLetter

            $PrimaryRoot = $drive.DriveLetter +":"
            $PrimaryExists = $true
        }


    }

    "$(Get-Date -format 'u') BACKUP STARTING" | out-file $logfile -append
    
    if($RaidExists -and $PrimaryExists ){#Will only attempt to back up if both drives are connected
    
        "$(Get-Date -format 'u') RAIDRoot is "+ $RAIDRoot | out-file $logfile -append
        "$(Get-Date -format 'u') PrimaryRoot is "+ $PrimaryRoot  | out-file $logfile -append
        "$(Get-Date -format 'u') PrimaryRootBackup is "+ $PrimaryRootBackup  | out-file $logfile -append


        foreach($file in get-childitem $PrimaryRoot -Recurse -File){ #Recursivelly interates through all files in Primary disk
        #because this only looks at files empty directories will not be copied(!)
        
            ""| out-file $logfile -append
            "$(Get-Date -format 'u') Processing file  "+ $file.fullname  | out-file $logfile -append

            $BackupLocation =$PrimaryRootBackup+($file.fullname).Substring(3) #figures out the equivalent path of the backup
            Write-Host $BackupLocation
            "$(Get-Date -format 'u') Checking against  "+ $BackupLocation  | out-file $logfile -append


            if (Test-Path -Path $BackupLocation -PathType Leaf){#if file has been backed up before will compare modification dates
                "$(Get-Date -format 'u') Backup already exists " | out-file $logfile -append
                Write-Host 'The file already exists'
                $OldModTime = $file.lastWriteTime
                $NewModTime = (get-item $BackupLocation).LastWriteTime
                "$(Get-Date -format 'u') File Last modified on " +$OldModTime | out-file $logfile -append
                "$(Get-Date -format 'u') Backup Last modified on " +$NewModTime | out-file $logfile -append

                if ($OldModTime -ne $NewModTime){#if modification times are not equal, override the baackup (always assume that Primary has correct data)
                    "$(Get-Date -format 'u') Modified times differ - will attempt to replace " | out-file $logfile -append
                    Copy-Item $file.FullName -destination $BackupLocation -force    
                }


            }
            else {#if file has never been backed up will add it
                "$(Get-Date -format 'u') Backup does not exist, copying... " | out-file $logfile -append
                Write-Host 'File does not exist'
                New-Item -ItemType File -Path $BackupLocation -Force; #force parameter will copy directory structure if required
                Copy-Item $file.FullName -destination $BackupLocation
            }

    
        }

  

        " "| out-file $logfile -append
        "$(Get-Date -format 'u') DELETING OBSOLETE FILES from Backup " | out-file $logfile -append
        foreach($file in get-childitem $PrimaryRootBackup -Recurse -File){#Will recurse through all items in Backup and delete obsolete ones
            "$(Get-Date -format 'u') Checking file  " +$file.fullname | out-file $logfile -append
            
            $PrimaryLocation = $PrimaryRoot+($file.FullName).Substring(15)
            Write-Host $PrimaryLocation
            if (-not (Test-Path -Path $PrimaryLocation -PathType Leaf)){#if primary file no longer exists
                "$(Get-Date -format 'u') $PrimaryLocation does not exist. Deleting." | out-file $logfile -append  
                Remove-item -Path $file.FullName -force
            }


        }

        "$(Get-Date -format 'u') BACKUP COMPLETED SUCCESSFULLY" | out-file $logfile -append

    }
    else {
    
    "$(Get-Date -format 'u') One of the disks is not connected "| out-file $logfile -append
    "$(Get-Date -format 'u') RAIDRoot is "+ $RAIDRoot | out-file $logfile -append
    "$(Get-Date -format 'u') PrimaryRoot is "+ $PrimaryRoot  | out-file $logfile -append
    "$(Get-Date -format 'u') Quiting"| out-file $logfile -append
    ""| out-file $logfile -append

    }


}
catch {
    #If script falls over - output exception details to C:\temp
    "$(Get-Date -format 'u') Backup failed with error:" | out-file C:\temp\Backup.log -append
    $ErrorMessage = $_.Exception.Message | out-file C:\temp\Backup.log -append
    $FailedItem = $_.Exception.ItemName | out-file C:\temp\Backup.log -append
    
    
    #If script falls over - output exception details to log file
    "$(Get-Date -format 'u') Backup failed with error:" | out-file $logfile -append
    $ErrorMessage = $_.Exception.Message | out-file $logfile -append
    $FailedItem = $_.Exception.ItemName | out-file $logfile -append
    Break;

}


finally{


}