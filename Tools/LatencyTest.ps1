# PingTestWithDurationAndAsciiChart.ps1
# Example
# [2023-04-23 21:49:14] Average latency over the last 5 seconds: 78 ms
# [2023-04-23 21:49:19] Average latency over the last 5 seconds: 55.4 ms
# [2023-04-23 21:49:24] Average latency over the last 5 seconds: 61.4 ms
# [2023-04-23 21:49:30] Average latency over the last 5 seconds: 50.4 ms

# TimeStamp           IPAddress      Latency_ms
# ---------           ---------      ----------
# 2023-04-23 21:46:32 185.60.114.159         61
# 2023-04-23 21:46:33 185.60.114.159         48
# Ping results have been saved to PingResults.csv.
# ASCII Chart of Average Latency (ms) for Every 5 Seconds:
#  84ms                                   
#  76ms       |  |                   |    
#  67ms     ||| || | | |       |   | |    
#  59ms ||  |||||| ||| |||| ||||   ||| |  
#  50ms |||||||||||||||||||||||||| ||||| |
#  42ms ||||||||||||||||||||||||||||||||||
#  34ms ||||||||||||||||||||||||||||||||||
#  25ms ||||||||||||||||||||||||||||||||||
#  17ms ||||||||||||||||||||||||||||||||||
#   8ms ||||||||||||||||||||||||||||||||||
#      0                  10                  20                  30      
#      + latency (ms)
#                                        + time (seconds)

param (
    [string]$TargetIP = "185.60.114.159",
    [int]$DurationInMinutes = 3,
    [int]$PacketSize = 1024,
    [string]$OutputFile = "PingResults.csv"
)

function Ping-HostWithDuration {
    param (
        [string]$IPAddress,
        [int]$DurationInMinutes,
        [int]$PacketSize
    )

    $pingResults = @()
    $endTime = (Get-Date).AddMinutes($DurationInMinutes)
    $totalSeconds = $DurationInMinutes * 60
    $elapsedSeconds = 0
    $intervalLatencies = @()

    while ((Get-Date) -lt $endTime) {
        $pingResult = Test-Connection -ComputerName $IPAddress -Count 1 -BufferSize $PacketSize -ErrorAction SilentlyContinue
        $currentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        if ($pingResult) {
            $latency = $pingResult.ResponseTime
            $intervalLatencies += $latency
            $pingResults += [PSCustomObject]@{
                'TimeStamp' = $currentTime
                'IPAddress' = $IPAddress
                'Latency_ms' = $latency
            }
        }
        else {
            $pingResults += [PSCustomObject]@{
                'TimeStamp' = $currentTime
                'IPAddress' = $IPAddress
                'Latency_ms' = "N/A"
            }
        }

        $elapsedSeconds++

        if ($elapsedSeconds % 5 -eq 0) {
            $averageLatency = [Math]::Round(($intervalLatencies | Measure-Object -Average).Average, 2)
            Write-Host "[$currentTime] Average latency over the last 5 seconds: $averageLatency ms"
            $intervalLatencies = @()
        }

        Start-Sleep -Seconds 1
    }

    return $pingResults
}

function Draw-AsciiChart {
    param (
        [System.Collections.ArrayList]$Data
    )

    $maxLatency = [Math]::Ceiling(($Data | Measure-Object -Maximum).Maximum)
    $chartHeight = 10
    $chartWidth = $Data.Count

    # Draw Y-axis labels
    for ($i = $chartHeight; $i -gt 0; $i--) {
        $threshold = ($maxLatency / $chartHeight) * $i
        $label = "{0,3}ms" -f [Math]::Round($threshold)
        $row = "$label "

        # Draw chart bars
        foreach ($value in $Data) {
            if ($value -ge $threshold) {
                $row += "|"
            } else {
                $row += " "
            }
        }

        Write-Host $row
    }

    # Draw X-axis labels
    $xAxisLabels = " " * 4
    $tickSpacing = 10
    for ($i = 0; $i -lt $chartWidth; $i++) {
        if ($i % $tickSpacing -eq 0) {
            $xAxisLabels += ($i * 1).ToString().PadLeft(2, ' ')
        } else {
            $xAxisLabels += "  "
        }
    }
    Write-Host $xAxisLabels

    # Draw axis titles
    Write-Host (" " * 4) + "latency (ms)"
    Write-Host (" " * ($chartWidth + 4)) + "time (seconds)"
}


# Run the ping test
$pingData = Ping-HostWithDuration -IPAddress $TargetIP -DurationInMinutes $DurationInMinutes -PacketSize $PacketSize

# Export the data to a CSV file
$pingData | Export-Csv -Path $OutputFile -NoTypeInformation

# Calculate average latencies for every 5-second interval
$intervals = [System.Collections.ArrayList]@()
$intervalData = $pingData | Where-Object { $_.Latency_ms -ne "N/A" } | Select-Object -ExpandProperty Latency_ms
$intervalCount = [Math]::Ceiling($intervalData.Count / 5)

for ($i = 0; $i -lt $intervalCount; $i++) {
    $start = $i * 5
    $end = ($i + 1) * 5 - 1
    $interval = $intervalData[$start..$end]
    $averageLatency = [Math]::Round(($interval | Measure-Object -Average).Average, 2)
    $intervals.Add($averageLatency) | Out-Null
}

# Display the results in a nicely formatted table
$pingData | Format-Table -AutoSize

Write-Host "Ping results have been saved to $($OutputFile)."

# Draw the ASCII chart
Write-Host "ASCII Chart of Average Latency (ms) for Every 5 Seconds:"
Draw-AsciiChart -Data $intervals
