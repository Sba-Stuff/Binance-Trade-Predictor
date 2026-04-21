$data = Get-Content "btc_data.json" -Raw | ConvertFrom-Json

Write-Host "Analyzing with TUNED strategy (let winners run)..." -ForegroundColor Yellow

$results = @()

for ($i = 20; $i -lt $data.Count; $i++) {
    $current = $data[$i]
    $currentPrice = $current.close
    
    # Simple moving averages
    $ma5 = 0
    for ($j = $i-4; $j -le $i; $j++) { $ma5 += $data[$j].close }
    $ma5 = $ma5 / 5
    
    $ma20 = 0
    for ($j = $i-19; $j -le $i; $j++) { $ma20 += $data[$j].close }
    $ma20 = $ma20 / 20
    
    # Price changes
    $priceChange1h = (($currentPrice - $data[$i-1].close) / $data[$i-1].close) * 100
    $priceChange4h = (($currentPrice - $data[$i-4].close) / $data[$i-4].close) * 100
    $priceChange12h = (($currentPrice - $data[$i-12].close) / $data[$i-12].close) * 100
    
    # Volume
    $volAvg10 = 0
    for ($j = $i-9; $j -le $i; $j++) { $volAvg10 += $data[$j].volume }
    $volAvg10 = $volAvg10 / 10
    $volumeRatio = $current.volume / $volAvg10
    
    # TUNED STRATEGY
    $signal = "HOLD"
    
    # BUY: Strong uptrend confirmation
    if ($currentPrice -gt $ma20 -and 
        $priceChange4h -gt 0.5 -and 
        $priceChange12h -gt 2 -and
        $volumeRatio -gt 1.1) {
        $signal = "BUY"
    }
    
    # BUY: Golden cross with volume
    if ($ma5 -gt $ma20 -and $data[$i-1].close -lt $ma20 -and $volumeRatio -gt 1.2) {
        $signal = "BUY"
    }
    
    # SELL: Death cross or trend reversal
    if ($ma5 -lt $ma20 -and $data[$i-1].close -gt $ma20) {
        $signal = "SELL"
    }
    
    # Take profit - let winners run longer (5% instead of 3%)
    if ($inPosition -and (($currentPrice - $entryPrice) / $entryPrice) -gt 0.05) {
        $signal = "SELL"
    }
    
    # Stop loss remains tight at -1.5%
    if ($inPosition -and (($currentPrice - $entryPrice) / $entryPrice) -lt -0.015) {
        $signal = "SELL"
    }
    
    # Trail stop after 3% gain (lock in profits)
    if ($inPosition) {
        $currentGain = (($currentPrice - $entryPrice) / $entryPrice) * 100
        if ($currentGain -gt 3 -and $priceChange1h -lt -0.3) {
            $signal = "SELL"
        }
    }
    
    $timestamp = [DateTimeOffset]::FromUnixTimeMilliseconds($current.openTime).DateTime
    
    $results += [PSCustomObject]@{
        Timestamp = $timestamp
        Price = [math]::Round($currentPrice, 2)
        Signal = $signal
        MA5 = [math]::Round($ma5, 2)
        MA20 = [math]::Round($ma20, 2)
        Change1h = [math]::Round($priceChange1h, 2)
        Change4h = [math]::Round($priceChange4h, 2)
        Change12h = [math]::Round($priceChange12h, 2)
        VolumeRatio = [math]::Round($volumeRatio, 2)
    }
}

$results | Export-Csv -Path "signals_tuned.csv" -NoTypeInformation
$results | ConvertTo-Json | Out-File "signals_tuned.json"

$buyCount = ($results | Where-Object { $_.Signal -eq "BUY" }).Count
$sellCount = ($results | Where-Object { $_.Signal -eq "SELL" }).Count

Write-Host "Tuned strategy analysis complete!" -ForegroundColor Green
Write-Host "`nSignal Distribution:" -ForegroundColor Yellow
Write-Host "  BUY:  $buyCount"
Write-Host "  SELL: $sellCount"
Write-Host "  HOLD: $($results.Count - $buyCount - $sellCount)"