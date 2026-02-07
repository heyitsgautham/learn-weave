# 🚀 LearnWeave - How to Run

## ✅ What's Already Set Up
1. MySQL database (learnweave_db, user: learnweave_user, password: password)
2. ChromaDB running in Docker on port 8001
3. Google credentials configured
4. All Python & npm dependencies installed

---

## 📝 How to Run the Project

### 🔥 Start Everything at Once
```bash
./scripts/start-all.sh
```
This starts **ChromaDB → Backend → Frontend** in order and waits for each to be ready.

### Or Start Services Individually

#### 1️⃣ Start ChromaDB
```bash
./scripts/start-chromadb.sh
```
- ChromaDB: http://localhost:8001
- Heartbeat: http://localhost:8001/api/v1/heartbeat

#### 2️⃣ Start Backend (Terminal 1)
```bash
./scripts/start-backend.sh
```
- API: http://localhost:8000
- Docs: http://localhost:8000/api/docs
- ReDoc: http://localhost:8000/api/redoc

> ⚠️ Requires `.env` file in `backend/`. Copy from `.env.example` if missing.

#### 3️⃣ Start Frontend (Terminal 2)
```bash
./scripts/start-frontend.sh
```
- App: http://localhost:3000

> ⚠️ Requires `node_modules/` in `frontend/`. Run `npm install` if missing.

---

### 4️⃣ Create Admin User (one-time)
```bash
cd backend
python3 create_admin.py --username admin --email admin@learnweave.com --password admin123
```

**Default Admin Credentials:**
- Username: `admin`
- Email: `admin@learnweave.com`
- Password: `admin123`

> ⚠️ **Important:** Change the admin password after first login!

---

## 🔍 Check Requirements
```bash
./scripts/check-requirements.sh
```
Verifies Python 3.12+, Node.js, MySQL, Docker, and npm are installed.

---

## 🔑 API Keys Used
| Key | Status | Notes |
|-----|--------|-------|
| Google Cloud | ✅ | Set via `$GOOGLE_APPLICATION_CREDENTIALS` |
| MySQL | ✅ | localhost:3306, user: learnweave_user |
| ChromaDB | ✅ | Docker on port 8001 |

---

## 📦 Project Structure
- **Backend**: FastAPI + MySQL + ChromaDB + Google Gemini AI
- **Frontend**: React + Vite + Tailwind CSS
- **Database**: MySQL (user data) + ChromaDB (vector embeddings)

---

## 🐛 Troubleshooting

### If Backend Won't Start:
```bash
# Make sure ChromaDB is running
sudo docker ps | grep chroma

# If not running:
./scripts/start-chromadb.sh

# Check MySQL
sudo systemctl start mysqld
mysql -u learnweave_user -p learnweave_db
```

### If Frontend Won't Start:
```bash
cd frontend
rm -rf node_modules package-lock.json
npm install
npm run dev
```

---

## 🎯 Quick Commands

**Check Services:**
```bash
# Backend API
curl http://localhost:8000/

# ChromaDB
curl http://localhost:8001/api/v1/heartbeat

# MySQL
mysql -u learnweave_user -ppassword -e "SHOW DATABASES;"
```

**Stop Services:**
```bash
# Stop all
pkill -f 'uvicorn src.main:app'   # Backend
pkill -f 'node.*vite'             # Frontend
sudo docker stop learnweave-chromadb  # ChromaDB

# Or press Ctrl+C in respective terminals
```

**View Logs (when started via start-all.sh):**
```bash
tail -f /tmp/learnweave-backend.log   # Backend
tail -f /tmp/learnweave-frontend.log  # Frontend
sudo docker logs learnweave-chromadb -f   # ChromaDB
```

---

## 📜 Available Scripts

| Script | Description |
|--------|-------------|
| `./scripts/start-all.sh` | Start all services (ChromaDB + Backend + Frontend) |
| `./scripts/start-backend.sh` | Start backend server only |
| `./scripts/start-frontend.sh` | Start frontend dev server only |
| `./scripts/start-chromadb.sh` | Start ChromaDB Docker container only |
| `./scripts/check-requirements.sh` | Verify all dependencies are installed |
