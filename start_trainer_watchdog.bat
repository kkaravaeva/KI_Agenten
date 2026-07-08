@echo off
title ML-Agents Watchdog v3 (auto-restart)
cd /d "C:\Users\alxbe\Documents\DHBW\Kurse\Studienarbeit\KI_Agenten"

:loop
echo [%TIME%] Starte Trainer (model_comparison_v3, time-scale 20)...
"C:\Users\alxbe\KI_Agent\.venv\Scripts\python.exe" -m mlagents.trainers.learn "config\model_comparison.yaml" --run-id model_comparison_v3 --base-port 5004 --results-dir "results" --timeout-wait 120 --time-scale 20
echo [%TIME%] Trainer beendet (Exit: %ERRORLEVEL%). Neustart in 5 Sekunden...
echo Strg+C druecken um zu stoppen.
timeout /t 5 /nobreak
goto loop
