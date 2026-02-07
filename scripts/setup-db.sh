#!/bin/bash
# ============================================
# LearnWeave - Database Setup & Health Check
# ============================================
# Just run it. It checks everything and fixes
# whatever is missing — no flags needed.
#
# Usage:
#   ./scripts/setup-db.sh
# ============================================

set -euo pipefail

# ── Colours ──────────────────────────────────────────────
GREEN='\033[0;92m'
RED='\033[0;91m'
YELLOW='\033[0;93m'
CYAN='\033[0;96m'
BOLD='\033[1m'
RESET='\033[0m'

ok()   { echo -e "  ${GREEN}✔${RESET} $1"; }
fail() { echo -e "  ${RED}✘${RESET} $1"; }
warn() { echo -e "  ${YELLOW}⚠${RESET} $1"; }
info() { echo -e "  ${CYAN}ℹ${RESET} $1"; }
header() { echo -e "\n${BOLD}────────────────────────────────────────────────────────────\n  $1\n────────────────────────────────────────────────────────────${RESET}"; }

# ── Resolve paths ────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKEND_DIR="$PROJECT_DIR/backend"
ENV_FILE="$BACKEND_DIR/.env"

echo -e "\n${BOLD}🔍  LearnWeave — Database Setup${RESET}"

# ── 1. Load .env ─────────────────────────────────────────
header "1 · Loading Configuration"

if [ ! -f "$ENV_FILE" ]; then
    warn ".env not found — creating from .env.example"
    if [ -f "$BACKEND_DIR/.env.example" ]; then
        cp "$BACKEND_DIR/.env.example" "$ENV_FILE"
        ok "Created .env from .env.example"
        info "Edit $ENV_FILE with your real credentials if needed"
    else
        fail "No .env or .env.example found at $BACKEND_DIR"
        exit 1
    fi
fi

# Source .env (KEY=VALUE lines, skip comments/blanks)
set -a
# shellcheck disable=SC1090
source <(grep -v '^\s*#' "$ENV_FILE" | grep -v '^\s*$')
set +a

# DB credentials
DB_USER="${DB_USER:-learnweave_user}"
DB_PASSWORD="${DB_PASSWORD:-learnweave_pass}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-3306}"
DB_NAME="${DB_NAME:-learnweave_db}"

# Admin credentials
ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@learnweave.local}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin123}"

ok "Loaded .env"
info "DB: ${DB_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
info "Admin: ${ADMIN_USERNAME} (${ADMIN_EMAIL})"

# ── Helper: run a MySQL query ────────────────────────────
run_mysql() {
    mysql -u"$DB_USER" -p"$DB_PASSWORD" -h"$DB_HOST" -P"$DB_PORT" "$@" 2>/dev/null
}

run_mysql_root() {
    if command -v sudo &>/dev/null && sudo -n true 2>/dev/null; then
        sudo mysql "$@" 2>/dev/null
    else
        mysql "$@" 2>/dev/null
    fi
}

# ── 2. Check MySQL is running ────────────────────────────
header "2 · MySQL Service"

MYSQL_RUNNING=false
if command -v systemctl &>/dev/null && systemctl is-active --quiet mysqld 2>/dev/null; then
    ok "MySQL service is running (mysqld)"
    MYSQL_RUNNING=true
elif command -v systemctl &>/dev/null && systemctl is-active --quiet mysql 2>/dev/null; then
    ok "MySQL service is running (mysql)"
    MYSQL_RUNNING=true
elif pgrep -x mysqld &>/dev/null; then
    ok "MySQL process is running"
    MYSQL_RUNNING=true
fi

if [ "$MYSQL_RUNNING" = false ]; then
    warn "MySQL is not running — trying to start it …"
    if command -v systemctl &>/dev/null; then
        if sudo systemctl start mysqld 2>/dev/null || sudo systemctl start mysql 2>/dev/null; then
            ok "MySQL started"
        else
            fail "Could not start MySQL. Start it manually:"
            echo "       sudo systemctl start mysqld"
            exit 1
        fi
    else
        fail "Cannot start MySQL automatically."
        echo "       Start it manually and re-run this script."
        exit 1
    fi
fi

# ── 3. Database & User ───────────────────────────────────
header "3 · Database & User"

if echo "SELECT 1;" | run_mysql "$DB_NAME" &>/dev/null; then
    ok "Database '${DB_NAME}' exists and '${DB_USER}' can connect"
