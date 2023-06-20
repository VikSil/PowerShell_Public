<#
This script will help you capture cursor coordinates on the screen
Run the script and move the cursor the the spot that you want to know the coordinates for
Wait for three seconds for the coordinates to appear in the console
#>

Add-Type -AssemblyName System.Windows.Forms

sleep 3

$X = [System.Windows.Forms.Cursor]::Position.X
$Y = [System.Windows.Forms.Cursor]::Position.Y
 
Write-Output "X: $X | Y: $Y"




