# vishnuvahan.com: project rules

Personal site of **Vipul Kumar**, designed as a **pilot's field logbook**: handmade,
textured, honest flight reports, playful details from drones/aviation/devotion.
Full brief: `docs/BRIEF.md`. Approved mockups: `docs/mockups/`.

## Stack
- `site/`: Astro 7 + TypeScript (strict), MDX, static output. Hand-written CSS with tokens
  in `site/src/styles/tokens.css`. **No Tailwind, no React, no UI kits.**
- Interactivity: small vanilla TS files in `site/src/scripts/`.
- Diagrams: Rough.js, rendered at build time in `components/report/SketchDiagram.astro`.
- Fonts: Fontsource (Kalam, Special Elite, Literata). Self-hosted.
- `api/`: reserved for a small Django + DRF service (Phase 6, only when Vipul asks).
- `deploy/`: Nginx config, server setup script, auto-deploy (VPS pulls `main` every 5 min),
  rollback. GitHub Actions only checks and builds (`.github/workflows/ci.yml`).

## Rules
- **Single repo. No Git submodules.**
- **Never invent facts about Vipul.** Missing content = visible placeholder + `TODO(vipul)`;
  in reports use `<Prompt>…</Prompt>`. `npm run todo` (in `site/`) lists them all.
- All content lives in `site/src/content/` (YAML data, MDX reports, notes). Components never
  hard-code personal facts.
- Keep code plain and readable; explain non-obvious decisions in one-line comments.
- Accessibility: real buttons/links, visible focus, AA contrast, `prefers-reduced-motion`.
- Keep JS tiny (≤ 30 KB gzipped per page). Static first; features must work without JS
  where possible.
- Never touch other Nginx server blocks on the VPS; never SSH into production yourself.
  Give Vipul the commands.
- Vyom Drones work stays general: no confidential details.

## Commands (run in `site/`)
- `npm run dev`: local dev server at http://localhost:4321
- `npm run check`: type and content check
- `npm run build`: production build into `site/dist/`
- `npm run todo`: everything still to fill in
- `npm run noise`: regenerate the paper grain tile (rarely needed)
