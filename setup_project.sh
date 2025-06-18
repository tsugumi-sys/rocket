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

###
# Setup Backend (Hono + Cloudflare Workers)
###

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

###
# Setup Web (Remix + Cloudflare Pages)
###

echo "🌐 Creating web project in ./$WEB_DIR using Remix + Cloudflare Pages..."
npx create-remix@latest "$WEB_DIR" -- --cf-pages --yes

echo "📦 Installing web dependencies..."
cd "$WEB_DIR"
npm install


###
# Create .dev.vars file and insert BACKEND_SERVER_URL
###

echo "Creating .dev.vars file..."

cat <<EOF > .dev.vars
BACKEND_SERVER_URL="http://localhost:8787"
EOF

echo "✅ .dev.vars file created with BACKEND_SERVER_URL."


###
# Overwrite page
###

echo "import React from \"react\";
import { Links, Meta, Outlet, Scripts, ScrollRestoration, useLoaderData } from \"@remix-run/react\";
import type { LoaderFunction } from \"@remix-run/node\";
import { json } from \"@remix-run/node\";

import \"./tailwind.css\";

// Loader function to fetch data from the backend API
export const loader: LoaderFunction = async () => {
  try {
    const response = await fetch(\"http://localhost:8787/users\");
    if (!response.ok) {
      throw new Error(\"Failed to fetch users\");
    }
    const users = await response.json();
    return json({ users });
  } catch (err) {
    return json({ error: \"Error fetching users\" }, { status: 500 });
  }
};

export const links = () => [
  { rel: \"preconnect\", href: \"https://fonts.googleapis.com\" },
  {
    rel: \"preconnect\",
    href: \"https://fonts.gstatic.com\",
    crossOrigin: \"anonymous\",
  },
  {
    rel: \"stylesheet\",
    href: \"https://fonts.googleapis.com/css2?family=Inter:ital,opsz,wght@0,14..32,100..900;1,14..32,100..900&display=swap\",
  },
];

export function Layout({ children }: { children: React.ReactNode }) {
  const { users, error } = useLoaderData();

  return (
    <html lang=\"en\">
      <head>
        <meta charSet=\"utf-8\" />
        <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />
        <Meta />
        <Links />
      </head>
      <body>
        {error ? (
          <p>{error}</p>
        ) : (
          <div>
            <h1>Users</h1>
            <ul>
              {users.map((user: any) => (
                <li key={user.id}>{user.email}</li>
              ))}
            </ul>
          </div>
        )}
        {children}
        <ScrollRestoration />
        <Scripts />
      </body>
    </html>
  );
}

export default function App() {
  return <Outlet />;
}" > app/root.tsx


cd ..

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

