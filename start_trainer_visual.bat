@echo off
title [TRAINER] ML-Agents Visual v5 (mit Fenster)
cd /d "%~dp0"

set BUILD=Build\KI_Agenten.exe
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

if not exist "%BUILD%" (
    echo FEHLER: Build nicht gefunden.
    pause & exit /b 1
)
if not exist "%LOGDIR%" mkdir "%LOGDIR%"

:loop
echo [%DATE% %TIME%] Starte Trainer (sichtbar, time-scale %TIME_SCALE%)...
echo ============================================================ >> "%LOGFILE%"
echo [%DATE% %TIME%] Starte Trainer (visual, time-scale %TIME_SCALE%)... >> "%LOGFILE%"

if exist "results\%RUN_ID%\LSTM_Navigator\checkpoint.pt" (
    echo [%DATE% %TIME%] Checkpoint gefunden - Resume...
    echo [%DATE% %TIME%] Checkpoint gefunden - Resume... >> "%LOGFILE%"
    %PY% -m mlagents.trainers.learn "%CFG%" ^
         --run-id %RUN_ID% ^
         --env "%BUILD%" ^
         --base-port 5004 ^
         --results-dir "results" ^
         --num-envs 1 ^
         --time-scale %TIME_SCALE% ^
         --timeout-wait 120 ^
         --resume >> "%LOGFILE%" 2>&1
) else (
    echo [%DATE% %TIME%] Kein Checkpoint - Frischer Start...
    echo [%DATE% %TIME%] Kein Checkpoint - Frischer Start... >> "%LOGFILE%"
    %PY% -m mlagents.trainers.learn "%CFG%" ^
         --run-id %RUN_ID% ^
         --env "%BUILD%" ^
         --base-port 5004 ^
         --results-dir "results" ^
         --num-envs 1 ^
         --time-scale %TIME_SCALE% ^
         --timeout-wait 120 >> "%LOGFILE%" 2>&1
)

echo [%DATE% %TIME%] Trainer beendet (Exit: %ERRORLEVEL%). Neustart in 30s...
echo [%DATE% %TIME%] Trainer beendet (Exit: %ERRORLEVEL%). >> "%LOGFILE%"
timeout /t 30 /nobreak >nul
goto loop
