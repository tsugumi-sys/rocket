# 🧱 Platform Core Design (Cloudflare + Hono Based)

## 🎯 Goal

Build a simple, fast, and extensible backend platform to support MVP development.

* **Cloudflare-first**: Use Cloudflare Workers, D1, and R2 for scalability and cost-efficiency.
* **Secure and reusable**: Backend code is written intentionally (e.g., auth, payment) for better security and maintainability.

---

## 🧠 Core Design Principles

### 1. **Framework Stack**

* **Backend**: Hono (Cloudflare Workers)
* **Frontend**: Remix (Cloudflare Pages)
* **Database**: Cloudflare D1 + Drizzle ORM
* **Authentication**: Google/Apple OAuth with stateless JWT

### 2. **Development Focus**

* Start by wrapping framework commands for easy DX: `remix`, `wrangler`, `drizzle-kit`
* Use `npm` packages to modularize and share critical logic (e.g., auth, payment)

### 3. **Modular Architecture**

* Each domain (auth, payment, etc.) lives in its own package
* Each package connects to DB via shared interface (defined as `DbClient`)

---

## 📦 Modules as NPM Packages

Instead of hardcoding auth/payment logic into the app, extract them as packages:

### Example Packages

* `@yourstack/auth`
* `@yourstack/payment`
* `@yourstack/utils`
* `@yourstack/db` (interface + types)

Each package exports routes or utilities that can be consumed from `apps/backend`.

```ts
// apps/backend/src/routes.ts
import { createAuthRoutes } from '@yourstack/auth';
import { createDbClient } from './db/client';

app.route('/auth', (c) => {
  const db = createDbClient(c);
  return createAuthRoutes(db).fetch(c.req);
});
```

---

## 🛢️ Database Abstraction: `DbClient`

To decouple packages from a specific database technology:

### Define a shared interface:

```ts
export interface DbClient {
  users: {
    findByProviderId(provider: string, id: string): Promise<User | null>;
    createUser(data: NewUser): Promise<User>;
  };
  sessions: {
    createSession(userId: number): Promise<string>;
    verifySession(token: string): Promise<User | null>;
  };
}
```

### Implement the interface (e.g. with Drizzle + D1):

```ts
export function createDbClient(c: Context): DbClient {
  const db = drizzle(c.env.DB);
  return {
    users: {
      async findByProviderId(...) { ... },
      async createUser(...) { ... },
    },
    sessions: { ... },
  };
}
```

This allows:

* Core packages to work with any backend (D1, PostgreSQL, in-memory)
* Easy mocking in tests
* Better separation of concerns

---

## 🧰 Developer Workflow

### Monorepo Structure (pnpm workspaces or turbo)

```
/
├── apps/
│   ├── backend/       # Hono app with routing
│   └── web/           # Remix frontend
├── packages/
│   ├── auth/          # Auth logic & routes
│   ├── payment/       # Payment logic & routes
│   ├── db/            # DbClient interface + types
│   └── utils/         # Shared types, error classes, etc.
```

---

## 🛠️ Future-Proofing

### Database

* You can implement `@yourstack/db-d1`, `@yourstack/db-neon`, etc. for different DB backends.

### CLI Tool

* Optional DX: `npx create-yourstack-app` to scaffold Remix + Hono project

### SDK Exports

From core packages:

```ts
// @yourstack/auth
export const AuthClient = {
  login: async (idToken: string) => {
    return fetch("/auth/login", { method: "POST", body: idToken });
  },
};
```

---

## ✅ Summary

By defining a shared `DbClient` interface and encapsulating core business logic into npm packages:

* You gain reusability and security
* Your system is testable and extensible
* Developers can build full-stack features with minimal boilerplate

This approach takes inspiration from Convex but gives you control, freedom, and performance using Cloudflare’s modern infrastructure.
