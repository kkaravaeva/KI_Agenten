@echo off
cd /d "C:\Users\alxbe\Documents\DHBW\Kurse\Studienarbeit\KI_Agenten"
"C:\Users\alxbe\KI_Agent\.venv\Scripts\python.exe" -m mlagents.trainers.learn "config\model_comparison.yaml" --run-id model_comparison_v2 --base-port 5004 --results-dir "results" > trainer_output.log 2>&1
echo ExitCode: %ERRORLEVEL% >> trainer_output.log
