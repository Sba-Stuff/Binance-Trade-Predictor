@echo off
echo ========================================
echo Step 1: Fetching BTC data from Binance...
echo ========================================
powershell -ExecutionPolicy Bypass -File fetch_data.ps1
if errorlevel 1 (
    echo ERROR: Failed to fetch data
    pause
    exit /b 1
)

echo.
echo ========================================
echo Step 2: Analyzing data...
echo ========================================
powershell -ExecutionPolicy Bypass -File analyze.ps1

echo.
echo ========================================
echo Step 3: Backtesting strategy...
echo ========================================
powershell -ExecutionPolicy Bypass -File backtest.ps1

echo.
echo ========================================
echo All done!
echo ========================================
pause