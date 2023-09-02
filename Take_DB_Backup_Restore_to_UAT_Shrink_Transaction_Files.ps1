$logfile = "E:\InstallationFolder\Backup_and_Restore.log"
$serverName = "DBSERVERNAME"
$sqldbnameFrom = "ORIGINDBNAME"
$sqldbnameTo = "DESTINATIONDBNAME"
$backupFolder = "E:\InstallationFolder\"

#Extract backup from the DB of origin
try{

"$(Get-Date -format 'u') Starting backup" | out-file $logfile -append

Backup-SqlDatabase -ServerInstance $serverName -Database $sqldbnameFrom -BackupAction Database -BackupFile "$($backupFolder)$($sqldbnameTo).bak" -Compression On -CopyOnly

"$(Get-Date -format 'u') Backup complete" | out-file $logfile -append
}
 
catch {
    #If script falls over - output exception details to file
    "$(Get-Date -format 'u') Backup failed with error:" | out-file $logfile -append
    $ErrorMessage = $_.Exception.Message | out-file $logfile -append
    $FailedItem = $_.Exception.ItemName | out-file $logfile -append
    Break;
 
}
finally {

}

#Force restore the backup onto the DB of destination
try{

"$(Get-Date -format 'u') Starting restore" | out-file $logfile -append

#Invoke-SqlCmd "USE [master]; ALTER DATABASE $sqldbnameTo SET  SINGLE_USER WITH ROLLBACK IMMEDIATE;" # to avoid error that database is in use

$query3 = 
"ALTER DATABASE $sqldbnameTo
SET offline WITH ROLLBACK immediate
GO

ALTER DATABASE $sqldbnameTo
SET online
GO
"

"$(Get-Date -format 'u') Dropping connections" | out-file $logfile -append
Invoke-Sqlcmd -ServerInstance $serverName -Database $sqldbnameTo -Query $query3

"$(Get-Date -format 'u') Replacing DB" | out-file $logfile -append
Restore-SqlDatabase -ServerInstance $serverName -Database $sqldbnameTo -BackupFile "$($backupFolder)$($sqldbnameTo).bak" -ReplaceDatabase

"$(Get-Date -format 'u') Restore complete" | out-file $logfile -append
}
 
catch {
    #If script falls over - output exception details to file
    "$(Get-Date -format 'u') Restore failed with error:" | out-file $logfile -append
    $ErrorMessage = $_.Exception.Message | out-file $logfile -append
    $FailedItem = $_.Exception.ItemName | out-file $logfile -append
    Break;
 
}
finally {

}


#Shrinking logfiles

try{
$query1 = "Use $sqldbnameFrom;
GO
ALTER DATABASE $sqldbnameFrom
SET RECOVERY SIMPLE;
GO
DBCC SHRINKFILE (Derivationlog, 89)
GO"

$query2 = "Use $sqldbnameTo;
GO
ALTER DATABASE $sqldbnameTo
SET RECOVERY SIMPLE;
GO
DBCC SHRINKFILE (Derivationlog, 90)
GO"

Invoke-Sqlcmd -ServerInstance $serverName -Database $sqldbnameFrom -Query $query1
Invoke-Sqlcmd -ServerInstance $serverName -Database $sqldbnameTo -Query $query2
}
 
catch {
    #If script falls over - output exception details to file
    "$(Get-Date -format 'u') Logfile shrink failed with error:" | out-file $logfile -append
    $ErrorMessage = $_.Exception.Message | out-file $logfile -append
    $FailedItem = $_.Exception.ItemName | out-file $logfile -append
    Break;
}

finally {
   
}