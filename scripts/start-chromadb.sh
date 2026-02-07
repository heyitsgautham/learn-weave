#!/bin/bash
# ============================================
# LearnWeave - Start ChromaDB Script
# ============================================

echo "========================================"
echo "  Starting ChromaDB"
echo "========================================"
echo ""

# Check if Docker is running
if ! docker ps &> /dev/null; then
    echo "✗ Docker is not running!"
    echo "  Start with: sudo systemctl start docker"
    exit 1
fi

# Navigate to backend directory
cd "$(dirname "$0")/../backend" || exit 1

# Check if ChromaDB container is already running
if docker ps --format '{{.Names}}' | grep -q "learnweave-chromadb"; then
    echo "✓ ChromaDB is already running"
    echo ""
    echo "Services:"
    echo "  • ChromaDB:  http://localhost:8001"
    echo ""
    exit 0
fi

echo "Starting ChromaDB container..."
sudo docker compose up -d chromadb

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ ChromaDB started successfully!"
    echo ""
    echo "Services:"
    echo "  • ChromaDB:  http://localhost:8001"
    echo "  • Heartbeat: http://localhost:8001/api/v1/heartbeat"
    echo ""
    echo "Check status: docker ps"
    echo "View logs:    docker logs learnweave-chromadb -f"
    echo "Stop:         docker stop learnweave-chromadb"
else
    echo ""
    echo "✗ Failed to start ChromaDB"
    echo "  Check logs: sudo docker compose logs chromadb"
    exit 1
fi
