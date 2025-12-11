# ============================================================================
# Harvester Status Checker
# Schnelles Monitoring ohne Dashboard
# ============================================================================

$envPath = Join-Path $PSScriptRoot "env.json"
$env = Get-Content $envPath | ConvertFrom-Json
$supabaseUrl = $env.SUPABASE_URL
$supabaseKey = $env.SUPABASE_SERVICE_ROLE_KEY

$headers = @{
    "apikey" = $supabaseKey
    "Authorization" = "Bearer $supabaseKey"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  HARVESTER STATUS CHECK" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Queue Status
Write-Host "[Queue Status]" -ForegroundColor Yellow
try {
    $uri = [System.Uri]::new("$supabaseUrl/rest/v1/knowledge_harvest_queue?select=status")
    $items = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
    
    $statusCount = $items | Group-Object status | Select-Object Name, Count
    foreach ($status in $statusCount) {
        $color = switch ($status.Name) {
            "completed" { "Green" }
            "pending" { "Yellow" }
            "processing" { "Cyan" }
            "failed" { "Red" }
            default { "White" }
        }
        Write-Host "  $($status.Name): $($status.Count)" -ForegroundColor $color
    }
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Hängende Items
Write-Host "[Hängende Items (>10 Min)]" -ForegroundColor Yellow
try {
    $cutoff = (Get-Date).AddMinutes(-10).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    $uri = [System.Uri]::new("$supabaseUrl/rest/v1/knowledge_harvest_queue?status=eq.processing&select=topic,attempts,last_attempt_at")
    $processing = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
    
    $stuck = $processing | Where-Object {
        [DateTime]::Parse($_.last_attempt_at) -lt (Get-Date).AddMinutes(-10).ToUniversalTime()
    }
    
    if ($stuck.Count -eq 0) {
        Write-Host "  Keine hängenden Items!" -ForegroundColor Green
    } else {
        foreach ($item in $stuck) {
            Write-Host "  - $($item.topic) (Attempts: $($item.attempts))" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Failed Topics
Write-Host "[Failed Topics (Letzte 5)]" -ForegroundColor Yellow
try {
    $uri = [System.Uri]::new("$supabaseUrl/rest/v1/failed_topics?select=topic,error_code,created_at&order=created_at.desc&limit=5")
    $failed = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
    
    if ($failed.Count -eq 0) {
        Write-Host "  Keine Failed Topics!" -ForegroundColor Green
    } else {
        foreach ($item in $failed) {
            $date = [DateTime]::Parse($item.created_at).ToLocalTime().ToString("yyyy-MM-dd HH:mm")
            Write-Host "  - $($item.topic) [$($item.error_code)] ($date)" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Letzte Erfolge
Write-Host "[Letzte Erfolge (5)]" -ForegroundColor Yellow
try {
    $uri = [System.Uri]::new("$supabaseUrl/rest/v1/knowledge_harvest_queue?status=eq.completed&select=topic,last_attempt_at&order=last_attempt_at.desc&limit=5")
    $completed = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
    
    if ($completed.Count -eq 0) {
        Write-Host "  Noch keine erfolgreichen Harvests" -ForegroundColor Gray
    } else {
        foreach ($item in $completed) {
            $date = [DateTime]::Parse($item.last_attempt_at).ToLocalTime().ToString("yyyy-MM-dd HH:mm")
            Write-Host "  - $($item.topic) ($date)" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
