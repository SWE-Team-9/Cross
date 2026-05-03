# Test script to simulate Android release CI locally
Write-Host "=== Android Release Build Test ===" -ForegroundColor Green

# 1. Simulate tag
$TAG = "v2.0.0"
Write-Host "Using tag: $TAG" -ForegroundColor Cyan

# 2. Extract version
$VERSION = $TAG -replace '^v', ''
Write-Host "Extracted version: $VERSION" -ForegroundColor Cyan

if ([string]::IsNullOrWhiteSpace($VERSION)) {
    Write-Host "ERROR: VERSION is empty" -ForegroundColor Red
    exit 1
}

# 3. Backup original pubspec.yaml
Write-Host "Backing up pubspec.yaml..." -ForegroundColor Cyan
Copy-Item pubspec.yaml pubspec.yaml.bak

# 4. Test version update
Write-Host "Testing pubspec version update..." -ForegroundColor Cyan
$newVersion = "$VERSION+1"
Write-Host "New version will be: $newVersion" -ForegroundColor Yellow
(Get-Content pubspec.yaml) -replace '^version:.*', "version: $newVersion" | Set-Content pubspec.yaml.test
$updated = (Get-Content pubspec.yaml.test | Select-String "^version:").Line
Write-Host "Updated line: $updated" -ForegroundColor Green

# 5. Flutter version
Write-Host "Flutter version:" -ForegroundColor Cyan
flutter --version

# 6. Dart version
Write-Host "Dart version:" -ForegroundColor Cyan
dart --version

# 7. SDK constraints
Write-Host "SDK constraints in pubspec.yaml:" -ForegroundColor Cyan
(Get-Content pubspec.yaml | Select-String "sdk:|flutter:")

# 8. Test dependency resolution
Write-Host "Running flutter pub get..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: flutter pub get failed" -ForegroundColor Red
    Remove-Item pubspec.yaml.test -Force
    Move-Item pubspec.yaml.bak pubspec.yaml -Force
    exit 1
}

# 9. Cleanup
Write-Host "Cleaning up..." -ForegroundColor Cyan
Remove-Item pubspec.yaml.test -Force
Move-Item pubspec.yaml.bak pubspec.yaml -Force

Write-Host ""
Write-Host "=== Test Results ===" -ForegroundColor Green
Write-Host "OK: Version extraction works" -ForegroundColor Green
Write-Host "OK: pubspec.yaml is valid" -ForegroundColor Green
Write-Host "OK: flutter pub get succeeded" -ForegroundColor Green
Write-Host ""
Write-Host "READY FOR APK BUILD" -ForegroundColor Green
