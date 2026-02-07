#!/bin/bash

# Quick Google OAuth Setup using GCloud CLI
# This script helps you quickly create OAuth credentials in GCP

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Google OAuth Quick Setup (GCP)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${YELLOW}⚠ Google Cloud CLI not found${NC}"
    echo "Install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Get current project
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
    echo -e "${YELLOW}⚠ No active GCloud project${NC}"
    echo "Set one with: gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

echo -e "${GREEN}✓${NC} Active Project: ${BLUE}$PROJECT_ID${NC}"
echo ""

# Check if user is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    echo -e "${YELLOW}⚠ Not authenticated${NC}"
    echo "Run: gcloud auth login"
    exit 1
fi

ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1)
echo -e "${GREEN}✓${NC} Authenticated as: ${BLUE}$ACCOUNT${NC}"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "OAuth Client Creation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "You need to create OAuth 2.0 credentials in GCP Console."
echo "Unfortunately, gcloud CLI doesn't support creating OAuth clients directly."
echo ""
echo "Opening GCP Console for you..."
echo ""

# Construct the URL
CONSOLE_URL="https://console.cloud.google.com/apis/credentials?project=$PROJECT_ID"

echo -e "${BLUE}→${NC} $CONSOLE_URL"
echo ""

# Try to open the URL
if command -v xdg-open &> /dev/null; then
    xdg-open "$CONSOLE_URL" 2>/dev/null
elif command -v open &> /dev/null; then
    open "$CONSOLE_URL" 2>/dev/null
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Steps to follow in the Console:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Click 'CREATE CREDENTIALS' at the top"
echo "2. Select 'OAuth client ID'"
echo "3. If prompted, configure OAuth consent screen:"
echo "   • User Type: External (for testing)"
echo "   • Add your email as test user"
echo "4. Application type: 'Web application'"
echo "5. Name: 'Learn-Weave-Dev' (or any name)"
echo "6. Authorized redirect URIs - Click 'ADD URI':"
echo "   • http://localhost:8000/api/auth/google/callback"
echo "7. Click 'CREATE'"
echo "8. Copy the Client ID and Client Secret"
echo ""

read -p "Press Enter once you have the credentials..."
echo ""

# Prompt for credentials
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
read -p "Enter Google Client ID: " CLIENT_ID
read -s -p "Enter Google Client Secret: " CLIENT_SECRET
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Validate inputs
if [ -z "$CLIENT_ID" ] || [ -z "$CLIENT_SECRET" ]; then
    echo -e "${YELLOW}⚠ Client ID and Secret cannot be empty${NC}"
    exit 1
fi

# Update .env file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$(dirname "$SCRIPT_DIR")/backend/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}⚠ .env file not found: $ENV_FILE${NC}"
    exit 1
fi

echo "Updating .env file..."

# Backup .env
cp "$ENV_FILE" "$ENV_FILE.backup"

# Update or add credentials
if grep -q "^GOOGLE_CLIENT_ID=" "$ENV_FILE"; then
    # macOS-compatible sed
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|^GOOGLE_CLIENT_ID=.*|GOOGLE_CLIENT_ID=$CLIENT_ID|" "$ENV_FILE"
        sed -i '' "s|^GOOGLE_CLIENT_SECRET=.*|GOOGLE_CLIENT_SECRET=$CLIENT_SECRET|" "$ENV_FILE"
    else
        sed -i "s|^GOOGLE_CLIENT_ID=.*|GOOGLE_CLIENT_ID=$CLIENT_ID|" "$ENV_FILE"
        sed -i "s|^GOOGLE_CLIENT_SECRET=.*|GOOGLE_CLIENT_SECRET=$CLIENT_SECRET|" "$ENV_FILE"
    fi
    echo -e "${GREEN}✓${NC} Updated existing credentials"
else
    # Add new credentials
    {
        echo ""
        echo "# Google OAuth Credentials"
        echo "GOOGLE_CLIENT_ID=$CLIENT_ID"
        echo "GOOGLE_CLIENT_SECRET=$CLIENT_SECRET"
    } >> "$ENV_FILE"
    echo -e "${GREEN}✓${NC} Added new credentials"
fi

# Uncomment if commented
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' 's/^# GOOGLE_CLIENT_ID=/GOOGLE_CLIENT_ID=/' "$ENV_FILE"
    sed -i '' 's/^# GOOGLE_CLIENT_SECRET=/GOOGLE_CLIENT_SECRET=/' "$ENV_FILE"
else
    sed -i 's/^# GOOGLE_CLIENT_ID=/GOOGLE_CLIENT_ID=/' "$ENV_FILE"
    sed -i 's/^# GOOGLE_CLIENT_SECRET=/GOOGLE_CLIENT_SECRET=/' "$ENV_FILE"
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Setup Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Next steps:"
echo "1. Restart your backend: cd backend && python run_dev.py"
echo "2. Test OAuth: http://localhost:8000/api/auth/login/google"
echo ""
echo "Backup created: $ENV_FILE.backup"
echo ""
