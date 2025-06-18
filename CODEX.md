## Project Overview
.
├── backend (Hono + Cloudflare Workers + Drizzle ORM)
│   ├── src
│   │   └── db
│   │       └── schema.ts (database)
│   ├── drizzle.config.ts
│   └── wrangler.jsonc
└── web (Remix + Cloudflare Pages)
    ├── app
    ├── public
    └── remix.config.js

Tech Stack:
Backend: Hono + Cloudflare Workers + Drizzle ORM (D1)
Web: Remix + Cloudflare Pages


## Tips

Backend server entry point: ./backend/src/index.ts
Frontend server entry point: ./web/app/root.tsx

The servers are already up.

- frontend: http://localhost:5173
- backend: http://localhost:8787

UI framework is shadcn/ui. Please use these components. For example, if you need to use the Button component:

```sh
cd web && npx shadcn@latest add button
```

Then you can import it:

```ts
import { Button } from "~/components/ui/button"
```

For the TODO app, you will also need input, checkbox, and table components:

```sh
cd web && npx shadcn@latest add input checkbox table
```

## When you create & modiry table

1. go to backend directory
2. modiry src/db/schema.ts
3. generate migrations `npm run db:generate`
4. apply `db:local:migration`

See more commands in ./backend/package.json
