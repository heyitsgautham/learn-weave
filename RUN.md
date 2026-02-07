# 🚀 LearnWeave - How to Run

## 📦 Project Structure
- **Backend**: FastAPI + MySQL + ChromaDB + Google Gemini AI
- **Frontend**: React + Vite + Tailwind CSS
- **Database**: MySQL (user data) + ChromaDB (vector embeddings)

---

## 🔍 Step 0 — Check Requirements
```bash
./scripts/check-requirements.sh
```
Verifies **Python 3.12+**, **Node.js**, **MySQL**, **Docker**, and **npm** are installed.

---

## 📝 Step 1 — Configure Environment
```bash
cp backend/.env.example backend/.env
```
Edit `backend/.env` and fill in:
- `SECRET_KEY` / `SESSION_SECRET_KEY` — generate with: `python3 -c "import secrets; print(secrets.token_urlsafe(32))"`
- **Google Cloud credentials** — required for Gemini AI (see comments in `.env.example`)
- DB credentials can stay at defaults for local dev

---

## 📥 Step 2 — Install Dependencies

### Python (backend)

> **Optional but recommended:** Use a virtual environment to isolate dependencies:
> ```bash
> cd backend
> python3 -m venv venv
> source venv/bin/activate   # On Linux/macOS
> ```
> After activating, all `pip install` and `python3` commands will use the venv.

```bash
cd backend
pip install -r requirements.txt
```

### Node.js (frontend)
```bash
cd frontend
npm install
```

---

## 🐳 Step 3 — Start ChromaDB
```bash
./scripts/start-chromadb.sh
```
- ChromaDB: http://localhost:8001
- Heartbeat: http://localhost:8001/api/v1/heartbeat

---

## 🗄️ Step 4 — Setup Database
```bash
./scripts/setup-db.sh
```
This single script handles **everything** database-related:
1. Starts MySQL if not running
2. Creates the database & user
3. Creates all tables (via SQLAlchemy models)
4. Creates the admin user

**Default Admin Credentials:**
- Username: `admin` · Email: `admin@learnweave.local` · Password: `admin123`

> ⚠️ **Change the admin password after first login!**

---

## ▶️ Step 5 — Start Backend (Terminal 1)
```bash
./scripts/start-backend.sh
```
- API: http://localhost:8000
- Docs: http://localhost:8000/api/docs
- ReDoc: http://localhost:8000/api/redoc

> If using a venv, make sure it's activated before running.

---

## ▶️ Step 6 — Start Frontend (Terminal 2)
```bash
./scripts/start-frontend.sh
```
- App: http://localhost:3000

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

**View Logs:**
```bash
sudo docker logs learnweave-chromadb -f   # ChromaDB
```

---

## 📜 Available Scripts

| Script | Description |
|--------|-------------|
| `./scripts/check-requirements.sh` | Verify all dependencies are installed |
| `./scripts/setup-db.sh` | Setup MySQL database, tables & admin user |
| `./scripts/start-chromadb.sh` | Start ChromaDB Docker container |
| `./scripts/start-backend.sh` | Start backend server |
| `./scripts/start-frontend.sh` | Start frontend dev server |
