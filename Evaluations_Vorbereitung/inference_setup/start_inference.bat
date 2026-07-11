@echo off
chcp 65001 >nul
REM ============================================================
REM  Finale final_v3-Modelle im Inference-Modus laufen lassen
REM  (MLP + LSTM + Transformer gleichzeitig, keine Lern-Updates)
REM
REM  Ablauf:
REM   1. Diese Datei doppelklicken (wartet dann auf Unity)
REM   2. In Unity die Szene "Training Area" öffnen und Play drücken
REM      -> alle drei Behaviors laufen mit ihren 30M-Gewichten
REM
REM  Alternative ohne Editor: die untere Zeile mit --env verwenden
REM  (Standalone-Build, sichtbar, keine --no-graphics-Option setzen)
REM ============================================================
setlocal
set VENV_PY=C:\Users\Finnl\mlagents-31008\Scripts\python.exe
set HERE=%~dp0

"%VENV_PY%" -m mlagents.trainers.learn "%HERE%model_comparison_final_v3.yaml" --run-id model_comparison_final_v3 --results-dir "%HERE%results" --inference --resume --base-port 5004

REM Variante mit Standalone-Build statt Editor (einkommentieren bei Bedarf):
REM "%VENV_PY%" -m mlagents.trainers.learn "%HERE%model_comparison_final_v3.yaml" --run-id model_comparison_final_v3 --results-dir "%HERE%results" --inference --resume --base-port 5004 --env "%HERE%..\..\Build\KI_Agenten.exe" --num-envs 1 --time-scale 1

pause
