$url = "https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=1h&limit=100"
$output = "btc_data.json"

try {
    Invoke-WebRequest -Uri $url -OutFile $output
    Write-Host "Data saved to $output"
} catch {
    Write-Host "Error:"
    Write-Host $_
}