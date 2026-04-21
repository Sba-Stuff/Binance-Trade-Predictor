# Read prompt from file
$prompt = Get-Content "prompt.txt" -Raw

# Build request body (simplified for reliability)
$body = @{
    model = "liquid/lfm2.5-1.2b"
    messages = @(
        @{
            role = "user"
            content = "Based on this BTC data, answer with ONLY one word: BUY, SELL, or HOLD.`n`n$prompt"
        }
    )
    temperature = 0
    max_tokens = 10
    stream = $false
} | ConvertTo-Json -Depth 10

Write-Host "Sending trading prediction request..." -ForegroundColor Yellow
Write-Host "Prompt length: $($prompt.Length) characters" -ForegroundColor Gray

try {
    $response = Invoke-RestMethod -Uri "http://localhost:1234/v1/chat/completions" `
        -Method Post `
        -Body $body `
        -ContentType "application/json" `
        -TimeoutSec 6000
    
    $output = $response.choices[0].message.content.Trim()
    
    # Clean up the output (remove any extra text)
    if ($output -match "BUY|SELL|HOLD") {
        $output = $matches[0]
    }
    
    # Save prediction
    $output | Out-File -FilePath "prediction.txt" -Encoding utf8
    
    Write-Host "SUCCESS! Prediction: $output" -ForegroundColor Green
    Write-Host "Saved to prediction.txt" -ForegroundColor Gray
}
catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
}