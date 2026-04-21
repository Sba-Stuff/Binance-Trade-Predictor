$data = Get-Content "btc_data.json" -Raw | ConvertFrom-Json

Write-Host "Analyzing with FINAL WORKING strategy..." -ForegroundColor Yellow

$results = @()
$inPosition = $false
$entryPrice = 0

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
    
    # FINAL WORKING STRATEGY (based on best results)
    $signal = "HOLD"
    
    # BUY conditions (from practical strategy that worked)
    if ($currentPrice -gt $ma20 -and 
        $priceChange4h -gt 0.3 -and 
        $volumeRatio -gt 1.05) {
        $signal = "BUY"
    }
    
    # BUY on golden cross
    if ($ma5 -gt $ma20 -and $data[$i-1].close -lt $ma20) {
        $signal = "BUY"
    }
    
    # SELL conditions
    if ($currentPrice -lt $ma20 -and $priceChange4h -lt -0.3) {
        $signal = "SELL"
    }
    
    # SELL on death cross
    if ($ma5 -lt $ma20 -and $data[$i-1].close -gt $ma20) {
        $signal = "SELL"
    }
    
    # Take profit at 4% (let winners run more)
    if ($inPosition -and (($currentPrice - $entryPrice) / $entryPrice) -gt 0.04) {
        $signal = "SELL"
    }
    
    # Stop loss at -1.5% (same as before)
    if ($inPosition -and (($currentPrice - $entryPrice) / $entryPrice) -lt -0.015) {
        $signal = "SELL"
    }
    
    # Trail stop after 2.5% gain
    if ($inPosition) {
        $currentGain = (($currentPrice - $entryPrice) / $entryPrice) * 100
        if ($currentGain -gt 2.5 -and $priceChange1h -lt -0.2) {
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
        VolumeRatio = [math]::Round($volumeRatio, 2)
    }
}

$results | Export-Csv -Path "signals_final_working.csv" -NoTypeInformation
$results | ConvertTo-Json | Out-File "signals_final_working.json"

$buyCount = ($results | Where-Object { $_.Signal -eq "BUY" }).Count
$sellCount = ($results | Where-Object { $_.Signal -eq "SELL" }).Count

Write-Host "Final working strategy analysis complete!" -ForegroundColor Green
Write-Host "`nSignal Distribution:" -ForegroundColor Yellow
Write-Host "  BUY:  $buyCount"
Write-Host "  SELL: $sellCount"
Write-Host "  HOLD: $($results.Count - $buyCount - $sellCount)"