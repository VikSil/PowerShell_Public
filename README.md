# PowerShell_Public

This repo contains snippets of PowerShell code to showcase my skills and previous uses of the scripting language. While some of the code was originally developed as part of an employment, all references to specific file system storage objects, data structures, server names and other proprietary information has been removed or replaced with generic descriptions. All scripts can be scheduled in Windows Task Manager to run at appropriate time and intervals.
The following table summarises the functionality of each file in the repo:

| Script filename     | Description |
| ----------- | ----------- |
| Backup_All_Disk_Content_to_RAID     | Script automates backup creation and maintenance. Takes in names of the backup disk and the origin disk. Directories and files on both are checked recursively. Files that are not present in the backup disk will be copied over from the origin disk. Files that have a newer last modified date in the origin disk will be copied over to the backup disk. Files that are no longer in the origin disk will be deleted from backup disk.       |
| Check_for_Missing_Dividend_Cashflows_in_DB  | Scipt runs a select statement in Microsoft SQL DB and sends e-mail if the select returns any lines. Takes Microsoft SQL Server and database names, log file objects and mailserver details. DB connection will be established to the MS Server, a query will be run and query result will be written to a file. The file content is checked and an alert e-mail is sent if there are any lines logged.        |
| Check_Report_File_for_Missing_Data_and_Email_Alert   | Script checks a report file for missing data and sends alerts. Takes in mailserver details. Checks a file in report folder with today's date in the file name for a pattern of missing data (blank cells). If any is found an alert e-mail is sent.        |
| Compare_Line_Count_in_Two_Files   | Script to monitor for missing lines in a report compared to another report. Takes in the paths to report file/directory, counts the number of lines in the latest file and sends an email if the line counts mismatch. |
| Email_Files_Created_within_Last_Five_Minutes   | Script selects files from a given directory that have been created within the last 5 minutes from when the script is run. The selected files will be sent in an email attachment.        |
| Fetch_Cursor_Coordinates   | Script will output the current coordinates of the cursor three seconds after being run.       |
| FIX_Log_Crawler   | Script parses a FIX log file and outputs a line graph characterising FIX traffic within given timeframe. Takes in path to the file to parse, starting and ending time of the chart. Will ignore heartbeats (tag 35 = 0). Will output two lines in a composite graph: one for processed messages, i.e. PARTIAL FILL (tag 150 = 1) and FILL (tag 150 = 2), another for unprocessed messages (all other values of tag 150). Useful for troubleshooting latency and throughput issues, especially at market open/close.  |
| FTP_File_Transfer   | Script transfers files from FTP server to local directory for another process to consume. Takes in a profile variable that determines FTP Server path and local destination path. All .csv files in the remote directory will be copied to the local directory and moved to an archive directory on the FTP server. |
| Kill_Process_By_Name_and_CommandLine   | Script takes in process name and a partial command line string. Processes matching the process name and containing the string argument in their command line will be removed.  |
| Process_Monitor   | Script performs checks according to a configuration file. Will send summary of all checks, or notifications about failed checks via e-mail. Can be configured to perform the following checks: <ul><li>check if given pattern is present in a file - useful for monitoring for common errors showing up in log files</li><li>check if given patter is not present in file - useful for monitoring if certain tasks have been run and registered in log files</li><li>check timestamp on the last line in FIX log - useful to monitor FIX server hearbeats</li><li>check the default printer and reset it - useful for making sure that the correct PDF writter is used for automated reports</li></ul> |
| Take_DB_Backup_Restore_to_UAT_Shrink_Transaction_Files   | Script performs overnight database maintenance tasks on MS SQL Server. Takes in production and UAT database names, log file path and backup folder. Caution: SCRIPT WILL DROP ALL CONNECTIONS!! Will make a backup of the production database and restore the backup on the UAT (overriding current UAT). Will shrink transaction files of both databases. |
| Truncate_Logfiles   | Script reduces the number of lines in a file. Takes in path to directory. Truncates content of all files in the directory to 10 000 last lines. |







