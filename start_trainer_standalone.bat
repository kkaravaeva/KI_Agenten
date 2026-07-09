@echo off
title [TRAINER] ML-Agents Standalone v4
cd /d "C:\Users\alxbe\Documents\DHBW\Kurse\Studienarbeit\KI_Agenten"

set BUILD=Build\KI_Agenten.exe
set PY="C:\Users\alxbe\KI_Agent\.venv\Scripts\python.exe"
set CFG=config\model_comparison_final_v2.yaml
set RUN_ID=model_comparison_final_v2
set LOGDIR=trainer_logs
set LOGFILE=%LOGDIR%\%RUN_ID%.log

if not exist "%BUILD%" (
    echo FEHLER: Build nicht gefunden.
    pause & exit /b 1
)
if not exist "%LOGDIR%" mkdir "%LOGDIR%"

:loop
echo [%DATE% %TIME%] Starte Trainer...
echo ============================================================ >> "%LOGFILE%"
echo [%DATE% %TIME%] Starte Trainer... >> "%LOGFILE%"

if exist "results\%RUN_ID%\LSTM_Navigator\checkpoint.pt" (
    echo [%DATE% %TIME%] Checkpoint gefunden - Resume...
    echo [%DATE% %TIME%] Checkpoint gefunden - Resume... >> "%LOGFILE%"
    %PY% -m mlagents.trainers.learn "%CFG%" ^
         --run-id %RUN_ID% ^
         --env "%BUILD%" ^
         --base-port 5004 ^
         --results-dir "results" ^
         --num-envs 3 ^
         --no-graphics ^
         --time-scale 40 ^
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
         --num-envs 3 ^
         --no-graphics ^
         --time-scale 40 ^
         --timeout-wait 120 >> "%LOGFILE%" 2>&1
)

echo [%DATE% %TIME%] Trainer beendet (Exit: %ERRORLEVEL%). Neustart in 30s...
echo [%DATE% %TIME%] Trainer beendet (Exit: %ERRORLEVEL%). >> "%LOGFILE%"
timeout /t 30 /nobreak >nul
goto loop
