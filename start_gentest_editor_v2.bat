@echo off
chcp 65001 >nul
REM ============================================================================
REM  Generalisierungstest LIVE im Unity-Editor zuschauen (v2-Modelle, ~16,6M)
REM
REM  Startet den Trainer im Inferenz-Modus (Python-Inferenz fuer alle 3 Behaviors
REM  inkl. Transformer) und wartet dann auf Unity. Keine Lern-Updates.
REM
REM  ABLAUF:
REM   1. In Unity einmalig das Menue ausfuehren:
REM        Training / Generalisierungstest: Editor-Ansicht vorbereiten (Python-Inferenz)
REM   2. Diese .bat doppelklicken (wartet auf Unity).
REM   3. In Unity die Szene "Generalization Test" oeffnen und Play druecken.
REM        -> alle drei Behaviors laufen mit ihren v2-Gewichten (~16,6M Steps).
REM
REM  Kamera im Play-Modus: [0]/[Tab] Uebersicht, [1-3] Top-Down LSTM/Transformer/MLP,
REM  [4-6] POV LSTM/Transformer/MLP.
REM ============================================================================
setlocal
set HERE=%~dp0

REM --- venv-Python automatisch finden (portabel) ---
set PY=
if exist "C:\Users\alxbe\KI_Agent\.venv\Scripts\python.exe" set PY="C:\Users\alxbe\KI_Agent\.venv\Scripts\python.exe"
if exist "%HERE%venv\Scripts\python.exe" set PY="%HERE%venv\Scripts\python.exe"
if exist "C:\Users\Finnl\mlagents-31008\Scripts\python.exe" set PY="C:\Users\Finnl\mlagents-31008\Scripts\python.exe"
if not defined PY ( echo FEHLER: Keine mlagents-venv gefunden - Pfad in dieser .bat anpassen. & pause & exit /b 1 )

echo Verwende Python: %PY%
echo Warte auf Unity (Play in Szene "Generalization Test" druecken)...

%PY% -m mlagents.trainers.learn "%HERE%config\model_comparison_final_v2.yaml" ^
    --run-id model_comparison_final_v2 ^
    --inference --resume --base-port 5004

pause
