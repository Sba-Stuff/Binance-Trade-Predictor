@echo off
echo Running PowerShell script...

powershell -ExecutionPolicy Bypass -File create_dataset.ps1

echo Done.
pause