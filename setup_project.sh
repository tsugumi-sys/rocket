#!/bin/bash

# Exit on error
set -e

echo "📦 Setting up your fullstack Cloudflare project..."

# Ask user for backend directory name
read -p "Enter backend project directory name [default: backend]: " BACKEND_DIR
BACKEND_DIR=${BACKEND_DIR:-backend}

# Ask user for web directory name
read -p "Enter web project directory name [default: web]: " WEB_DIR
WEB_DIR=${WEB_DIR:-web}

### --- Setup Backend ---
echo "🔧 Creating backend project in ./$BACKEND_DIR using Hono..."
npm create hono@latest "$BACKEND_DIR" -- --template cloudflare-workers

echo "📦 Installing backend dependencies..."
cd "$BACKEND_DIR"
npm install
cd ..

### --- Setup Web (Remix + Cloudflare Pages) ---
echo "🌐 Creating web project in ./$WEB_DIR using Remix + Cloudflare Pages..."
npx create-remix@latest "$WEB_DIR" -- --cf-pages --yes

echo "📦 Installing web dependencies..."
cd "$WEB_DIR"
npm install
cd ..

### --- Project Structure & Stack ---
echo ""
echo "✅ Setup complete."
echo ""
echo "📁 Project Structure:"
echo ""
echo "."
echo "├── $BACKEND_DIR (Hono + Cloudflare Workers)"
echo "│   ├── src"
echo "│   └── wrangler.toml"
echo "└── $WEB_DIR (Remix + Cloudflare Pages)"
echo "    ├── app"
echo "    ├── public"
echo "    └── remix.config.js"
echo ""
echo "🧱 Tech Stack:"
echo "👉 Backend: Hono + Cloudflare Workers"
echo "👉 Web: Remix + Cloudflare Pages"
