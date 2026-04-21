$dataset = Get-Content "dataset.json" | ConvertFrom-Json

$win = 0
$loss = 0
$total = 0

foreach ($item in $dataset) {

    # Build prompt
    $prompt = "Predict BUY, SELL, or HOLD based on last 5 candles:`n"

    foreach ($c in $item.input) {
        $prompt += "O=$($c[1]) H=$($c[2]) L=$($c[3]) C=$($c[4]) V=$($c[5])`n"
    }

    $prompt += "`nAnswer ONLY BUY, SELL, or HOLD."

    $body = @{
        model = "google/gemma-3-1b"
        messages = @(
            @{ role="system"; content="You are a trading decision engine. You MUST choose one: BUY, SELL, or HOLD." },
            @{ role="user"; content=$prompt }
        )
        temperature = 0
        max_tokens = 500
    } | ConvertTo-Json -Depth 10

    try {
        $response = Invoke-RestMethod `
            -Uri "http://localhost:1234/v1/chat/completions" `
            -Method Post `
            -Body $body `
            -ContentType "application/json" `
            -TimeoutSec 600000
        $pred = $response.choices[0].message.content.Trim().ToUpper()

        if ($pred -eq $item.label) {
            $win++
        } else {
            $loss++
        }

        $total++

        Write-Host "Pred: $pred | Actual: $($item.label)"

    } catch {
        Write-Host "Skipped one due to error"
    }
}

Write-Host "`n===== RESULTS ====="
Write-Host "Total: $total"
Write-Host "Wins: $win"
Write-Host "Losses: $loss"
Write-Host ("Accuracy: {0:P2}" -f ($win / $total))