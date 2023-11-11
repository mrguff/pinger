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
$duration = ""

Write-Host "Monitoring $targetHost. Press Ctrl+C to stop."

function LogStatusChange {
    $endTime = Get-Date
    $uptime = if ($status -eq "UP") { "Uptime: $duration" } else { "Downtime: $duration" }

    if ($status -eq "DOWN") {
        Write-Host "$(Get-Date) - [$targetHost] is now $status! $uptime" -ForegroundColor Red
        Add-Content -Path $logFile -Value "$(Get-Date) - [$targetHost] is now $status! $uptime"
    } else {
        Write-Host "$(Get-Date) - [$targetHost] is now $status! $uptime" -ForegroundColor Green
        Add-Content -Path $logFile -Value "$(Get-Date) - [$targetHost] is now $status! $uptime"
    }
}

function CalculateDuration {
    $endTime = Get-Date
    $durationSec = ($endTime - $startTime).TotalSeconds

    $days = [math]::floor($durationSec / 86400)
    $durationSec -= $days * 86400

    $hours = [math]::floor($durationSec / 3600)
    $durationSec -= $hours * 3600

    $minutes = [math]::floor($durationSec / 60)
    $seconds = [math]::floor($durationSec % 60)

    $duration = "$days days, {0:D2}:{1:D2}:{2:D2}" -f $hours, $minutes, $seconds
}

try {
    while ($true) {
        $result = Test-Connection -ComputerName $host -Count 1 -ErrorAction SilentlyContinue

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
