$signals = Get-Content "signals_tuned.json" -Raw | ConvertFrom-Json

Write-Host "Backtesting TUNED strategy..." -ForegroundColor Yellow

$balance = 10000
$btcHeld = 0
$trades = @()
$inPosition = $false
$entryPrice = 0
$entryDate = $null

for ($i = 0; $i -lt $signals.Count - 1; $i++) {
    $currentSignal = $signals[$i]
    
    if ($currentSignal.Signal -eq "BUY" -and -not $inPosition) {
        $btcHeld = $balance / $currentSignal.Price
        $entryPrice = $currentSignal.Price
        $entryDate = $currentSignal.Timestamp
        $balance = 0
        $inPosition = $true
        
        $trades += [PSCustomObject]@{
            EntryDate = $entryDate
            EntryPrice = $entryPrice
        }
        Write-Host "BUY at `$$($currentSignal.Price) on $($currentSignal.Timestamp)" -ForegroundColor Green
    }
    elseif ($currentSignal.Signal -eq "SELL" -and $inPosition) {
        $balance = $btcHeld * $currentSignal.Price
        $profit = (($currentSignal.Price - $entryPrice) / $entryPrice) * 100
        $exitDate = $currentSignal.Timestamp
        $btcHeld = 0
        $inPosition = $false
        
        $trades[-1] | Add-Member -NotePropertyName "ExitDate" -NotePropertyValue $exitDate -Force
        $trades[-1] | Add-Member -NotePropertyName "ExitPrice" -NotePropertyValue $currentSignal.Price -Force
        $trades[-1] | Add-Member -NotePropertyName "Profit" -NotePropertyValue ([math]::Round($profit, 2)) -Force
        $trades[-1] | Add-Member -NotePropertyName "HeldHours" -NotePropertyValue ([math]::Round((($exitDate - $entryDate).TotalHours), 1)) -Force
        
        if ($profit -gt 0) {
            Write-Host "SELL at `$$($currentSignal.Price) on $exitDate - PROFIT: $([math]::Round($profit, 2))%" -ForegroundColor Green
        } else {
            Write-Host "SELL at `$$($currentSignal.Price) on $exitDate - LOSS: $([math]::Round($profit, 2))%" -ForegroundColor Red
        }
    }
}

if ($inPosition) {
    $balance = $btcHeld * $signals[-1].Price
    $profit = (($signals[-1].Price - $entryPrice) / $entryPrice) * 100
    $trades[-1] | Add-Member -NotePropertyName "ExitDate" -NotePropertyValue $signals[-1].Timestamp -Force
    $trades[-1] | Add-Member -NotePropertyName "ExitPrice" -NotePropertyValue $signals[-1].Price -Force
    $trades[-1] | Add-Member -NotePropertyName "Profit" -NotePropertyValue ([math]::Round($profit, 2)) -Force
    $trades[-1] | Add-Member -NotePropertyName "HeldHours" -NotePropertyValue ([math]::Round((($signals[-1].Timestamp - $entryDate).TotalHours), 1)) -Force
}

$finalBalance = $balance
$buyAndHold = 10000 * ($signals[-1].Price / $signals[0].Price)
$totalReturn = (($finalBalance - 10000) / 10000) * 100
$buyHoldReturn = (($buyAndHold - 10000) / 10000) * 100

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "         TUNED STRATEGY RESULTS" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Initial Balance: `$10,000.00"
Write-Host "Final Balance:   `$$([math]::Round($finalBalance, 2))"
Write-Host "Total Return:    $([math]::Round($totalReturn, 2))%"
Write-Host "Buy and Hold:    $([math]::Round($buyHoldReturn, 2))%"
Write-Host "Total Trades:    $($trades.Count)"

if ($totalReturn -gt $buyHoldReturn) {
    $diff = $totalReturn - $buyHoldReturn
    Write-Host "RESULT: BEAT Buy and Hold by $([math]::Round($diff, 2))%" -ForegroundColor Green
} else {
    $diff = $buyHoldReturn - $totalReturn
    Write-Host "RESULT: UNDERPERFORMED Buy and Hold by $([math]::Round($diff, 2))%" -ForegroundColor Red
}

if ($trades.Count -gt 0) {
    $winningTrades = ($trades | Where-Object { $_.Profit -gt 0 }).Count
    $losingTrades = ($trades | Where-Object { $_.Profit -lt 0 }).Count
    $avgWin = if ($winningTrades -gt 0) { ($trades | Where-Object { $_.Profit -gt 0 } | Measure-Object -Average Profit).Average } else { 0 }
    $avgLoss = if ($losingTrades -gt 0) { ($trades | Where-Object { $_.Profit -lt 0 } | Measure-Object -Average Profit).Average } else { 0 }
    $avgHoldTime = ($trades | Measure-Object -Average HeldHours).Average
    
    Write-Host "`nTrade Statistics:" -ForegroundColor Yellow
    Write-Host "  Winning Trades: $winningTrades"
    Write-Host "  Losing Trades:  $losingTrades"
    Write-Host "  Win Rate:       $([math]::Round(($winningTrades / ($winningTrades + $losingTrades)) * 100, 1))%"
    Write-Host "  Avg Win:        $([math]::Round($avgWin, 2))%"
    Write-Host "  Avg Loss:       $([math]::Round($avgLoss, 2))%"
    Write-Host "  Avg Hold Time:  $([math]::Round($avgHoldTime, 1)) hours"
    if ($avgLoss -ne 0) {
        $profitFactor = ($avgWin * $winningTrades) / ([math]::Abs($avgLoss) * $losingTrades)
        Write-Host "  Profit Factor:  $([math]::Round($profitFactor, 2))"
    }
    
    $trades | Export-Csv -Path "trades_tuned.csv" -NoTypeInformation
    Write-Host "`nTrades saved to trades_tuned.csv" -ForegroundColor Gray
    
    Write-Host "`nAll Trades:" -ForegroundColor Yellow
    $trades | Format-Table EntryDate, EntryPrice, ExitDate, ExitPrice, Profit, HeldHours -AutoSize
}