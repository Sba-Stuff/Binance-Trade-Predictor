$data = Get-Content "btc_data.json" -Raw | ConvertFrom-Json
$signals = Get-Content "signals.json" -Raw | ConvertFrom-Json

if ($signals.Count -eq 0) {
    Write-Host "No signals found. Run analyze.ps1 first." -ForegroundColor Red
    exit
}

Write-Host "Backtesting strategy on $($signals.Count) signals..." -ForegroundColor Yellow

$balance = 10000
$btcHeld = 0
$trades = @()
$inPosition = $false
$entryPrice = 0

for ($i = 0; $i -lt $signals.Count - 1; $i++) {
    $currentSignal = $signals[$i]
    $nextPrice = $signals[$i+1].Price
    
    if ($currentSignal.Signal -eq "BUY" -and -not $inPosition) {
        $btcHeld = $balance / $currentSignal.Price
        $entryPrice = $currentSignal.Price
        $balance = 0
        $inPosition = $true
        
        $trades += [PSCustomObject]@{
            Date = $currentSignal.Timestamp
            Type = "BUY"
            Price = $currentSignal.Price
            Balance = $balance
            BTC = [math]::Round($btcHeld, 8)
        }
        Write-Host "BUY at `$$($currentSignal.Price) on $($currentSignal.Timestamp)" -ForegroundColor Green
    }
    elseif ($currentSignal.Signal -eq "SELL" -and $inPosition) {
        $balance = $btcHeld * $currentSignal.Price
        $profit = (($currentSignal.Price - $entryPrice) / $entryPrice) * 100
        $btcHeld = 0
        $inPosition = $false
        
        $trades += [PSCustomObject]@{
            Date = $currentSignal.Timestamp
            Type = "SELL"
            Price = $currentSignal.Price
            Balance = [math]::Round($balance, 2)
            BTC = 0
        }
        Write-Host "SELL at `$$($currentSignal.Price) on $($currentSignal.Timestamp) (Profit: $([math]::Round($profit, 2))%)" -ForegroundColor Red
    }
}

if ($inPosition) {
    $balance = $btcHeld * $signals[-1].Price
    $trades += [PSCustomObject]@{
        Date = $signals[-1].Timestamp
        Type = "CLOSE"
        Price = $signals[-1].Price
        Balance = [math]::Round($balance, 2)
        BTC = 0
    }
    Write-Host "Closed position at `$$($signals[-1].Price) on $($signals[-1].Timestamp)" -ForegroundColor Yellow
}

$finalBalance = $balance
$buyAndHold = 10000 * ($signals[-1].Price / $signals[0].Price)
$totalReturn = (($finalBalance - 10000) / 10000) * 100
$buyHoldReturn = (($buyAndHold - 10000) / 10000) * 100

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "         BACKTEST RESULTS" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Initial Balance: `$10,000.00"
Write-Host "Final Balance:   `$$([math]::Round($finalBalance, 2))"
Write-Host "Total Return:    $([math]::Round($totalReturn, 2))%"
Write-Host "Buy and Hold:    $([math]::Round($buyHoldReturn, 2))%"
Write-Host "Total Trades:    $($trades.Count)"

if ($totalReturn -gt $buyHoldReturn) {
    $diff = $totalReturn - $buyHoldReturn
    Write-Host "Strategy BEAT Buy and Hold by $([math]::Round($diff, 2))%" -ForegroundColor Green
} else {
    $diff = $buyHoldReturn - $totalReturn
    Write-Host "Strategy UNDERPERFORMED Buy and Hold by $([math]::Round($diff, 2))%" -ForegroundColor Red
}

if ($trades.Count -gt 0) {
    $trades | Export-Csv -Path "trades.csv" -NoTypeInformation
    Write-Host "`nTrades saved to trades.csv" -ForegroundColor Gray
    
    Write-Host "`nTrade History:" -ForegroundColor Yellow
    $trades | Format-Table -AutoSize
}