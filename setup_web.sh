#!/bin/bash

set -e  # Exit on error

WEB_DIR="$1"


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


###
# Setup shadcn
###
echo "Setting up shadcn..."
npx shadcn@latest init -b neutral -d

echo "Creating postcss.config.js..."

cat <<EOF > postcss.config.js
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
EOF

echo "✅ postcss.config.js created."

cd ..
