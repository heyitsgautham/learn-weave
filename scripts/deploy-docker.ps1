# LearnWeave - Docker Deployment Script
# Quick script to build and deploy with Docker

param(
    [switch]$Build,
    [switch]$Start,
    [switch]$Stop,
    [switch]$Restart,
    [switch]$Logs,
    [switch]$Status
)

function Write-Header {
    param([string]$Text)
    Write-Host "`n================================" -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
}

function Check-Prerequisites {
    Write-Host "`nChecking prerequisites..." -ForegroundColor Yellow
    
    # Check Docker
    try {
        docker --version | Out-Null
        Write-Host "✓ Docker is installed" -ForegroundColor Green
    } catch {
        Write-Host "✗ Docker is not installed or not in PATH!" -ForegroundColor Red
        Write-Host "  Please install Docker Desktop from: https://www.docker.com/products/docker-desktop/" -ForegroundColor Yellow
        return $false
    }
    
    # Check if Docker is running
    try {
        docker ps | Out-Null
        Write-Host "✓ Docker daemon is running" -ForegroundColor Green
    } catch {
        Write-Host "✗ Docker daemon is not running!" -ForegroundColor Red
        Write-Host "  Please start Docker Desktop" -ForegroundColor Yellow
        return $false
    }
    
    # Check if .env exists
    if (Test-Path "backend\.env") {
        Write-Host "✓ .env file exists" -ForegroundColor Green
    } else {
        Write-Host "✗ backend\.env file not found!" -ForegroundColor Red
        Write-Host "  Please create it from .env.example" -ForegroundColor Yellow
        return $false
    }
    
    # Check if google-credentials.json exists
    if (Test-Path "backend\google-credentials.json") {
        Write-Host "✓ google-credentials.json exists" -ForegroundColor Green
    } else {
        Write-Host "✗ backend\google-credentials.json not found!" -ForegroundColor Red
        Write-Host "  Please download your Google Cloud service account key" -ForegroundColor Yellow
        return $false
    }
    
    return $true
}

function Build-Containers {
    Write-Header "Building Docker Containers"
    
    Set-Location backend
    Write-Host "`nBuilding containers (this may take a few minutes)...`n" -ForegroundColor Yellow
    docker-compose build
    
    if ($?) {
        Write-Host "`n✓ Build completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "`n✗ Build failed!" -ForegroundColor Red
    }
    
    Set-Location ..
}

function Start-Containers {
    Write-Header "Starting Docker Containers"
    
    Set-Location backend
    Write-Host "`nStarting containers...`n" -ForegroundColor Yellow
    docker-compose up -d
    
    if ($?) {
        Write-Host "`n✓ Containers started successfully!" -ForegroundColor Green
        Write-Host "`n📊 Services:" -ForegroundColor White
        Write-Host "  • Backend API:    http://localhost:8127" -ForegroundColor Cyan
        Write-Host "  • API Docs:       http://localhost:8127/docs" -ForegroundColor Cyan
        Write-Host "  • ChromaDB:       http://localhost:8001" -ForegroundColor Cyan
        Write-Host "`nView logs with: .\deploy-docker.ps1 -Logs" -ForegroundColor Yellow
    } else {
        Write-Host "`n✗ Failed to start containers!" -ForegroundColor Red
    }
    
    Set-Location ..
}

function Stop-Containers {
    Write-Header "Stopping Docker Containers"
    
    Set-Location backend
    Write-Host "`nStopping containers...`n" -ForegroundColor Yellow
    docker-compose down
    
    if ($?) {
        Write-Host "`n✓ Containers stopped successfully!" -ForegroundColor Green
    } else {
        Write-Host "`n✗ Failed to stop containers!" -ForegroundColor Red
    }
    
    Set-Location ..
}

function Restart-Containers {
    Write-Header "Restarting Docker Containers"
    
    Set-Location backend
    Write-Host "`nRestarting containers...`n" -ForegroundColor Yellow
    docker-compose restart
    
    if ($?) {
        Write-Host "`n✓ Containers restarted successfully!" -ForegroundColor Green
    } else {
        Write-Host "`n✗ Failed to restart containers!" -ForegroundColor Red
    }
    
    Set-Location ..
}

function Show-Logs {
    Write-Header "Container Logs"
    
    Set-Location backend
    Write-Host "`nShowing logs (Ctrl+C to exit)...`n" -ForegroundColor Yellow
    docker-compose logs -f
    
    Set-Location ..
}

function Show-Status {
    Write-Header "Container Status"
    
    Set-Location backend
    Write-Host ""
    docker-compose ps
    Write-Host ""
    
    Set-Location ..
}

# Main execution
if (-not (Test-Path "backend")) {
    Write-Host "ERROR: Please run this script from the LearnWeave root directory!" -ForegroundColor Red
    exit 1
}

# Check prerequisites
if (-not (Check-Prerequisites)) {
    Write-Host "`nPlease fix the issues above and try again." -ForegroundColor Yellow
    exit 1
}

if ($Build) {
    Build-Containers
    Write-Host "`nNext: Run '.\deploy-docker.ps1 -Start' to start the containers" -ForegroundColor Yellow
} elseif ($Start) {
    Start-Containers
} elseif ($Stop) {
    Stop-Containers
} elseif ($Restart) {
    Restart-Containers
} elseif ($Logs) {
    Show-Logs
} elseif ($Status) {
    Show-Status
} else {
    Write-Header "LearnWeave - Docker Deployment"
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\deploy-docker.ps1 -Build      Build Docker images" -ForegroundColor White
    Write-Host "  .\deploy-docker.ps1 -Start      Start containers" -ForegroundColor White
    Write-Host "  .\deploy-docker.ps1 -Stop       Stop containers" -ForegroundColor White
    Write-Host "  .\deploy-docker.ps1 -Restart    Restart containers" -ForegroundColor White
    Write-Host "  .\deploy-docker.ps1 -Logs       Show container logs" -ForegroundColor White
    Write-Host "  .\deploy-docker.ps1 -Status     Show container status" -ForegroundColor White
    Write-Host ""
    Write-Host "Quick Start:" -ForegroundColor Yellow
    Write-Host "  1. .\deploy-docker.ps1 -Build" -ForegroundColor Cyan
    Write-Host "  2. .\deploy-docker.ps1 -Start" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Or build and start in one command:" -ForegroundColor Yellow
    Write-Host "  cd backend" -ForegroundColor Cyan
    Write-Host "  docker-compose up --build -d" -ForegroundColor Cyan
    Write-Host ""
}
