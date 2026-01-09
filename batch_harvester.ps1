# ============================================================================
# Batch Harvester - Starte mehrere Harvester parallel
# ============================================================================

param(
    [int]$Count = 5  # Wie viele Items parallel harvesten
)

$envPath = Join-Path $PSScriptRoot "env.json"
$env = Get-Content $envPath | ConvertFrom-Json
$supabaseUrl = $env.SUPABASE_URL
$supabaseKey = $env.SUPABASE_ANON_KEY

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  BATCH HARVESTER" -ForegroundColor Cyan
Write-Host "  Starte $Count parallele Harvester" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$jobs = @()

# Starte mehrere Harvester parallel
for ($i = 1; $i -le $Count; $i++) {
    Write-Host "[$i/$Count] Starte Harvester..." -ForegroundColor Yellow
    
    $job = Start-Job -ScriptBlock {
        param($url, $key, $index)
        
        $headers = @{
            "Authorization" = "Bearer $key"
            "Content-Type" = "application/json"
        }
        
        try {
            $response = Invoke-RestMethod `
                -Uri "$url/functions/v1/auto-knowledge-harvester" `
                -Method POST `
                -Headers $headers `
                -Body '{}' `
                -TimeoutSec 300
            
            return @{
                Index = $index
                Success = $true
                Response = $response
            }
        } catch {
            return @{
                Index = $index
                Success = $false
                Error = $_.Exception.Message
            }
        }
    } -ArgumentList $supabaseUrl, $supabaseKey, $i
    
    $jobs += $job
    
    # Kurze Pause zwischen Starts
    Start-Sleep -Seconds 2
}

Write-Host ""
Write-Host "Warte auf Abschluss..." -ForegroundColor Cyan
Write-Host ""

# Warte auf alle Jobs
$completed = 0
while ($completed -lt $Count) {
    $completed = ($jobs | Where-Object { $_.State -ne 'Running' }).Count
    Write-Host "`rFertig: $completed / $Count" -NoNewline -ForegroundColor Yellow
    Start-Sleep -Seconds 5
}

Write-Host ""
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ERGEBNISSE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Zeige Ergebnisse
foreach ($job in $jobs) {
    $result = Receive-Job -Job $job
    
    if ($result.Success) {
        Write-Host "[Harvester $($result.Index)] ERFOLG" -ForegroundColor Green
    } else {
        Write-Host "[Harvester $($result.Index)] FEHLER: $($result.Error)" -ForegroundColor Red
    }
}

# Cleanup
$jobs | Remove-Job

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Batch-Harvest abgeschlossen!" -ForegroundColor Green
Write-Host ""
