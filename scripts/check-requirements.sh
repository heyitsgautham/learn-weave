#!/bin/bash
# ============================================
# LearnWeave - Requirements Check Script
# ============================================

echo "========================================"
echo "  LearnWeave - Requirements Check"
echo "========================================"
echo ""

ERROR_COUNT=0

# Check Python
echo "[1/5] Checking Python installation..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo "✓ Found: $PYTHON_VERSION"
    
    # Check if version is 3.12+
    PYTHON_MAJOR=$(python3 -c 'import sys; print(sys.version_info.major)')
    PYTHON_MINOR=$(python3 -c 'import sys; print(sys.version_info.minor)')
    
    if [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -ge 12 ]; then
        echo "✓ Python version is compatible (3.12+)"
    else
        echo "⚠ Warning: Python 3.12+ recommended, found: $PYTHON_VERSION"
    fi
else
    echo "✗ Python not found!"
    echo "  Install with: sudo dnf install python3"
    ((ERROR_COUNT++))
fi

# Check Node.js
echo ""
echo "[2/5] Checking Node.js installation..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "✓ Found Node.js: $NODE_VERSION"
else
    echo "✗ Node.js not found!"
    echo "  Install with: sudo dnf install nodejs npm"
    ((ERROR_COUNT++))
fi

# Check MySQL
echo ""
echo "[3/5] Checking MySQL installation..."
if command -v mysql &> /dev/null; then
    MYSQL_VERSION=$(mysql --version)
    echo "✓ Found: $MYSQL_VERSION"
    
    # Check if MySQL is running
    if systemctl is-active --quiet mysqld; then
        echo "✓ MySQL service is running"
    else
        echo "⚠ MySQL service is not running"
        echo "  Start with: sudo systemctl start mysqld"
    fi
else
    echo "✗ MySQL not found!"
    echo "  Install with: sudo dnf install mysql-server"
    ((ERROR_COUNT++))
fi

# Check Docker
echo ""
echo "[4/5] Checking Docker installation..."
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    echo "✓ Found: $DOCKER_VERSION"
    
    # Check if Docker is running
    if docker ps &> /dev/null; then
        echo "✓ Docker daemon is running"
    else
        echo "⚠ Docker daemon is not running"
        echo "  Start with: sudo systemctl start docker"
    fi
else
    echo "✗ Docker not found!"
    echo "  Install with: sudo dnf install docker"
    ((ERROR_COUNT++))
fi

# Check environment files
echo ""
echo "[5/5] Checking configuration files..."
if [ -f "backend/.env" ]; then
    echo "✓ backend/.env exists"
else
    echo "✗ backend/.env not found!"
    echo "  Copy from: cp backend/.env.example backend/.env"
    ((ERROR_COUNT++))
fi

if [ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    echo "✓ Google credentials found at: $GOOGLE_APPLICATION_CREDENTIALS"
else
    echo "⚠ Google credentials not found"
    echo "  Set GOOGLE_APPLICATION_CREDENTIALS environment variable"
fi

# Summary
echo ""
echo "========================================"
if [ $ERROR_COUNT -eq 0 ]; then
    echo "  ✓ All Requirements Met!"
else
    echo "  ✗ $ERROR_COUNT Error(s) Found!"
fi
echo "========================================"
echo ""

if [ $ERROR_COUNT -eq 0 ]; then
    echo "✓ Your system is ready to run LearnWeave!"
    echo ""
    echo "Next steps:"
    echo "  1. Start ChromaDB:  ./scripts/start-chromadb.sh"
    echo "  2. Start backend:   ./scripts/start-backend.sh"
    echo "  3. Start frontend:  ./scripts/start-frontend.sh"
    echo "  Or start all:       ./scripts/start-all.sh"
else
    echo "Please fix the issues above before running LearnWeave."
fi
echo ""

exit $ERROR_COUNT
