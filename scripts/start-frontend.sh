#!/bin/bash
# ============================================
# LearnWeave - Start Frontend Script
# ============================================

echo "========================================"
echo "  Starting Frontend Server"
echo "========================================"
echo ""

# Navigate to frontend directory
cd "$(dirname "$0")/../frontend" || exit 1

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "✗ node_modules not found!"
    echo "  Install dependencies with: npm install"
    exit 1
fi

# Check if port 3000 is already in use
if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠ Port 3000 is already in use!"
    echo "  Stop existing frontend with: pkill -f 'node.*vite'"
    exit 1
fi

# Check if backend is running
if ! lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠ Warning: Backend is not running on port 8000"
    echo "  Start it with: ./scripts/start-backend.sh"
    echo ""
fi

echo "Starting Vite development server..."
echo ""
echo "Frontend will be available at:"
echo "  • App:  http://localhost:3000"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""
echo "----------------------------------------"
echo ""

# Start the frontend
npm run dev
