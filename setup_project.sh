#!/bin/bash

set -e  # Exit on error

echo "📦 Setting up your fullstack Cloudflare project..."

###
# Project Directory Setup
###

read -p "Enter backend project directory name [default: backend]: " BACKEND_DIR
BACKEND_DIR=${BACKEND_DIR:-backend}

# Set CLOUDFLARE_ACCOUNT_ID only if it's not already set
if [ -z "$CLOUDFLARE_ACCOUNT_ID" ]; then
  echo "⚠️ More than one account available but unable to select one in non-interactive mode."
  # Show the current authenticated Cloudflare account
  echo "👤 Checking Cloudflare account..."
  npx wrangler whoami
  read -p "Please enter your Cloudflare account ID: " CLOUDFLARE_ACCOUNT_ID

  if [ -z "$CLOUDFLARE_ACCOUNT_ID" ]; then
    echo "❌ Cloudflare account ID is required. Aborting."
    exit 1
  fi
  echo "Using account ID: $CLOUDFLARE_ACCOUNT_ID"

  # Set CLOUDFLARE_ACCOUNT_ID as environment variable
  export CLOUDFLARE_ACCOUNT_ID="$CLOUDFLARE_ACCOUNT_ID"
  echo "Environment variable CLOUDFLARE_ACCOUNT_ID set to $CLOUDFLARE_ACCOUNT_ID"
else
  echo "CLOUDFLARE_ACCOUNT_ID is already set to $CLOUDFLARE_ACCOUNT_ID"
fi


read -p "Enter web directory name [default: web]: " WEB_DIR
WEB_DIR=${WEB_DIR:-web}


./setup_backend.sh $BACKEND_DIR $DB_NAME $CLOUDFLARE_ACCOUNT_ID

./setup_web.sh $WEB_DIR


###
# Summary
###

echo ""
echo "✅ Setup complete."
echo ""
echo "📁 Project Structure:"
echo "."
echo "├── $BACKEND_DIR (Hono + Cloudflare Workers + Drizzle ORM)"
echo "│   ├── src"
echo "│   │   └── db"
echo "│   │       └── schema.ts"
echo "│   ├── drizzle.config.ts"
echo "│   └── wrangler.jsonc"
echo "└── $WEB_DIR (React Router + Cloudflare Workers)"
echo "    ├── app"
echo ""
echo "🧱 Tech Stack:"
echo "👉 Backend: Hono + Cloudflare Workers + Drizzle ORM (D1)"
echo "👉 Web: React Router + Cloudflare Workers"

