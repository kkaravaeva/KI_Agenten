# Wächter für den Generalisierungstest mit Finns 30M-Modellen.
# Sichert die CSV sofort bei Abschluss (2326 Zeilen = 155*5*3 + Header)
# und beendet Trainer + Player, bevor der mlagents-Auto-Restart die CSV
# überschreibt. Meldet Fortschritt/Abschluss als Monitor-Events (stdout).

$ErrorActionPreference = "SilentlyContinue"
$proj   = "C:\Users\alxbe\Documents\DHBW\Kurse\Studienarbeit\KI_Agenten"
$csvSrc = Join-Path $proj "Build_Gen\results\generalization\generalization_results.csv"
$csvDst = Join-Path $proj "results\generalization\generalization_results_finn_v3.csv"
$plog   = Join-Path $proj "results\finn_v3_gentest\run_logs\Player-0.log"
$EXPECT = 2326

# Startzeitpunkt merken, damit wir NICHT die alte v2-CSV fälschlich sichern
$startTicks = (Get-Date).Ticks
while ($true) {
    if (Test-Path $csvSrc) {
        $f = Get-Item $csvSrc
        if ($f.LastWriteTime.Ticks -gt $startTicks) {
            $lines = (Get-Content $csvSrc | Measure-Object -Line).Lines
            if ($lines -ge $EXPECT) { break }
        }
    }
    # Fortschrittsmeldung (alle ~10 Maps)
    $prog = Select-String -Path $plog -Pattern 'Map (30|60|90|120|150)/155' -EA SilentlyContinue | Select-Object -Last 1
    if ($prog -and $prog.Line -ne $lastProg) { Write-Output $prog.Line.Trim(); $lastProg = $prog.Line }
    # Fehler melden
    $err = (Select-String -Path $plog -Pattern 'Exception|CUDA' -EA SilentlyContinue | Measure-Object).Count
    if ($err -gt $lastErr) { Write-Output "WARNUNG: $err Exceptions im Player-Log"; $lastErr = $err }
    Start-Sleep 45
}

# Abschluss: CSV sofort sichern, dann Prozesse killen
Copy-Item $csvSrc $csvDst -Force
$secured = (Get-Content $csvDst | Measure-Object -Line).Lines
Get-Process KI_Agenten_GenTest -EA SilentlyContinue | Stop-Process -Force
Get-CimInstance Win32_Process -Filter "Name='python.exe'" |
    Where-Object { $_.CommandLine -match 'finn_v3_gentest' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
Write-Output "TEST ABGESCHLOSSEN - CSV gesichert ($secured Zeilen) nach generalization_results_finn_v3.csv, Prozesse beendet"
