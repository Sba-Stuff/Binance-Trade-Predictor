@echo off
echo Fetching BTC data from Binance...
powershell -ExecutionPolicy Bypass -File fetch_data.ps1
echo Done.
pause
