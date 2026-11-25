# vishnuvahan.com: Field Logbook

My personal site, built as a pilot's field logbook: drones, software, and honest
flight reports (crashes included).

## Run it on your Mac

Needs **Node 24 LTS** (or Node 22.23.4+). Check with `node -v`; install with
`brew install node@24` or from https://nodejs.org.

```bash
cd site
npm install
npm run dev        # → http://localhost:4321
```

Other commands (inside `site/`):

| Command | What it does |
|---|---|
| `npm run build` | Production build into `site/dist/` |
| `npm run preview` | Serve the production build locally |
| `npm run check` | Type and content checks (the build fails on bad content) |
| `npm run todo` | Lists every placeholder still waiting for real content |
| `npm run format` | Prettier |

Component reference (dev only): http://localhost:4321/kit/

## Where things live

```
site/src/content/data/      profile, flight log, ventures, seva, hangar (YAML)
site/src/content/reports/   flight reports (MDX), one file each
site/src/content/notes/     field notes (Markdown/MDX)
site/src/assets/photos/     your photos (optimised automatically)
site/public/                resume.pdf, videos, favicon, share image
site/src/components/        notebook/, playful/, report/
deploy/                     Nginx config, rollback script, server setup guide
docs/                       brief, content guide, mockups
api/                        reserved for the small Django API (later)
```

- Adding content: **`docs/CONTENT-GUIDE.md`**
- Going live: **`deploy/README.md`** (push to `main`; the VPS deploys itself within about 5 minutes)
- Project rules for Claude Code: **`CLAUDE.md`**
