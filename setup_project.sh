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

### --- Setup Drizzle ---
echo "🌾 Setting up Drizzle ORM..."
npm install drizzle-orm@latest --save
npm install -D drizzle-kit@latest

echo "🛠️ Initializing Drizzle config..."
cat <<EOF > drizzle.config.ts
import type { Config } from "drizzle-kit";

export default {
  schema: "./src/db/schema.ts",
  out: "./drizzle",
  dialect: "sqlite",
  driver: "d1-http",
} satisfies Config;
EOF

echo "📁 Creating example schema..."
mkdir -p src/db
cat <<EOF > src/db/schema.ts
import { sqliteTable, text, int } from "drizzle-orm/sqlite-core";

export const users = sqliteTable("users", {
  id: int("id").primaryKey({ autoIncrement: true }),
  email: text("email").notNull(),
});
EOF

### --- Setup DB
echo "🗃️ Setting up D1 Database..."
read -p "Enter D1 database name: " DB_NAME

WRANGLER_FILE="wrangler.jsonc"

# Create the D1 database
DB_OUTPUT=$(npx wrangler d1 create "$DB_NAME")

# Extract database_id from JSON in stdout
DB_ID=$(echo "$DB_OUTPUT" | grep -oE '"database_id":\s*"[^"]+"' | cut -d'"' -f4)

if [ -z "$DB_ID" ]; then
  echo "❌ Failed to extract D1 database ID. Aborting."
  exit 1
fi

echo "✅ D1 created. ID: $DB_ID"

# Strip comments, inject config, and write back
npx strip-json-comments "$WRANGLER_FILE" \
| jq --arg db_name "$DB_NAME" \
     --arg db_id "$DB_ID" \
     '.d1_databases = [
        {
          binding: "DB",
          database_name: $db_name,
          database_id: $db_id,
          migrations_dir: "drizzle"
        }
      ]' \
> "$WRANGLER_FILE.tmp" && mv "$WRANGLER_FILE.tmp" "$WRANGLER_FILE"

echo "✅ Updated $WRANGLER_FILE with D1 config."

### --- Add DB commands to package.json ---
echo "📝 Adding DB scripts to backend/package.json..."

if command -v jq >/dev/null 2>&1; then
  tmpfile=$(mktemp)
  jq --arg db_name "$DB_NAME" \
    '.scripts += {
      "db:generate": "drizzle-kit generate",
      "db:local:migration": "wrangler d1 migrations apply \($db_name) --local",
      "db:remote:migration": "wrangler d1 migrations apply \($db_name) --remote"
    }' package.json > "$tmpfile" && mv "$tmpfile" package.json
else
  echo "⚠️ 'jq' not found. Please install jq to automatically insert db scripts into package.json."
  echo "Alternatively, add these manually to backend/package.json:"
  echo '  "db:generate": "drizzle-kit generate",'
  echo "  \"db:local:migration\": \"wrangler d1 migrations apply $DB_NAME --local\","
  echo "  \"db:remote:migration\": \"wrangler d1 migrations apply $DB_NAME --remote\""
fi


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
echo "├── $BACKEND_DIR (Hono + Cloudflare Workers + Drizzle ORM)"
echo "│   ├── src"
echo "│   │   └── db"
echo "│   │       └── schema.ts"
echo "│   ├── drizzle.config.ts"
echo "│   └── wrangler.toml"
echo "└── $WEB_DIR (Remix + Cloudflare Pages)"
echo "    ├── app"
echo "    ├── public"
echo "    └── remix.config.js"
echo ""
echo "🧱 Tech Stack:"
echo "👉 Backend: Hono + Cloudflare Workers + Drizzle ORM (D1)"
echo "👉 Web: Remix + Cloudflare Pages"

