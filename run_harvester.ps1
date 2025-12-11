# SICHER: Lade Keys aus .env oder env.json
$envFilePath = ".\.env"
$envJsonPath = ".\env.json"

if (Test-Path $envJsonPath) {
    # Lade aus env.json
    $envData = Get-Content $envJsonPath | ConvertFrom-Json
    $supabaseUrl = $envData.SUPABASE_URL
    $authToken = $envData.SUPABASE_ANON_KEY
    Write-Host "✅ Keys aus env.json geladen" -ForegroundColor Green
} elseif (Test-Path $envFilePath) {
    # Lade aus .env
    Get-Content $envFilePath | ForEach-Object {
        if ($_ -match '^SUPABASE_URL=(.+)$') {
            $supabaseUrl = $matches[1]
        }
        if ($_ -match '^SUPABASE_ANON_KEY=(.+)$') {
            $authToken = $matches[1]
        }
    }
    Write-Host "✅ Keys aus .env geladen" -ForegroundColor Green
} else {
    Write-Host "❌ FEHLER: Keine .env oder env.json gefunden!" -ForegroundColor Red
    Write-Host "Erstelle eine dieser Dateien mit SUPABASE_URL und SUPABASE_ANON_KEY" -ForegroundColor Yellow
    exit 1
}

$functionUrl = "$supabaseUrl/functions/v1/auto-knowledge-harvester"

# Wie oft soll der Harvester laufen?
$iterations = 30

# Pause zwischen den Läufen (Sekunden)
$delaySeconds = 60

# Success und Error Count
$successCount = 0
$errorCount = 0

$headers = @{
    "Authorization" = "Bearer $authToken"
    "Content-Type"  = "application/json"
}

for ($i = 1; $i -le $iterations; $i++) {
    Write-Host "Starte Harvester Lauf $i von $iterations ..." -ForegroundColor Cyan

    try {
        $response = Invoke-WebRequest -Uri $functionUrl -Method POST -Headers $headers -UseBasicParsing
        Write-Host "✅ StatusCode: $($response.StatusCode)" -ForegroundColor Green
        Write-Host "Body: $($response.Content)" -ForegroundColor DarkGray
        $successCount++
    }
    catch {
        Write-Host "❌ Fehler beim Aufruf des Harvesters:" -ForegroundColor Red
        Write-Host $_ -ForegroundColor Red
        $errorCount++
    }

    if ($i -lt $iterations) {
        Write-Host "Warte $delaySeconds Sekunden..." -ForegroundColor Yellow
        Start-Sleep -Seconds $delaySeconds
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "📊 HARVESTER ZUSAMMENFASSUNG" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Erfolgreich: $successCount / $iterations" -ForegroundColor Green
Write-Host "❌ Fehlgeschlagen: $errorCount / $iterations" -ForegroundColor Red
$successRate = [math]::Round(($successCount / $iterations) * 100, 1)
Write-Host "📈 Erfolgsrate: $successRate%" -ForegroundColor $(if($successRate -gt 70) {"Green"} else {"Yellow"})
Write-Host "`n💡 HINWEIS: Fehlgeschlagene Topics werden automatisch 3x wiederholt!" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan
