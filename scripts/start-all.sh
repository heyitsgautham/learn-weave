#!/bin/bash
# ============================================
# LearnWeave - Start All Services Script
# ============================================

echo "========================================"
echo "  LearnWeave - Starting All Services"
echo "========================================"
echo ""

# Navigate to project root
cd "$(dirname "$0")/.." || exit 1

# Function to check if a port is in use
check_port() {
    lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null 2>&1
}

# Function to wait for service
wait_for_service() {
    local url=$1
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s "$url" > /dev/null 2>&1; then
            return 0
        fi
        sleep 1
        ((attempt++))
    done
    return 1
}

# Step 1: Start ChromaDB
echo "[1/3] Starting ChromaDB..."
if docker ps --format '{{.Names}}' | grep -q "learnweave-chromadb"; then
    echo "✓ ChromaDB is already running"
else
    cd backend || exit 1
    sudo docker compose up -d chromadb
    if [ $? -eq 0 ]; then
        echo "✓ ChromaDB started"
    else
        echo "✗ Failed to start ChromaDB"
        exit 1
    fi
    cd ..
fi

echo ""
echo "Waiting for ChromaDB to be ready..."
sleep 3

# Step 2: Start Backend
echo ""
echo "[2/3] Starting Backend..."
if check_port 8000; then
    echo "⚠ Backend is already running on port 8000"
else
    cd backend || exit 1
    echo "  Starting backend in background..."
    nohup python3 -m uvicorn src.main:app --reload --host 0.0.0.0 --port 8000 > /tmp/learnweave-backend.log 2>&1 &
    BACKEND_PID=$!
    echo "  Backend PID: $BACKEND_PID"
    cd ..
    
    echo "  Waiting for backend to be ready..."
    if wait_for_service "http://localhost:8000/api/docs"; then
        echo "✓ Backend started successfully"
    else
        echo "⚠ Backend may still be starting (check logs: tail -f /tmp/learnweave-backend.log)"
    fi
fi

# Step 3: Start Frontend
echo ""
echo "[3/3] Starting Frontend..."
if check_port 3000; then
    echo "⚠ Frontend is already running on port 3000"
else
    cd frontend || exit 1
    echo "  Starting frontend in background..."
    nohup npm run dev > /tmp/learnweave-frontend.log 2>&1 &
    FRONTEND_PID=$!
    echo "  Frontend PID: $FRONTEND_PID"
    cd ..
    
    echo "  Waiting for frontend to be ready..."
    sleep 5
    if wait_for_service "http://localhost:3000"; then
        echo "✓ Frontend started successfully"
    else
        echo "⚠ Frontend may still be starting (check logs: tail -f /tmp/learnweave-frontend.log)"
    fi
fi

# Summary
echo ""
echo "========================================"
echo "  ✓ All Services Started!"
echo "========================================"
echo ""
echo "Services:"
echo "  • ChromaDB:      http://localhost:8001"
echo "  • Backend API:   http://localhost:8000"
echo "  • API Docs:      http://localhost:8000/api/docs"
echo "  • Frontend App:  http://localhost:3000"
echo ""
echo "Logs:"
echo "  • Backend:   tail -f /tmp/learnweave-backend.log"
echo "  • Frontend:  tail -f /tmp/learnweave-frontend.log"
echo "  • ChromaDB:  docker logs learnweave-chromadb -f"
echo ""
echo "Stop all services:"
echo "  • Backend:   pkill -f 'uvicorn src.main:app'"
echo "  • Frontend:  pkill -f 'node.*vite'"
echo "  • ChromaDB:  docker stop learnweave-chromadb"
echo ""
echo "🚀 Open http://localhost:3000 in your browser!"
echo ""
