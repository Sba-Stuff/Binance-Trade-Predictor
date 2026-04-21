$data = Get-Content "btc_data.json" -Raw | ConvertFrom-Json

Write-Host "Analyzing $($data.Count) candles..." -ForegroundColor Yellow

$results = @()

for ($i = 30; $i -lt $data.Count; $i++) {
    $current = $data[$i]
    $currentPrice = $current.close
    
    $ma7_values = @()
    for ($j = $i-6; $j -le $i; $j++) {
        $ma7_values += $data[$j].close
    }
    $ma7 = ($ma7_values | Measure-Object -Average).Average
    
    $ma25_values = @()
    for ($j = $i-24; $j -le $i; $j++) {
        $ma25_values += $data[$j].close
    }
    $ma25 = ($ma25_values | Measure-Object -Average).Average
    
    $gains = @()
    $losses = @()
    for ($j = $i-13; $j -le $i; $j++) {
        $change = $data[$j].close - $data[$j-1].close
        if ($change -gt 0) {
            $gains += $change
            $losses += 0
        } else {
            $gains += 0
            $losses += -$change
        }
    }
    $avgGain = ($gains | Measure-Object -Average).Average
    $avgLoss = ($losses | Measure-Object -Average).Average
    
    if ($avgLoss -eq 0) {
        $rsi = 100
    } else {
        $rs = $avgGain / $avgLoss
        $rsi = [math]::Round(100 - (100 / (1 + $rs)))
    }
    
    $vol5_values = @()
    for ($j = $i-4; $j -le $i; $j++) {
        $vol5_values += $data[$j].volume
    }
    $vol5 = ($vol5_values | Measure-Object -Average).Average
    
    $vol20_values = @()
    for ($j = $i-19; $j -le $i; $j++) {
        $vol20_values += $data[$j].volume
    }
    $vol20 = ($vol20_values | Measure-Object -Average).Average
    
    $volumeRatio = $vol5 / $vol20
    $priceChange1h = (($currentPrice - $data[$i-1].close) / $data[$i-1].close) * 100
    $priceChange6h = (($currentPrice - $data[$i-6].close) / $data[$i-6].close) * 100
    
    $signal = "HOLD"
    $score = 0
    
    if ($ma7 -gt $ma25 -and $ma7 -gt $ma25 * 1.005) { $score += 2 }
    if ($ma7 -lt $ma25 -and $ma7 -lt $ma25 * 0.995) { $score -= 2 }
    if ($rsi -lt 30) { $score += 2 }
    if ($rsi -gt 70) { $score -= 2 }
    if ($volumeRatio -gt 1.5) { 
        if ($priceChange1h -gt 0) { $score += 1 }
        if ($priceChange1h -lt 0) { $score -= 1 }
    }
    if ($priceChange6h -gt 1) { $score += 1 }
    if ($priceChange6h -lt -1) { $score -= 1 }
    
    if ($score -ge 2) { $signal = "BUY" }
    if ($score -le -2) { $signal = "SELL" }
    
    $timestamp = [DateTimeOffset]::FromUnixTimeMilliseconds($current.openTime).DateTime
    
    $results += [PSCustomObject]@{
        Timestamp = $timestamp
        Price = [math]::Round($currentPrice, 2)
        Signal = $signal
        Score = $score
        MA7 = [math]::Round($ma7, 2)
        MA25 = [math]::Round($ma25, 2)
        RSI = $rsi
        VolumeRatio = [math]::Round($volumeRatio, 2)
        Change1h = [math]::Round($priceChange1h, 2)
        Change6h = [math]::Round($priceChange6h, 2)
    }
}

$results | Export-Csv -Path "signals.csv" -NoTypeInformation
$results | ConvertTo-Json | Out-File "signals.json"

Write-Host "Analysis complete! Generated $($results.Count) signals" -ForegroundColor Green

if ($results.Count -gt 0) {
    Write-Host "Latest signal: $($results[-1].Signal) at price `$$($results[-1].Price)" -ForegroundColor Cyan
}

$buyCount = ($results | Where-Object { $_.Signal -eq "BUY" }).Count
$sellCount = ($results | Where-Object { $_.Signal -eq "SELL" }).Count
$holdCount = ($results | Where-Object { $_.Signal -eq "HOLD" }).Count

Write-Host "`nSignal Distribution:" -ForegroundColor Yellow
Write-Host "  BUY:  $buyCount"
Write-Host "  SELL: $sellCount"
Write-Host "  HOLD: $holdCount"

if ($results.Count -gt 0) {
    Write-Host "`nLast 5 signals:" -ForegroundColor Yellow
    $results | Select-Object -Last 5 | Format-Table Timestamp, Price, Signal, Score -AutoSize
}