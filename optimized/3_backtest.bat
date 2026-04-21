@echo off
echo Backtesting strategy...
powershell -ExecutionPolicy Bypass -File backtest.ps1
echo Done.
pause
