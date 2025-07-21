#!/bin/bash

set -e  # Exit on error

WEB_DIR="$1"


echo "🌐 Creating web project in ./$WEB_DIR using React Router + Cloudflare Workers ..."
npm create cloudflare@latest -- "$WEB_DIR" --no-git --no-deploy --framework=react-router

echo "📦 Installing web dependencies..."
cd "$WEB_DIR"
npm install --legacy-peer-deps

###
# Create .dev.vars file and insert BACKEND_SERVER_URL
###

echo "Creating .dev.vars file..."

cat <<EOF > .dev.vars
BACKEND_SERVER_URL="http://localhost:8787"
EOF

echo "✅ .dev.vars file created with BACKEND_SERVER_URL."



cd ..

