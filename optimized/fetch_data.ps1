$symbol = "BTCUSDT"
$interval = "1h"
$limit = 500

$url = "https://api.binance.com/api/v3/klines?symbol=$symbol&interval=$interval&limit=$limit"

try {
    Write-Host "Fetching $symbol $interval data..." -ForegroundColor Yellow
    
    $response = Invoke-WebRequest -Uri $url
    $rawData = $response.Content | ConvertFrom-Json
    
    $candles = @()
    foreach ($item in $rawData) {
        $candles += @{
            openTime = $item[0]
            open = [double]$item[1]
            high = [double]$item[2]
            low = [double]$item[3]
            close = [double]$item[4]
            volume = [double]$item[5]
            closeTime = $item[6]
            quoteVolume = [double]$item[7]
            trades = [int]$item[8]
            buyBaseVolume = [double]$item[9]
            buyQuoteVolume = [double]$item[10]
        }
    }
    
    $candles | ConvertTo-Json -Depth 10 | Out-File -FilePath "btc_data.json" -Encoding utf8
    
    Write-Host "SUCCESS! Saved $($candles.Count) candles to btc_data.json" -ForegroundColor Green
    
    $firstDate = [DateTimeOffset]::FromUnixTimeMilliseconds($candles[0].openTime).DateTime
    $lastDate = [DateTimeOffset]::FromUnixTimeMilliseconds($candles[-1].openTime).DateTime
    Write-Host "Date range: $firstDate to $lastDate" -ForegroundColor Gray
    Write-Host "Current price: `$$($candles[-1].close)" -ForegroundColor Cyan
}
catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
}