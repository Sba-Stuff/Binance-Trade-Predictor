# Save as: realtime_monitor.ps1
Write-Host "BTC Real-Time Monitor (Press Ctrl+C to stop)" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

while ($true) {
    Clear-Host
    Write-Host "BTCUSDT Live Monitor - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    
    # Fetch last 50 candles
    $url = "https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=1h&limit=50"
    $data = Invoke-RestMethod -Uri $url
    
    $currentPrice = [double]$data[-1][4]
    $priceChange1h = (($currentPrice - [double]$data[-2][4]) / [double]$data[-2][4]) * 100
    
    # Calculate MA7 and MA25
    $ma7 = ($data[-7..-1] | ForEach-Object { [double]$_[4] } | Measure-Object -Average).Average
    $ma25 = ($data[-25..-1] | ForEach-Object { [double]$_[4] } | Measure-Object -Average).Average
    
    # Calculate RSI
    $gains = @()
    $losses = @()
    for ($j = $data.Count-15; $j -lt $data.Count; $j++) {
        $change = [double]$data[$j][4] - [double]$data[$j-1][4]
        if ($change -gt 0) { $gains += $change; $losses += 0 }
        else { $gains += 0; $losses += -$change }
    }
    $avgGain = ($gains | Measure-Object -Average).Average
    $avgLoss = ($losses | Measure-Object -Average).Average
    $rs = if ($avgLoss -eq 0) { 100 } else { $avgGain / $avgLoss }
    $rsi = [math]::Round(100 - (100 / (1 + $rs)))
    
    # Generate signal
    $signal = "HOLD"
    $score = 0
    if ($ma7 -gt $ma25) { $score += 2 }
    if ($ma7 -lt $ma25) { $score -= 2 }
    if ($rsi -lt 30) { $score += 2 }
    if ($rsi -gt 70) { $score -= 2 }
    if ($score -ge 2) { $signal = "BUY" }
    if ($score -le -2) { $signal = "SELL" }
    
    # Color based on signal
    $signalColor = "White"
    if ($signal -eq "BUY") { $signalColor = "Green" }
    if ($signal -eq "SELL") { $signalColor = "Red" }
    
    Write-Host "`nCurrent Price: `$$currentPrice" -ForegroundColor Yellow
    Write-Host "24h Change:    $([math]::Round($priceChange1h, 2))%" -ForegroundColor $(if($priceChange1h -gt 0){"Green"}else{"Red"})
    Write-Host "MA7:           `$$([math]::Round($ma7, 2))"
    Write-Host "MA25:          `$$([math]::Round($ma25, 2))"
    Write-Host "RSI:           $rsi" -ForegroundColor $(if($rsi -gt 70){"Red"}elseif($rsi -lt 30){"Green"}else{"Gray"})
    Write-Host "`nSIGNAL:        $signal" -ForegroundColor $signalColor
    
    Start-Sleep -Seconds 60  # Update every minute
}