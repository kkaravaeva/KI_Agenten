# setup_and_export.ps1
# Einmaliges Setup der mlagents-Umgebung + ONNX-Export des V24 Transformer-Modells.
# Ausfuehren: .\training\setup_and_export.ps1
# (aus dem KI_Agenten-Projektordner)

$ErrorActionPreference = "Stop"
$ProjectDir = Split-Path -Parent $PSScriptRoot  # KI_Agenten/
$VenvDir    = "$ProjectDir\training\venv_mlagents"

# ── 1. Venv anlegen (nur einmalig) ────────────────────────────────────────────
if (-not (Test-Path "$VenvDir\Scripts\python.exe")) {
    Write-Host "=== Erstelle Python-Venv unter $VenvDir ===" -ForegroundColor Cyan
    python -m venv $VenvDir
} else {
    Write-Host "=== Venv existiert bereits ($VenvDir) ===" -ForegroundColor Green
}

$Python = "$VenvDir\Scripts\python.exe"
$Pip    = "$VenvDir\Scripts\pip.exe"

# ── 2. mlagents 0.30.0 installieren ──────────────────────────────────────────
$installed = & $Pip show mlagents 2>&1
if ($installed -notmatch "Version: 0.30") {
    Write-Host "=== Installiere mlagents 0.30.0 ===" -ForegroundColor Cyan
    # torch 1.8.x ist kompatibel; torch 2.x funktioniert meist auch mit Python 3.10
    & $Pip install torch==1.8.1+cpu torchvision==0.9.1+cpu -f https://download.pytorch.org/whl/torch_stable.html
    & $Pip install mlagents==0.30.0 protobuf==3.20.3
    & $Pip install onnx==1.13.0
    Write-Host "=== Installation abgeschlossen ===" -ForegroundColor Green
} else {
    Write-Host "=== mlagents 0.30.0 bereits installiert ===" -ForegroundColor Green
}

# ── 3. Transformer-Patch anwenden ─────────────────────────────────────────────
Write-Host "=== Wende Transformer-Patch an ===" -ForegroundColor Cyan
& $Python training\patch_mlagents.py $VenvDir

Write-Host ""
Write-Host "=== SETUP ABGESCHLOSSEN ===" -ForegroundColor Green
Write-Host ""
Write-Host "Naechste Schritte:" -ForegroundColor Yellow
Write-Host "  ONNX exportieren (Methode B):" -ForegroundColor White
Write-Host "    1. Unity-Szene oeffnen und Play druecken"
Write-Host "    2. In neuem Terminal ausfuehren:"
Write-Host "       $Python -m mlagents.trainers.learn V24_Paket/results/v24/config_export.yaml --run-id=v24"
Write-Host "    3. Nach 'Listening on port 5005': Play in Unity druecken"
Write-Host "    4. mlagents exportiert ONNX und beendet sich automatisch"
Write-Host "    5. ONNX patchen: $Python training\fix_onnx_batch.py V24_Paket\results\v24\LabyrinthNavigator\LabyrinthNavigator.onnx"
Write-Host ""
Write-Host "  Inference (Methode A, kein ONNX noetig):" -ForegroundColor White
Write-Host "    $Python -m mlagents.trainers.learn V24_Paket/results/v24/configuration.yaml --run-id=v24 --resume --inference"
Write-Host "    -> Dann Play in Unity druecken"
