# 🚀 Rocket Start: Fullstack Cloudflare Project Template

This script sets up a modern fullstack application using:

- Backend: Hono + Cloudflare Workers + Drizzle ORM (D1)
- Frontend: Remix + Cloudflare Pages

## 📋 Prerequisites

Before you run the setup script, make sure you have the following installed:

- Node.js: >= 20
- jq: command-line JSON processor
- strip-json-comments: to handle .jsonc (install globally)
- Cloudflare CLI (wrangler):

```sh
npm install -g strip-json-comments
```

Log in to Cloudflare:

```sh
npm install -g wrangler
wrangler login
```

## 🚀 How to use


1. Download script.

```bash
curl -fsSL https://raw.githubusercontent.com/tsugumi-sys/rocket/refs/heads/main/setup_project.sh -o installer.sh
```

2. Run:

```bash
chmod +x installer.sh && ./installer.sh 
```
