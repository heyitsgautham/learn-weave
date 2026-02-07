# ============================================
# LearnWeave - Quick Start Script
# Test locally for local development
# ============================================

Write-Host "================================" -ForegroundColor Cyan
Write-Host "  LearnWeave - Local Test Setup" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Check if Supabase is configured
Write-Host "[1/5] Checking Supabase configuration..." -ForegroundColor Yellow
$envContent = Get-Content "backend\.env" -Raw
if ($envContent -match "your-supabase-password") {
    Write-Host "WARNING: Please configure Supabase first!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Quick Setup:" -ForegroundColor Yellow
    Write-Host "1. Go to: https://supabase.com/dashboard" -ForegroundColor White
    Write-Host "2. Create new project" -ForegroundColor White
    Write-Host "3. Get database connection details from Settings > Database" -ForegroundColor White
    Write-Host "4. Update backend\.env with:" -ForegroundColor White
    Write-Host "   DB_USER, DB_PASSWORD, DB_HOST, DB_PORT" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}
else {
    Write-Host "Supabase configured" -ForegroundColor Green
}

# Check Docker
Write-Host ""
Write-Host "[2/5] Checking Docker..." -ForegroundColor Yellow
try {
    docker --version | Out-Null
    docker ps | Out-Null
    Write-Host "Docker is ready" -ForegroundColor Green
}
catch {
    Write-Host "Docker is not running!" -ForegroundColor Red
    exit 1
}

# Check Google credentials
Write-Host ""
Write-Host "[3/5] Checking Google credentials..." -ForegroundColor Yellow
if (Test-Path "backend\google-credentials.json") {
    Write-Host "Google credentials found" -ForegroundColor Green
}
else {
    Write-Host "backend\google-credentials.json missing!" -ForegroundColor Red
    exit 1
}

# Build and start
Write-Host ""
Write-Host "[4/5] Building and starting containers..." -ForegroundColor Yellow
Set-Location backend
docker-compose -f docker-compose-supabase.yml down 2>&1 | Out-Null
docker-compose -f docker-compose-supabase.yml up -d --build

if ($LASTEXITCODE -eq 0) {
    Write-Host "Containers started" -ForegroundColor Green
}
else {
    Write-Host "Failed to start containers!" -ForegroundColor Red
    Set-Location ..
    exit 1
}

# Wait and test
Write-Host ""
Write-Host "[5/5] Waiting for services..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "  Local Test Ready!" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Backend API: http://localhost:8127/docs" -ForegroundColor Green
Write-Host "ChromaDB: http://localhost:8001" -ForegroundColor Green
Write-Host "Database: Supabase (cloud)" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Test API: http://localhost:8127/docs" -ForegroundColor White
Write-Host "2. View logs: docker-compose -f docker-compose-supabase.yml logs -f" -ForegroundColor White
Write-Host "3. Stop: docker-compose -f docker-compose-supabase.yml down" -ForegroundColor White
Write-Host ""
Write-Host "Ready for local testing with Docker!" -ForegroundColor Green
Write-Host "See: README.md for local deployment instructions" -ForegroundColor Cyan
Write-Host ""

Set-Location ..
