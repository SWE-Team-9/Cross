$LF=0
$LH=0
Get-Content 'coverage\\lcov.info' | ForEach-Object {
    if ($_ -match '^LF:(\d+)') { $LF += [int]$matches[1] }
    elseif ($_ -match '^LH:(\d+)') { $LH += [int]$matches[1] }
}
Write-Output "LF:$LF LH:$LH"
if ($LF -gt 0) { $pct = [math]::Round($LH*100.0/$LF,2); Write-Output "coverage: $pct%" } else { Write-Output "coverage: 0%" }