else
    info "Setting up database '${DB_NAME}' and user '${DB_USER}' …"
    if run_mysql_root -e "
        CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
        CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
        FLUSH PRIVILEGES;
    "; then
        ok "Database '${DB_NAME}' and user '${DB_USER}' created"
    else
        fail "Could not create database (needs root/sudo access)"
        echo "       Run manually:  sudo mysql < backend/setup_database.sql"
        exit 1
    fi

    # Verify
    if echo "SELECT 1;" | run_mysql "$DB_NAME" &>/dev/null; then
        ok "Connection verified"
    else
        fail "Still cannot connect after creating DB. Check credentials in .env"
        exit 1
    fi
fi

# ── 4. Tables ─────────────────────────────────────────────
header "4 · Tables"

EXPECTED_TABLES=(
    "chapters"
    "chats"
    "courses"
    "documents"
    "images"
    "notes"
    "practice_questions"
    "usages"
    "users"
)

ACTUAL_TABLES=$(echo "SHOW TABLES;" | run_mysql "$DB_NAME" --skip-column-names 2>/dev/null || true)

MISSING_TABLES=()
for table in "${EXPECTED_TABLES[@]}"; do
    if echo "$ACTUAL_TABLES" | grep -qw "$table"; then
        ok "Table '${table}'"
    else
        warn "Table '${table}' missing"
        MISSING_TABLES+=("$table")
    fi
done

# Show extra tables (info only)
if [ -n "$ACTUAL_TABLES" ]; then
    while IFS= read -r actual_table; do
        [ -z "$actual_table" ] && continue
        FOUND=false
        for expected in "${EXPECTED_TABLES[@]}"; do
            [ "$actual_table" = "$expected" ] && FOUND=true && break
        done
        [ "$FOUND" = false ] && info "Extra table '${actual_table}' (not in models — probably fine)"
    done <<< "$ACTUAL_TABLES"
fi

# Create missing tables
if [ ${#MISSING_TABLES[@]} -gt 0 ]; then
    echo ""
    info "Creating missing tables …"
    cd "$BACKEND_DIR"
    if python3 -c "
import sys
sys.path.insert(0, '.')
from src.db.database import engine, Base
from src.db.models import db_user, db_course, db_chat, db_file, db_note, db_usage
Base.metadata.create_all(bind=engine)
"; then
        ok "Tables created"
    else
        fail "Failed to create tables — check Python errors above"
        exit 1
    fi

    # Verify each one
    ACTUAL_TABLES=$(echo "SHOW TABLES;" | run_mysql "$DB_NAME" --skip-column-names 2>/dev/null || true)
    STILL_MISSING=0
    for table in "${MISSING_TABLES[@]}"; do
        if echo "$ACTUAL_TABLES" | grep -qw "$table"; then
            ok "Table '${table}' created"
        else
            fail "Table '${table}' still missing!"
            STILL_MISSING=$((STILL_MISSING + 1))
        fi
    done
    [ "$STILL_MISSING" -gt 0 ] && exit 1
fi

# ── 5. Admin user ─────────────────────────────────────────
header "5 · Admin User"

ADMIN_EXISTS=$(echo "SELECT username FROM users WHERE is_admin = 1 LIMIT 1;" | run_mysql "$DB_NAME" --skip-column-names 2>/dev/null || true)

if [ -n "$ADMIN_EXISTS" ]; then
    ok "Admin user exists: '${ADMIN_EXISTS}'"
else
    info "Creating admin '${ADMIN_USERNAME}' (${ADMIN_EMAIL}) …"
    cd "$BACKEND_DIR"
    if python3 -c "
import sys, os, uuid
from datetime import datetime, timezone
sys.path.insert(0, '.')
from src.db.database import SessionLocal
from src.core.security import get_password_hash
from src.db.models.db_user import User

db = SessionLocal()
try:
    admin = User(
        id=str(uuid.uuid4()),
        username='${ADMIN_USERNAME}',
        email='${ADMIN_EMAIL}',
        hashed_password=get_password_hash('${ADMIN_PASSWORD}'),
        is_admin=True,
        is_active=True,
        created_at=datetime.now(timezone.utc)
    )
    db.add(admin)
    db.commit()
finally:
    db.close()
"; then
        ok "Admin '${ADMIN_USERNAME}' created"
    else
        fail "Could not create admin user — check errors above"
        exit 1
    fi
fi

# ── Done ──────────────────────────────────────────────────
header "Done"
echo -e "  ${GREEN}${BOLD}✔ Database is ready!${RESET}\n"
exit 0
