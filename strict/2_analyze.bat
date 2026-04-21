@echo off
echo Analyzing data and generating signals...
powershell -ExecutionPolicy Bypass -File analyze.ps1
echo Done.
pause
