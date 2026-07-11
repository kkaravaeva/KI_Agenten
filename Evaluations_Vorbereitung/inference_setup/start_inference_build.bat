@echo off
chcp 65001 >nul
REM ============================================================
REM  Ein-Klick-Variante OHNE Unity-Editor:
REM  Startet den Standalone-Build sichtbar (1 Instanz, Echtzeit)
REM  und lässt alle drei finalen Modelle im Inference-Modus laufen.
REM
REM  Voraussetzung: Build\KI_Agenten.exe existiert im Projekt
REM  (sonst Runbook Schritt 3: StandaloneBuild.BuildFromCommandLine)
REM ============================================================
setlocal
set VENV_PY=C:\Users\Finnl\mlagents-31008\Scripts\python.exe
set HERE=%~dp0

"%VENV_PY%" -m mlagents.trainers.learn "%HERE%model_comparison_final_v3.yaml" --run-id model_comparison_final_v3 --results-dir "%HERE%results" --inference --resume --base-port 5005 --env "%HERE%..\..\Build\KI_Agenten.exe" --num-envs 1 --time-scale 1

pause
