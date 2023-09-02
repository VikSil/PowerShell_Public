#The below script was developed to crawl through OMS FIX log and return a distribution of particular messages/tag values over given time period.
#Only works with the specific format of log files (not included, since that's confidential proprietary information).

#------------------------------------------------------------------------------
#
#   PARAMETER SECTION
#
#------------------------------------------------------------------------------

$logfile = "D:\WorkFolder\Logcrawler\FIX_FileParserLogfile.log"
$FIXfile = "D:\WorkFolder\Logcrawler\FIX_logs\FIX_Log_filename.log"
$starthour = 9
$endhour = 17
$ChartOverhead = 20

#------------------------------------------------------------------------------

$msgType = "Incoming"


"Initialising hash-array" | Out-File $logfile -Append

$BookedTradesPerMin=@{}
for ($hours=0; $hours -lt 24; $hours++){
    $BookedTradesPerMin[$hours]=@{}
    for ($minutes=0; $minutes -lt 60; $minutes++){
        $BookedTradesPerMin[$hours][$minutes]=0    
    }
}

$SkippedTradesPerMin=@{}
for ($hours=0; $hours -lt 24; $hours++){
    $SkippedTradesPerMin[$hours]=@{}
    for ($minutes=0; $minutes -lt 60; $minutes++){
        $SkippedTradesPerMin[$hours][$minutes]=0    
    }
}

" " | Out-File $logfile -Append
"Initialising FIX file reader" | Out-File $logfile -Append

$newstreamreader = New-Object System.IO.StreamReader ($FIXfile)
" " | Out-File $logfile -Append

"Dumping all processed lines" | Out-File $logfile -Append
while (($readeachline = $newstreamreader.ReadLine()) -ne $null)
{

        if (($readeachline.Contains($msgType)) -and (-not($readeachline.Contains("35=0"))) -and (($readeachline.Contains("150=2")) -or ($readeachline.Contains("150=1")))) {
            "Message that WAS booked" | Out-File $logfile -Append
            $readeachline | Out-File $logfile -Append
            $hourstamp =[int]$readeachline.substring(0,2)   
            $minutestamp = [int]$readeachline.substring(3,2)
            $BookedTradesPerMin[$hourstamp][$minutestamp]++
            $hourstamp | Out-File $logfile -Append
            $minutestamp | Out-File $logfile -Append
            $BookedTradesPerMin[$hourstamp][$minutestamp] | Out-File $logfile -Append

        }

        if (($readeachline.Contains($msgType)) -and (-not($readeachline.Contains("35=0"))) -and (-not($readeachline.Contains("150=2"))) -and (-not($readeachline.Contains("150=1"))) -and (-not($readeachline.Contains("35=A"))) -and (-not($readeachline.Contains("35=1")))) {
            "Message that was NOT booked" | Out-File $logfile -Append
            $readeachline | Out-File $logfile -Append
            $hourstamp =[int]$readeachline.substring(0,2)   
            $minutestamp = [int]$readeachline.substring(3,2)
            $SkippedTradesPerMin[$hourstamp][$minutestamp]++
            $hourstamp | Out-File $logfile -Append
            $minutestamp | Out-File $logfile -Append
            $SkippedTradesPerMin[$hourstamp][$minutestamp] | Out-File $logfile -Append
        }    
}

" " | Out-File $logfile -Append
"Consolidating results" | Out-File $logfile -Append

$ResultsConsolidated = [ordered]@{}

for ($hours=$starthour; $hours -lt $endhour; $hours++){
    for ($minutes=0; $minutes -lt 60; $minutes++){
        $ResultsConsolidated."$($hours):$($minutes)" = @()
        $ResultsConsolidated."$($hours):$($minutes)" +="$($BookedTradesPerMin.$($hours).$($minutes))"
        $ResultsConsolidated."$($hours):$($minutes)" +="$($SkippedTradesPerMin.$($hours).$($minutes))"

        "Outputting both keys separatelly" | Out-File $logfile -Append
        $ResultsConsolidated."$($hours):$($minutes)"[0] | Out-File $logfile -Append
        $ResultsConsolidated."$($hours):$($minutes)"[1] | Out-File $logfile -Append

        
    }
}
#-------------

#looking for maximum column height
$maxcolumn = 0
foreach ($datapoint in $ResultsConsolidated.GetEnumerator()){
    
    $total = [int]$datapoint.value[0] + [int]$datapoint.value[1]
    if ( $total -gt $maxcolumn) {
        $maxcolumn =$total
    }
}
"Maxcolumn is: $maxcolumn" | Out-File $logfile -Append


"Outputing to chart" | Out-File $logfile -Append

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Windows.Forms.DataVisualization

$Chart = New-object System.Windows.Forms.DataVisualization.Charting.Chart
$ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
$Chart.ChartAreas.Add($ChartArea)
$ChartTypes = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]

$legend = New-Object system.Windows.Forms.DataVisualization.Charting.Legend
$legend.name = "MainLegend"
$Chart.Legends.Add($legend)

#$Series = New-Object -TypeName System.Windows.Forms.DataVisualization.Charting.Series
#$Series.ChartType = $ChartTypes::StackedColumn
[void]$Chart.Series.Add("Processed")
$Chart.Series["Processed"].ChartType = "StackedColumn"

$XValues = @(foreach($datapoint in $ResultsConsolidated.GetEnumerator()){$datapoint.key})
$YValues = @(foreach($datapoint in $ResultsConsolidated.GetEnumerator()){[int]$datapoint.value[0]})

$Chart.Series["Processed"].Points.DataBindXY($XValues, $YValues)
$Chart.Series["Processed"].IsXValueIndexed = $true
$Chart.Series["Processed"].Color =[System.Drawing.Color]::Magenta
$Chart.Series["Processed"].IsVisibleInLegend = $true
$Chart.Series["Processed"].Legend = "MainLegend"

#----


[void]$Chart.Series.Add("Skipped")
$Chart.Series["Skipped"].ChartType = "StackedColumn"

$XValues2 = @(foreach($datapoint in $ResultsConsolidated.GetEnumerator()){$datapoint.key})
$YValues2 = @(foreach($datapoint in $ResultsConsolidated.GetEnumerator()){[int]$datapoint.value[1]})

$Chart.Series["Skipped"].Points.DataBindXY($XValues2, $YValues2)
$Chart.Series["Skipped"].IsXValueIndexed = $true
$Chart.Series["Skipped"].Color =[System.Drawing.Color]::Blue
$Chart.Series["Skipped"].IsVisibleInLegend = $true
$Chart.Series["Skipped"].Legend = "MainLegend"


$Chart.Width = 1850
$Chart.Height = 1000
$Chart.Left = 0
$Chart.Top = 0

$ChartArea.AxisX.Interval = '20'
$ChartArea.AxisY.Interval = '10'
$ChartArea.AxisY.Maximum =[int]$maxcolumn + [int]$ChartOverhead
$ChartArea.AxisX.LabelStyle.Angle = -90
$ChartArea.AxisX.MajorGrid.LineColor =  [System.Drawing.Color]::White
$ChartArea.BackColor = [System.Drawing.Color]::LightGray


$AnchorAll = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right -bor
    [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$Form = New-Object Windows.Forms.Form
$Form.Width = 1850
$Form.Height = 1000
$Form.WindowState = System.Windows.Forms.FormWindowState.Maximized;
$Form.controls.add($Chart)
$Chart.Anchor = $AnchorAll 

$Form.Add_Shown({$Form.Activate()})
[void]$Form.ShowDialog()




