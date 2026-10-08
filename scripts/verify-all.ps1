# MyDay Monorepo Verification Script
Write-Host "=== MyDay Monorepo Verification ===" -ForegroundColor Cyan

# Mobile Check
Write-Host "`n[1/3] Verifying Mobile (Flutter)..." -ForegroundColor Yellow
Push-Location apps/mobile
try {
    flutter gen-l10n
    flutter analyze
    flutter test
    Write-Host "Mobile checks passed!" -ForegroundColor Green
} finally {
    Pop-Location
}

Write-Host "`nVerification complete!" -ForegroundColor Cyan
