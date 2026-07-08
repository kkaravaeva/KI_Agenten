@echo off
title Unity Standalone Build
cd /d "C:\Users\alxbe\Documents\DHBW\Kurse\Studienarbeit\KI_Agenten"

echo [%TIME%] Starte Unity Build (batchmode)...
echo Bitte warten - das dauert 2-5 Minuten.
echo.

"C:\Program Files\Unity\Hub\Editor\6000.2.6f1\Editor\Unity.exe" ^
  -quit ^
  -batchmode ^
  -projectPath "%CD%" ^
  -executeMethod StandaloneBuild.BuildFromCommandLine ^
  -logFile build_log.txt

echo.
if exist "Build\KI_Agenten.exe" (
    echo [OK] Build erfolgreich: Build\KI_Agenten.exe
    echo Starte jetzt das Overnight-Training...
    start "" "%CD%\start_trainer_standalone.bat"
) else (
    echo [FEHLER] Build fehlgeschlagen - siehe build_log.txt
    pause
)
