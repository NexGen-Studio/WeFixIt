# Cleanup Stuck Harvester Items
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  HARVESTER CLEANUP" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Config laden
$envPath = Join-Path $PSScriptRoot "env.json"
if (-Not (Test-Path $envPath)) {
    Write-Host "ERROR: env.json nicht gefunden!" -ForegroundColor Red
    exit 1
}

$env = Get-Content $envPath | ConvertFrom-Json
$supabaseUrl = $env.SUPABASE_URL
$supabaseKey = $env.SUPABASE_SERVICE_ROLE_KEY

# Validiere Config
if ([string]::IsNullOrWhiteSpace($supabaseUrl)) {
    Write-Host "ERROR: SUPABASE_URL nicht gefunden in env.json!" -ForegroundColor Red
    exit 1
}
if ([string]::IsNullOrWhiteSpace($supabaseKey)) {
    Write-Host "ERROR: SUPABASE_SERVICE_ROLE_KEY nicht gefunden in env.json!" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Config geladen" -ForegroundColor Green
Write-Host "[DEBUG] URL: $supabaseUrl" -ForegroundColor Gray
Write-Host ""

# Headers
$headers = @{
    "apikey" = $supabaseKey
    "Authorization" = "Bearer $supabaseKey"
    "Content-Type" = "application/json"
}

# Cutoff Zeit (10 Minuten alt)
$cutoffTime = (Get-Date).AddMinutes(-10).ToUniversalTime()
Write-Host "Suche Items aelter als: $cutoffTime UTC" -ForegroundColor Yellow
Write-Host ""

# ALLE Items holen
Write-Host "Lade Items aus Queue..." -ForegroundColor Cyan

try {
    # Einfacher Invoke-WebRequest (zeigt mehr Details)
    $response = Invoke-WebRequest -Uri "$supabaseUrl/rest/v1/knowledge_harvest_queue?status=eq.processing&select=*" -Method GET -Headers $headers -UseBasicParsing
    
    Write-Host "[DEBUG] StatusCode: $($response.StatusCode)" -ForegroundColor Gray
    Write-Host "[DEBUG] Content Length: $($response.Content.Length)" -ForegroundColor Gray
    
    $allItems = $response.Content | ConvertFrom-Json
    
    if ($null -eq $allItems -or $allItems.Count -eq 0) {
        Write-Host "[INFO] Keine processing Items gefunden" -ForegroundColor Yellow
        exit 0
    }
    
    Write-Host "[OK] $($allItems.Count) processing Items geladen" -ForegroundColor Green
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
    if ($_.Exception.Response) {
        Write-Host "HTTP Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    }
    Write-Host "Full Error: $_" -ForegroundColor Red
    exit 1
}

# Filtern nach Zeit (in PowerShell statt URL)
$stuckItems = $allItems | Where-Object {
    $lastAttempt = [DateTime]::Parse($_.last_attempt_at)
    $lastAttempt -lt $cutoffTime
}

$stuckCount = ($stuckItems | Measure-Object).Count
Write-Host "Gefunden: $stuckCount haengende Items" -ForegroundColor Yellow
Write-Host ""

if ($stuckCount -eq 0) {
    Write-Host "[OK] Keine haengenden Items!" -ForegroundColor Green
    exit 0
}

# Verarbeiten
$resetCount = 0
$failedCount = 0

foreach ($item in $stuckItems) {
    $attempts = if ($item.attempts) { [int]$item.attempts } else { 0 }
    $maxRetries = 3
    
    Write-Host "---" -ForegroundColor Gray
    Write-Host "Topic: $($item.topic)" -ForegroundColor White
    Write-Host "Attempts: $attempts / $maxRetries" -ForegroundColor Cyan
    
    if ($attempts -ge $maxRetries) {
        # Nach failed_topics
        Write-Host "  -> failed_topics" -ForegroundColor Red
        
        $failedData = @{
            topic = $item.topic
            error_code = "timeout"
            error_message = "Stuck in processing >10min, attempts: $attempts"
            retry_count = $attempts
            status = "failed"
        } | ConvertTo-Json
        
        try {
            # Insert in failed_topics
            $failedUrl = $supabaseUrl + '/rest/v1/failed_topics'
            Invoke-RestMethod -Uri $failedUrl -Method POST -Headers $headers -Body $failedData -ContentType 'application/json' | Out-Null
            
            # Update queue status
            $updateUrl = $supabaseUrl + '/rest/v1/knowledge_harvest_queue?id=eq.' + $item.id
            $updateData = @{
                status = "failed"
                error_message = "Failed after $attempts attempts"
            } | ConvertTo-Json
            Invoke-RestMethod -Uri $updateUrl -Method PATCH -Headers $headers -Body $updateData -ContentType 'application/json' | Out-Null
            
            Write-Host "  [OK] Gespeichert" -ForegroundColor Green
            $failedCount++
        } catch {
            Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
        }
        
    } else {
        # Zurueck auf pending
        Write-Host "  -> pending (retry)" -ForegroundColor Yellow
        
        $updateUrl = $supabaseUrl + '/rest/v1/knowledge_harvest_queue?id=eq.' + $item.id
        $updateData = @{
            status = "pending"
            error_message = "Reset from stuck state"
        } | ConvertTo-Json
        
        try {
            Invoke-RestMethod -Uri $updateUrl -Method PATCH -Headers $headers -Body $updateData -ContentType 'application/json' | Out-Null
            Write-Host "  [OK] Zurueckgesetzt" -ForegroundColor Green
            $resetCount++
        } catch {
            Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  CLEANUP ABGESCHLOSSEN" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Pending: $resetCount" -ForegroundColor Yellow
Write-Host "Failed: $failedCount" -ForegroundColor Red
Write-Host ""
