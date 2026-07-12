# Stoppt das v2-Training, sobald ALLE drei Envs ihren Hard-Block 5 abgeschlossen haben.
# Fertig-Kriterium je Env: Curriculum verlaesst Phase 7 (Loop-Ruecksprung) ODER Episode >= 20000.
# Danach: auf naechsten Checkpoint-Export warten (Hard-5-Ende sicher in den Gewichten),
# dann Watchdog-Baum beenden. Fortschritt wird zeilenweise gemeldet (Monitor-Events).

$ErrorActionPreference = "SilentlyContinue"
$ll      = "C:\Users\alxbe\AppData\LocalLow\DefaultCompany\KI Agenten"
$proj    = "C:\Users\alxbe\Documents\DHBW\Kurse\Studienarbeit\KI_Agenten"
$cpFile  = Join-Path $proj "results\model_comparison_final_v2\MLP_Navigator\checkpoint.pt"
$marker  = Join-Path $proj "results\model_comparison_final_v2\loop5_stop_protokoll.txt"
$done    = @{ 5004 = $false; 5005 = $false; 5006 = $false }

Add-Content $marker "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Waechter gestartet"

while ($true) {
    foreach ($p in 5004, 5005, 5006) {
        if ($done[$p]) { continue }
        $raw = Get-Content (Join-Path $ll "curriculum_state_$p.json") -Raw
        if (-not $raw) { continue }
        try { $j = $raw | ConvertFrom-Json } catch { continue }
        if ($j.phaseIndex -ne 7 -or $j.episodeCountInPhase -ge 20000) {
            $done[$p] = $true
            $msg = "ENV $p FERTIG: Hard-Block 5 abgeschlossen (Phase $($j.phaseIndex), Episode $($j.episodeCountInPhase)) um $(Get-Date -Format 'HH:mm:ss')"
            Write-Output $msg
            Add-Content $marker "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg"
        }
    }
    if (-not ($done.Values -contains $false)) { break }
    Start-Sleep 60
}

Write-Output "ALLE 3 ENVS FERTIG - warte auf naechsten Checkpoint-Export (max. 45 Min)..."
$t0 = (Get-Item $cpFile).LastWriteTime
$deadline = (Get-Date).AddMinutes(45)
while ((Get-Item $cpFile).LastWriteTime -eq $t0 -and (Get-Date) -lt $deadline) { Start-Sleep 30 }
Write-Output "Checkpoint exportiert ($((Get-Item $cpFile).LastWriteTime.ToString('HH:mm:ss'))) - stoppe Training..."

$wd = Get-CimInstance Win32_Process -Filter "Name='cmd.exe'" | Where-Object { $_.CommandLine -match 'start_trainer_standalone' }
foreach ($proc in $wd) { taskkill /PID $proc.ProcessId /T /F | Out-Null }
Start-Sleep 5
$rest = (Get-CimInstance Win32_Process -Filter "Name='python.exe'" | Where-Object { $_.CommandLine -match 'mlagents.trainers' } | Measure-Object).Count
$lastStep = (Select-String -Path (Join-Path $proj "trainer_logs\model_comparison_final_v2.log") -Pattern 'Step: (\d+)' | Select-Object -Last 1).Matches[0].Groups[1].Value
$msg = "TRAINING GESTOPPT bei Step ~$lastStep (verbleibende Trainer-Prozesse: $rest)"
Write-Output $msg
Add-Content $marker "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg"
