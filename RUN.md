# 🚀 LearnWeave - How to Run

## ✅ What's Already Set Up
1. MySQL database (learnweave_db, user: learnweave_user, password: password)
2. ChromaDB running in Docker on port 8001
3. Google credentials configured
4. All Python & npm dependencies installed

## 📝 How to Run the Project

### 1️⃣ Start Backend (Terminal 1)
```bash
cd /home/kinux/projects/LearnWeave/backend
export PYTHONPATH=/home/kinux/projects/LearnWeave/backend
python3 -m uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
```

**Backend will be available at:**
- API: http://localhost:8000
- API Docs: http://localhost:8000/docs

### 2️⃣ Start Frontend (Terminal 2)
```bash
cd /home/kinux/projects/LearnWeave/frontend
npm run dev
```

**Frontend will be available at:** http://localhost:5173

### 3️⃣ Create Admin User (Terminal 3)
```bash
cd /home/kinux/projects/LearnWeave/backend
python3 create_admin.py --username admin --email admin@learnweave.com --password admin123
```

**Default Admin Credentials Created:**
- Username: `admin`
- Email: `admin@learnweave.com`
- Password: `admin123`

> ⚠️ **Important:** Change the admin password after first login!

---

## 🔑 API Keys Used
| Key | Status | Notes |
|-----|--------|-------|
| Google Cloud | ✅ | Set via `$GOOGLE_APPLICATION_CREDENTIALS` |
| MySQL | ✅ | localhost:3306, user: learnweave_user |
| ChromaDB | ✅ | Docker on port 8001 |

---

## 🐛 Troubleshooting

### If Backend Won't Start:
```bash
# Make sure ChromaDB is running
sudo docker ps | grep chroma

# If not running, start it:
cd /home/kinux/projects/LearnWeave/backend
sudo docker run -d --name learnweave-chromadb -p 8001:8000 chromadb/chroma:latest

# Check MySQL
mysql -u learnweave_user -p learnweave_db
```

### If Frontend Won't Start:
```bash
cd /home/kinux/projects/LearnWeave/frontend
rm -rf node_modules package-lock.json
npm install
npm run dev
```

---

## 📦 Project Structure
- **Backend**: FastAPI + MySQL + ChromaDB + Google Gemini AI
- **Frontend**: React + Vite + Tailwind CSS
- **Database**: MySQL (user data) + ChromaDB (vector embeddings)

---

## 🎯 Quick Commands

**Check Services:**
```bash
# Backend API
curl http://localhost:8000/

# ChromaDB
curl http://localhost:8001/api/v2/heartbeat

# MySQL
mysql -u learnweave_user -ppassword -e "SHOW DATABASES;"
```

**Stop Services:**
```bash
# Stop Docker ChromaDB
sudo docker stop learnweave-chromadb

# Backend & Frontend: Press Ctrl+C in their terminals
```
