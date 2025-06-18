#!/bin/bash

set -e  # Exit on error

echo "📦 Setting up your fullstack Cloudflare project..."

###
# Project Directory Setup
###

read -p "Enter backend project directory name [default: backend]: " BACKEND_DIR
BACKEND_DIR=${BACKEND_DIR:-backend}

read -p "Enter web directory name [default: web]: " WEB_DIR
WEB_DIR=${WEB_DIR:-web}

read -p "Enter D1 database name: " DB_NAME


./setup_backend.sh $BACKEND_DIR $DB_NAME

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
echo "└── $WEB_DIR (Remix + Cloudflare Pages)"
echo "    ├── app"
echo "    ├── public"
echo "    └── remix.config.js"
echo ""
echo "🧱 Tech Stack:"
echo "👉 Backend: Hono + Cloudflare Workers + Drizzle ORM (D1)"
echo "👉 Web: Remix + Cloudflare Pages"

