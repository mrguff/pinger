param(
    [string]$targetHost = ""
)

if ($targetHost -eq "") {
    Write-Host "Usage: $((Get-Command $MyInvocation.InvocationName).Name) -host <hostname>"
    exit
}

$status = "DOWN"
$logFile = "ping_log_$targetHost.txt"
$startTime = Get-Date

Write-Host "Monitoring $targetHost. Press Ctrl+C to stop."

# Return days, hours, mins, secs between startTime and endTime
function CalculateDuration {
    param (
        [ref]$duration
    )
    $durationSec = ($endTime - $startTime).TotalSeconds
    $days = [math]::floor($durationSec / 86400)
    $durationSec -= $days * 86400
    $hours = [math]::floor($durationSec / 3600)
    $durationSec -= $hours * 3600
    $minutes = [math]::floor($durationSec / 60)
    $seconds = [math]::floor($durationSec % 60)
    $duration.Value = "$days days, {0:D2}:{1:D2}:{2:D2}" -f [int]$hours, [int]$minutes, [int]$seconds
}

function LogStatusChange {
    $duration = ""
    $endTime = Get-Date
    CalculateDuration -duration ([ref]$duration)
    if ($status -eq "DOWN") {
        Write-Host "$(Get-Date) - [$targetHost] is now $status! Uptime: $duration" -ForegroundColor Red
        Add-Content -Path $logFile -Value "$(Get-Date) - [$targetHost] is now $status! Uptime: $duration"
    } else {
        Write-Host "$(Get-Date) - [$targetHost] is now $status! Downtime: $duration" -ForegroundColor Green
        Add-Content -Path $logFile -Value "$(Get-Date) - [$targetHost] is now $status! Downtime: $duration"
    }
}

try {
    while ($true) {
        $result = Test-Connection -ComputerName $targetHost -Count 1 -ErrorAction SilentlyContinue
        if ($result -eq $null) {
            if ($status -eq "UP") {
                $status = "DOWN"
                LogStatusChange
                $startTime = Get-Date
            }
        } else {
            if ($status -eq "DOWN") {
                $status = "UP"
                LogStatusChange
                $startTime = Get-Date
            }
        }

        Start-Sleep -Seconds 1
    }
} catch {
    Write-Host "Error: $_"
}
