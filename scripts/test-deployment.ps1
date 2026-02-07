# LearnWeave - Quick Test Script
# Run this to verify everything is working before deployment

Write-Host "================================" -ForegroundColor Cyan
Write-Host "  LearnWeave - Pre-Deployment Test" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

$ErrorCount = 0

# Check Docker
Write-Host "[1/8] Checking Docker..." -ForegroundColor Yellow
try {
    docker --version | Out-Null
    docker ps | Out-Null
    Write-Host "✓ Docker is ready" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker is not running!" -ForegroundColor Red
    $ErrorCount++
}

# Check files exist
Write-Host "`n[2/8] Checking required files..." -ForegroundColor Yellow
$files = @(
    "backend\.env",
    "backend\google-credentials.json",
    "backend\docker-compose.yml",
    "backend\Dockerfile"
)
foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "✓ $file exists" -ForegroundColor Green
    } else {
        Write-Host "✗ $file missing!" -ForegroundColor Red
        $ErrorCount++
    }
}

# Check .env passwords changed
Write-Host "`n[3/8] Checking .env configuration..." -ForegroundColor Yellow
$envContent = Get-Content "backend\.env" -Raw
if ($envContent -match "Change_This_Password|your_secure_password|your-secret-key") {
    Write-Host "⚠ WARNING: Default passwords detected in .env!" -ForegroundColor Yellow
    Write-Host "  Please update passwords in backend\.env before deploying!" -ForegroundColor Yellow
} else {
    Write-Host "✓ Passwords appear to be configured" -ForegroundColor Green
}

# Stop any existing containers
Write-Host "`n[4/8] Cleaning up old containers..." -ForegroundColor Yellow
Set-Location backend
docker-compose down 2>&1 | Out-Null
Write-Host "✓ Cleanup complete" -ForegroundColor Green

# Start services
Write-Host "`n[5/8] Starting services (this may take a few minutes)..." -ForegroundColor Yellow
Write-Host "  Building and starting containers..." -ForegroundColor Cyan
docker-compose up -d --build

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Services started" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to start services!" -ForegroundColor Red
    $ErrorCount++
}

# Wait for services to be ready
Write-Host "`n[6/8] Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Check containers
Write-Host "`n[7/8] Checking container status..." -ForegroundColor Yellow
$containers = docker ps --format "{{.Names}}"
$expectedContainers = @("learnweave", "learnweave-mysql", "learnweave-chromadb")
foreach ($container in $expectedContainers) {
    if ($containers -contains $container) {
        Write-Host "✓ $container is running" -ForegroundColor Green
    } else {
        Write-Host "✗ $container is not running!" -ForegroundColor Red
        $ErrorCount++
    }
}

# Test endpoints
Write-Host "`n[8/8] Testing API endpoints..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

try {
    $response = Invoke-WebRequest -Uri "http://localhost:8127/docs" -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "✓ Backend API is accessible at http://localhost:8127" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ Backend API is not responding!" -ForegroundColor Red
    Write-Host "  Check logs: docker-compose logs -f app" -ForegroundColor Yellow
    $ErrorCount++
}

try {
    $response = Invoke-WebRequest -Uri "http://localhost:8001/api/v1/heartbeat" -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "✓ ChromaDB is accessible at http://localhost:8001" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠ ChromaDB is not responding (may need more time)" -ForegroundColor Yellow
}

# Summary
Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "  Test Results" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

if ($ErrorCount -eq 0) {
    Write-Host "`n✓ ALL TESTS PASSED!" -ForegroundColor Green
    Write-Host "`nYour application is ready for deployment!" -ForegroundColor Green
    Write-Host "`nServices running:" -ForegroundColor White
    Write-Host "  • Backend:  http://localhost:8127/docs" -ForegroundColor Cyan
    Write-Host "  • ChromaDB: http://localhost:8001" -ForegroundColor Cyan
    Write-Host "  • MySQL:    localhost:3306" -ForegroundColor Cyan
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "  1. Test the API in browser: http://localhost:8127/docs" -ForegroundColor White
    Write-Host "  2. Create admin user: docker exec -it learnweave python create_admin.py" -ForegroundColor White
    Write-Host "  3. Start frontend: cd frontend; npm run dev" -ForegroundColor White
    Write-Host "  4. (Production deployment instructions removed)" -ForegroundColor White
} else {
    Write-Host "`n✗ $ErrorCount ERROR(S) FOUND!" -ForegroundColor Red
    Write-Host "`nPlease fix the issues above and try again." -ForegroundColor Yellow
    Write-Host "`nCheck logs:" -ForegroundColor White
    Write-Host "  docker-compose logs -f" -ForegroundColor Cyan
}

Write-Host "`nView logs:" -ForegroundColor Yellow
Write-Host "  docker-compose logs -f" -ForegroundColor Cyan
Write-Host "`nStop services:" -ForegroundColor Yellow
Write-Host "  docker-compose down" -ForegroundColor Cyan

Set-Location ..
Write-Host ""
