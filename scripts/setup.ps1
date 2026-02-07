# LearnWeave - Quick Setup Script for Windows
# Run this script in PowerShell to automate initial setup

Write-Host "================================" -ForegroundColor Cyan
Write-Host "  LearnWeave - Setup Script" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Check if we're in the right directory
if (-not (Test-Path "backend") -or -not (Test-Path "frontend")) {
    Write-Host "ERROR: Please run this script from the LearnWeave root directory!" -ForegroundColor Red
    exit 1
}

# Step 1: Check Python
Write-Host "[1/8] Checking Python installation..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "✓ Found: $pythonVersion" -ForegroundColor Green
    
    # Check if version is 3.12+
    if ($pythonVersion -match "Python 3\.1[2-9]|Python 3\.[2-9][0-9]") {
        Write-Host "✓ Python version is compatible" -ForegroundColor Green
    } else {
        Write-Host "⚠ Warning: Python 3.12+ recommended, found: $pythonVersion" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ Python not found! Please install Python 3.12+" -ForegroundColor Red
    Write-Host "  Download from: https://www.python.org/downloads/" -ForegroundColor Cyan
    exit 1
}

# Step 2: Check Node.js
Write-Host "`n[2/8] Checking Node.js installation..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version 2>&1
    Write-Host "✓ Found Node.js: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Node.js not found! Please install Node.js LTS" -ForegroundColor Red
    Write-Host "  Download from: https://nodejs.org/" -ForegroundColor Cyan
    exit 1
}

# Step 3: Check MySQL
Write-Host "`n[3/8] Checking MySQL installation..." -ForegroundColor Yellow
try {
    $mysqlVersion = mysql --version 2>&1
    Write-Host "✓ Found: $mysqlVersion" -ForegroundColor Green
} catch {
    Write-Host "⚠ MySQL not found in PATH" -ForegroundColor Yellow
    Write-Host "  Make sure MySQL is installed and running" -ForegroundColor Cyan
    Write-Host "  Download from: https://dev.mysql.com/downloads/mysql/" -ForegroundColor Cyan
}

# Step 4: Create .env file
Write-Host "`n[4/8] Setting up .env file..." -ForegroundColor Yellow
if (Test-Path "backend\.env") {
    Write-Host "✓ .env file already exists" -ForegroundColor Green
    $overwrite = Read-Host "Do you want to overwrite it? (y/N)"
    if ($overwrite -ne "y") {
        Write-Host "  Keeping existing .env file" -ForegroundColor Cyan
    } else {
        Copy-Item "backend\.env.example" "backend\.env" -Force
        Write-Host "✓ Created new .env file from template" -ForegroundColor Green
    }
} else {
    Copy-Item "backend\.env.example" "backend\.env"
    Write-Host "✓ Created .env file from template" -ForegroundColor Green
}

# Step 5: Generate secret keys
Write-Host "`n[5/8] Generating secret keys..." -ForegroundColor Yellow
$secretKey = python -c "import secrets; print(secrets.token_urlsafe(32))" 2>&1
$sessionKey = python -c "import secrets; print(secrets.token_urlsafe(32))" 2>&1

Write-Host "  Generated SECRET_KEY: $secretKey" -ForegroundColor Cyan
Write-Host "  Generated SESSION_SECRET_KEY: $sessionKey" -ForegroundColor Cyan
Write-Host "  ⚠ IMPORTANT: Copy these to your backend\.env file!" -ForegroundColor Yellow

# Step 6: Create virtual environment
Write-Host "`n[6/8] Setting up Python virtual environment..." -ForegroundColor Yellow
if (Test-Path "backend\venv") {
    Write-Host "✓ Virtual environment already exists" -ForegroundColor Green
} else {
    Set-Location backend
    python -m venv venv
    if ($?) {
        Write-Host "✓ Created virtual environment" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to create virtual environment" -ForegroundColor Red
        Set-Location ..
        exit 1
    }
    Set-Location ..
}

# Step 7: Install Python dependencies
Write-Host "`n[7/8] Installing Python dependencies..." -ForegroundColor Yellow
Write-Host "  This may take a few minutes..." -ForegroundColor Cyan
Set-Location backend
& ".\venv\Scripts\Activate.ps1"
pip install -r requirements.txt --quiet
if ($?) {
    Write-Host "✓ Python dependencies installed" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to install Python dependencies" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Set-Location ..

# Step 8: Install Node.js dependencies
Write-Host "`n[8/8] Installing Node.js dependencies..." -ForegroundColor Yellow
Write-Host "  This may take a few minutes..." -ForegroundColor Cyan
Set-Location frontend
npm install --silent
if ($?) {
    Write-Host "✓ Node.js dependencies installed" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to install Node.js dependencies" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Set-Location ..

# Summary
Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "  Setup Complete! ✓" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Edit backend\.env file with your API keys:" -ForegroundColor White
Write-Host "   - Add your SECRET_KEY and SESSION_SECRET_KEY (generated above)" -ForegroundColor Cyan
Write-Host "   - Add MySQL database credentials" -ForegroundColor Cyan
Write-Host "   - Add Google Cloud credentials path" -ForegroundColor Cyan
Write-Host "   - (Optional) Add Unsplash API keys" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Set up MySQL database:" -ForegroundColor White
Write-Host "   mysql -u root -p" -ForegroundColor Cyan
Write-Host "   CREATE DATABASE learnweave_db;" -ForegroundColor Cyan
Write-Host "   CREATE USER 'learnweave_user'@'localhost' IDENTIFIED BY 'password';" -ForegroundColor Cyan
Write-Host "   GRANT ALL PRIVILEGES ON learnweave_db.* TO 'learnweave_user'@'localhost';" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Get Google Cloud credentials:" -ForegroundColor White
Write-Host "   - Go to: https://console.cloud.google.com/" -ForegroundColor Cyan
Write-Host "   - Create service account and download JSON key" -ForegroundColor Cyan
Write-Host "   - Save as: backend\google-credentials.json" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. Start ChromaDB (if using Docker):" -ForegroundColor White
Write-Host "   cd backend\chroma_db" -ForegroundColor Cyan
Write-Host "   docker-compose up -d" -ForegroundColor Cyan
Write-Host ""
Write-Host "5. Start the application:" -ForegroundColor White
Write-Host "   Backend:  cd backend; .\venv\Scripts\activate; uvicorn src.main:app --reload" -ForegroundColor Cyan
Write-Host "   Frontend: cd frontend; npm run dev" -ForegroundColor Cyan
Write-Host ""
Write-Host "For detailed instructions, see: LOCALHOST_SETUP.md" -ForegroundColor Yellow
Write-Host ""
