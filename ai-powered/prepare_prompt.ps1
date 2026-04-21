$data = Get-Content "btc_data.json" | ConvertFrom-Json

# Take last 10 candles (you can adjust later)
$recent = $data[-10..-1]

$prompt = "BTCUSDT Market Data (last 10 hours):`n"

foreach ($candle in $recent) {
    $open = $candle[1]
    $high = $candle[2]
    $low = $candle[3]
    $close = $candle[4]
    $volume = $candle[5]

    $prompt += "Open=$open High=$high Low=$low Close=$close Volume=$volume`n"
}

$prompt += "`nQuestion: Should we BUY, SELL, or HOLD next?`n"
$prompt += "Answer ONLY one word: BUY, SELL, or HOLD."

$prompt | Out-File "prompt.txt"

Write-Host "Prompt saved to prompt.txt"