#!/bin/bash

###
# Setup Backend (Hono + Cloudflare Workers)
###

BACKEND_DIR="$1"
DB_NAME="$2"

echo "🔧 Creating backend project in ./$BACKEND_DIR using Hono..."
npm create hono@latest "$BACKEND_DIR" -- --template cloudflare-workers --pm npm --install

echo "📦 Installing backend dependencies..."
cd "$BACKEND_DIR"
npm install

###
# Setup Drizzle ORM
###

echo "🌾 Installing Drizzle ORM..."
npm install drizzle-orm@latest --save
npm install -D drizzle-kit@latest

echo "🛠️ Creating drizzle.config.ts..."
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

###
# Setup D1 Database
###

echo "🗃️ Setting up D1 Database..."

WRANGLER_FILE="wrangler.jsonc"
DB_OUTPUT=$(npx wrangler d1 create "$DB_NAME")

# Extract DB ID
DB_ID=$(echo "$DB_OUTPUT" | grep -oE '"database_id":\s*"[^"]+"' | cut -d'"' -f4)
if [ -z "$DB_ID" ]; then
  echo "❌ Failed to extract D1 database ID. Aborting."
  exit 1
fi

echo "✅ D1 created. ID: $DB_ID"

# Strip comments, update wrangler.jsonc
npx strip-json-comments "$WRANGLER_FILE" \
| jq --arg db_name "$DB_NAME" --arg db_id "$DB_ID" \
     '.d1_databases = [
        {
          binding: "DB",
          database_name: $db_name,
          database_id: $db_id,
          migrations_dir: "drizzle"
        }
      ]' > "$WRANGLER_FILE.tmp" && mv "$WRANGLER_FILE.tmp" "$WRANGLER_FILE"

npm run cf-typegen

echo "✅ Updated $WRANGLER_FILE with D1 config."

###
# Add DB Scripts to package.json
###

echo "📝 Adding DB scripts to package.json..."
if command -v jq >/dev/null 2>&1; then
  tmpfile=$(mktemp)
  jq --arg db_name "$DB_NAME" \
    '.scripts += {
      "db:generate": "drizzle-kit generate",
      "db:local:migration": "wrangler d1 migrations apply \($db_name) --local",
      "db:remote:migration": "wrangler d1 migrations apply \($db_name) --remote"
    }' package.json > "$tmpfile" && mv "$tmpfile" package.json
else
  echo "⚠️ 'jq' not found. Please install jq to update scripts automatically."
  echo "Add these manually to package.json:"
  echo '  "db:generate": "drizzle-kit generate",'
  echo "  \"db:local:migration\": \"wrangler d1 migrations apply $DB_NAME --local\","
  echo "  \"db:remote:migration\": \"wrangler d1 migrations apply $DB_NAME --remote\""
fi


###
# Setup migration
###
echo "Generate migration"

npm run db:generate

echo "Run migration locally"

Y | npm run db:local:migration


###
# Overwrite index.ts
###

echo "import { Hono } from 'hono'
import { drizzle } from \"drizzle-orm/d1\";

import { users } from \"./db/schema\";


export type Bindings = {
  DB: D1Database;
};

const app = new Hono<{ Bindings: Bindings }>()


app.get('/', (c) => {
  return c.text('Hello Hono!')
})

app.get(\"/users\", async (c) => {
  const db = drizzle(c.env.DB);
  const result = await db.select().from(users).all();
  return c.json(result);
});

export default app" > ./src/index.ts

cd ..
