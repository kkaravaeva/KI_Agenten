@echo off
title [TRAINER] ML-Agents Editor-Training v5
cd /d "%~dp0"

REM --- venv-Python automatisch finden (portabel: Laptop oder Desktop) ---
set PY=
if exist "C:\Users\Finnl\mlagents-31008\Scripts\python.exe" set PY="C:\Users\Finnl\mlagents-31008\Scripts\python.exe"
if exist "C:\Users\alxbe\KI_Agent\.venv\Scripts\python.exe" set PY="C:\Users\alxbe\KI_Agent\.venv\Scripts\python.exe"
if not defined PY ( echo FEHLER: Keine mlagents-venv gefunden - Pfad in dieser .bat anpassen. & pause & exit /b 1 )
set CFG=config\model_comparison_final_v3.yaml
set RUN_ID=model_comparison_final_v3
set TIME_SCALE=10
set LOGDIR=trainer_logs
set LOGFILE=%LOGDIR%\%RUN_ID%.log

if not exist "%LOGDIR%" mkdir "%LOGDIR%"

:loop
echo.
echo ============================================================
echo  Trainer startet und WARTET auf Unity:
echo  In Unity die Szene "Training Area" oeffnen und PLAY druecken!
echo ============================================================
echo.
echo ============================================================ >> "%LOGFILE%"
echo [%DATE% %TIME%] Starte Editor-Trainer (time-scale %TIME_SCALE%)... >> "%LOGFILE%"

if exist "results\%RUN_ID%\LSTM_Navigator\checkpoint.pt" (
    echo [%DATE% %TIME%] Checkpoint gefunden - Resume...
    %PY% -m mlagents.trainers.learn "%CFG%" ^
         --run-id %RUN_ID% ^
         --results-dir "results" ^
         --num-envs 1 ^
         --time-scale %TIME_SCALE% ^
         --timeout-wait 300 ^
         --resume >> "%LOGFILE%" 2>&1
) else (
    echo [%DATE% %TIME%] Kein Checkpoint - Frischer Start...
    %PY% -m mlagents.trainers.learn "%CFG%" ^
         --run-id %RUN_ID% ^
         --results-dir "results" ^
         --num-envs 1 ^
         --time-scale %TIME_SCALE% ^
         --timeout-wait 300 >> "%LOGFILE%" 2>&1
)

echo [%DATE% %TIME%] Trainer beendet (Exit: %ERRORLEVEL%). >> "%LOGFILE%"
echo.
echo Trainer beendet. Neustart in 10s â€” dann in Unity wieder PLAY druecken...
timeout /t 10 /nobreak >nul
goto loop
