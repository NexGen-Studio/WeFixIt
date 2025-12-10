$functionUrl = "https://zbrlhswafnlpfwqikapu.supabase.co/functions/v1/auto-knowledge-harvester"
$authToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"

# Wie oft soll der Harvester laufen?
$iterations = 30

# Pause zwischen den Läufen (Sekunden)
$delaySeconds = 30

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
