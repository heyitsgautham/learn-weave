# LearnWeave - Quick Start Script
# Run this after you've completed the setup

param(
    [switch]$Backend,
    [switch]$Frontend,
    [switch]$ChromaDB,
    [switch]$All
)

function Write-Header {
    param([string]$Text)
    Write-Host "`n================================" -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
}

function Start-Backend {
    Write-Header "Starting Backend Server"
    
    # Check if .env exists
    if (-not (Test-Path "backend\.env")) {
        Write-Host "✗ backend\.env file not found!" -ForegroundColor Red
        Write-Host "  Please create it from .env.example and fill in your API keys" -ForegroundColor Yellow
        return $false
    }
    
    # Check if venv exists
    if (-not (Test-Path "backend\venv")) {
        Write-Host "✗ Virtual environment not found!" -ForegroundColor Red
        Write-Host "  Run setup.ps1 first or create it manually" -ForegroundColor Yellow
        return $false
    }
    
    Write-Host "Starting FastAPI server..." -ForegroundColor Yellow
    Set-Location backend
    & ".\venv\Scripts\Activate.ps1"
    
    Write-Host "`nBackend server starting at http://localhost:8000" -ForegroundColor Green
    Write-Host "API Documentation: http://localhost:8000/docs" -ForegroundColor Green
    Write-Host "`nPress Ctrl+C to stop the server`n" -ForegroundColor Yellow
    
    uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
    
    Set-Location ..
    return $true
}

function Start-Frontend {
    Write-Header "Starting Frontend Server"
    
    # Check if node_modules exists
    if (-not (Test-Path "frontend\node_modules")) {
        Write-Host "✗ node_modules not found!" -ForegroundColor Red
        Write-Host "  Run: cd frontend && npm install" -ForegroundColor Yellow
        return $false
    }
    
    Write-Host "Starting Vite development server..." -ForegroundColor Yellow
    Set-Location frontend
    
    Write-Host "`nFrontend server starting at http://localhost:5173" -ForegroundColor Green
    Write-Host "`nPress Ctrl+C to stop the server`n" -ForegroundColor Yellow
    
    npm run dev
    
    Set-Location ..
    return $true
}

function Start-ChromaDB {
    Write-Header "Starting ChromaDB"
    
    # Check if Docker is running
    try {
        docker ps | Out-Null
        Write-Host "✓ Docker is running" -ForegroundColor Green
    } catch {
        Write-Host "✗ Docker is not running!" -ForegroundColor Red
        Write-Host "  Please start Docker Desktop first" -ForegroundColor Yellow
        return $false
    }
    
    # Check if docker-compose.yml exists
    if (-not (Test-Path "backend\chroma_db\docker-compose.yml")) {
        Write-Host "✗ ChromaDB docker-compose.yml not found!" -ForegroundColor Red
        return $false
    }
    
    Write-Host "Starting ChromaDB container..." -ForegroundColor Yellow
    Set-Location backend\chroma_db
    docker-compose up -d
    
    if ($?) {
        Write-Host "`n✓ ChromaDB started successfully!" -ForegroundColor Green
        Write-Host "  URL: http://localhost:8001" -ForegroundColor Cyan
        Write-Host "  Check status: curl http://localhost:8001/api/v1/heartbeat" -ForegroundColor Cyan
    } else {
        Write-Host "✗ Failed to start ChromaDB" -ForegroundColor Red
    }
    
    Set-Location ..\..
    return $?
}

function Start-All {
    Write-Header "Starting All Services"
    
    # Start ChromaDB first
    Write-Host "[1/3] Starting ChromaDB..." -ForegroundColor Yellow
    Start-ChromaDB
    Start-Sleep -Seconds 3
    
    # Then start backend and frontend in separate windows
    Write-Host "`n[2/3] Starting Backend in new window..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PWD'; .\start.ps1 -Backend"
    Start-Sleep -Seconds 2
    
    Write-Host "`n[3/3] Starting Frontend in new window..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PWD'; .\start.ps1 -Frontend"
    
    Write-Host "`n================================" -ForegroundColor Green
    Write-Host "  All Services Starting! ✓" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Green
    Write-Host "`nServices:" -ForegroundColor White
    Write-Host "  • ChromaDB:  http://localhost:8001" -ForegroundColor Cyan
    Write-Host "  • Backend:   http://localhost:8000" -ForegroundColor Cyan
    Write-Host "  • Frontend:  http://localhost:5173" -ForegroundColor Cyan
    Write-Host "  • API Docs:  http://localhost:8000/docs" -ForegroundColor Cyan
    Write-Host "`nOpen http://localhost:5173 in your browser!" -ForegroundColor Green
    Write-Host ""
}

# Main execution
if (-not (Test-Path "backend") -or -not (Test-Path "frontend")) {
    Write-Host "ERROR: Please run this script from the LearnWeave root directory!" -ForegroundColor Red
    exit 1
}

if ($All) {
    Start-All
} elseif ($Backend) {
    Start-Backend
} elseif ($Frontend) {
    Start-Frontend
} elseif ($ChromaDB) {
    Start-ChromaDB
} else {
    Write-Header "LearnWeave - Quick Start"
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\start.ps1 -All          Start all services" -ForegroundColor White
    Write-Host "  .\start.ps1 -Backend      Start backend only" -ForegroundColor White
    Write-Host "  .\start.ps1 -Frontend     Start frontend only" -ForegroundColor White
    Write-Host "  .\start.ps1 -ChromaDB     Start ChromaDB only" -ForegroundColor White
    Write-Host ""
    Write-Host "Example:" -ForegroundColor Yellow
    Write-Host "  .\start.ps1 -All" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "First time setup? Run: .\setup.ps1" -ForegroundColor Yellow
    Write-Host ""
}
