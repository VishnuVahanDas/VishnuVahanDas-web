# vishnuvahan.com — "Field Logbook" · Claude Code build brief

> **How to use this file**
> 1. Create an empty folder `vishnuvahan/`, run `git init`, and open Claude Code in it.
> 2. Put this file at `docs/BRIEF.md` and the two mockup files at `docs/mockups/`.
> 3. First message to Claude Code: **"Read docs/BRIEF.md fully, then start Phase 0. Stop at the end of each phase for my review."**

---

## 0. Who you are working with, and how

I am **Vipul Kumar** (GitHub: `VishnuVahanDas`). I am a developer myself (Django/DRF, Flutter, Linux/Nginx), and **I want to build this site with you, not just receive it.** So:

- Work **phase by phase** (section 9). At the end of every phase, **stop**, summarise what you did, list files changed, and wait for my "go ahead".
- **Explain the decisions** that are not obvious (one or two lines each), so that I can maintain the code later.
- Keep the code **plain and readable**: small components, clear names, comments only where intent is not obvious. No clever abstractions.
- Never invent facts about me. Where real content is missing, write a visible placeholder and mark it in code with `TODO(vipul): …` (section 7 lists what is missing).
- Do **not** SSH into my server or run anything against production. For server steps, give me the exact commands and I will run them.
- **Repository structure: single repo (monorepo), not Git submodules.** This is decided. Reason: one author, the site and its small API change together, and it is simpler for me to maintain.

---

## 1. The concept

The site is **my pilot's field logbook**: a real-looking notebook lying on a dark desk. Every page feels **handmade and textured**, every project is written up as an **honest flight report** (including what crashed and how I fixed it), and the interface is full of **small playful details from my own world**: drones, RC transmitters, DGCA licence, travel, and devotion.

**Originality rule:** the idea was inspired by the general qualities of another engineer's portfolio (handmade feel, honest case studies, playful hardware details). **Do not copy any other site's theme, layout, components or code.** Everything below is our own design.

**Voice:** warm, first person, casual but precise. Short sentences. Occasional Hindi/Sanskrit words are welcome. Labels are typewriter-style, notes are handwritten, body text is a readable serif.

---

## 2. Tech stack (decided)

| Layer | Choice | Notes |
|---|---|---|
| Site | **Astro** (latest stable) + **TypeScript** | Static output. Content in **content collections** (content layer API, schemas in `src/content.config.ts`). Check the installed version's docs before using an API. |
| Content | **MDX** for flight reports and notes; **YAML/JSON** for structured data | Every collection has a Zod schema; build must fail on invalid content. |
| Styling | **Hand-written CSS** with custom properties (design tokens), Astro scoped styles | **No Tailwind, no UI kit.** The look is too custom for utility classes. |
| Interactivity | **Vanilla TypeScript** in Astro `<script>` tags or tiny custom elements | No React. Total JS per page ≤ 30 KB gzipped (report pages with the diagram may go up to 60 KB). |
| Diagrams | **Rough.js** (hand-drawn pencil look) rendered into SVG from a small JSON spec, with pan & zoom | See `SketchDiagram` in section 5. |
| Fonts | Self-hosted via **Fontsource**: **Kalam** (400, 700; has Devanagari), **Special Elite**, **Literata** (variable) | `font-display: swap`; preload the two primary fonts. |
| Images | Astro `<Image>`/`<Picture>` (sharp), AVIF/WebP | Every image needs `alt` (enforced by schema). |
| Extras | `@astrojs/sitemap`, `@astrojs/mdx`, `@astrojs/rss` (for notes) | |
| API (later, Phase 6) | **Django + DRF**, gunicorn, systemd, Postgres | Only for the visitor counter, contact form and uptime checks. |
| Hosting | **My own VPS**: Nginx serves the static site; `/api/` is proxied to gunicorn; Certbot TLS | Other sites run on the same VPS, so **never touch other Nginx server blocks**. |
| CI/CD | **GitHub Actions**: build, then rsync to the VPS over SSH, using an atomic release + symlink swap | Section 8. |
| Tooling | Current Node LTS, npm, Prettier, ESLint, `astro check` | `.editorconfig`, `.nvmrc`. |

---

## 3. Repository layout

```
vishnuvahan/
├─ CLAUDE.md                  # short project rules for future sessions (you create it in Phase 0)
├─ docs/
│  ├─ BRIEF.md                # this file
│  ├─ CONTENT-GUIDE.md        # how I add a flight report, log entry, photo (you write it)
│  └─ mockups/                # design references (see section 4)
├─ site/                      # Astro project
│  ├─ src/
│  │  ├─ content.config.ts
│  │  ├─ content/
│  │  │  ├─ reports/          # fr-01-swarm.mdx … (flight reports)
│  │  │  ├─ notes/            # field notes / blog (Phase 4, can start empty)
│  │  │  └─ data/             # profile.yaml, log.yaml, seva.yaml, hangar.yaml, ventures.yaml
│  │  ├─ components/          # one folder per component group (notebook/, report/, playful/)
│  │  ├─ layouts/             # NotebookLayout.astro, ReportLayout.astro
│  │  ├─ pages/               # index, reports/[...], notes/[...], resume, 404, _kit (dev only)
│  │  ├─ scripts/             # battery.ts, arm-switch.ts, sketch-diagram.ts, lightbox.ts
│  │  ├─ styles/              # tokens.css, base.css, textures.css
│  │  └─ assets/photos/       # real photos (I will add them)
│  └─ public/                 # resume.pdf, favicon, noise tile, videos
├─ api/                       # Django project (Phase 6 only; create an empty README now)
├─ deploy/
│  ├─ nginx/vishnuvahan.com.conf
│  ├─ systemd/                # api service + uptime timer (Phase 6)
│  └─ scripts/                # release helper, rollback
└─ .github/workflows/deploy.yml
```

---

## 4. Design references

`docs/mockups/` contains two mockups we approved:

- `logbook-home.mockup.html`: the home page
- `flight-report.mockup.html`: flight report FR-01

They are written in a design-canvas template format (`{{ }}` holes, `<sc-for>` loops, inline styles). **They are not production code and will not run on their own.** Read them for layout, spacing, copy, colours, rotations and component ideas, then rebuild cleanly in Astro. Where the mockup and this brief disagree, this brief wins.

---

## 5. Design system

### 5.1 Tokens (`src/styles/tokens.css`)

| Token | Value | Use |
|---|---|---|
| `--desk` | `#2B2622` | page background around the notebook |
| `--paper` | `#F1ECDF` | notebook page (home) |
| `--paper-report` | `#F4F0E6` | report sheets (ruled) |
| `--card` | `#FBF8F1` | cards, pilot card, photo borders |
| `--grid-line` | `rgba(70,100,140,0.12)` | 24 px graph-paper grid |
| `--ruled-line` | `rgba(70,100,140,0.16)` | 32 px ruled lines on report pages |
| `--margin-line` | `rgba(180,35,24,0.35)` | red margin line |
| `--ink` | `#2E2A24` | body text |
| `--ink-muted` | `#5B5446` | labels |
| `--ink-blue` | `#1E3A8A` | handwriting, links |
| `--ink-red` | `#B42318` | corrections, incidents, ॥ श्री ॥ |
| `--highlighter` | `rgba(255,221,0,0.55)` | highlighted words |
| `--tape` | `rgba(222,205,150,0.85)` | masking tape |
| `--manila` / `--manila-edge` / `--manila-ink` | `#E3C98F` / `#8A6B2E` / `#5B4A22` | report folders |
| `--tag` | `#F7E7B9` | luggage tags |
| `--photo-empty` | `#D8D2C4` | photo placeholders |
| `--tab-1…5` | `#F6E27A`, `#BFE3C6`, `#F5C2B8`, `#F7C77C`, `#BCD3F2` | index tabs (nav) |
| `--lipo` | `#2F7D4F` | battery cells |
| `--tx-body` / `--tx-well` / `--tx-lever` | `#3A3F45` / `#24282D` / `#C9CED4` | RC transmitter |
| `--armed` / `--disarmed` / `--link-on-dark` | `#7BE0A1` / `#F5A3A3` / `#F6E27A` | ARM switch states |
| `--kalava-red` / `--kalava-yellow` | `#C62828` / `#F2B705` | sacred thread divider |

Fonts: `--font-hand: Kalam`, `--font-type: "Special Elite"`, `--font-body: Literata`.
Type scale (desktop → mobile, use `clamp()`): name/hero 104 → 56 px (Kalam 700); section titles 52 → 36 px (Kalam 700); report title 76 → 44 px; body 18–21 px Literata; labels 12–15 px Special Elite with 1–3 px letter-spacing.

**Contrast:** all text must meet WCAG AA on its background. Verify `--ink-muted`, `--ink-red` and `--manila-ink` on paper/manila, and adjust the shade if a pair fails (keep the hue).

### 5.2 Textures (`textures.css`)

- **Paper grain:** a small pre-generated, tileable noise PNG (~256 px, under 15 KB) in `public/`, blended with `multiply` at about 15–18% opacity. Write a tiny Node script to generate it once. Do **not** use a full-page live SVG filter, because it is too slow on phones.
- **Graph paper** (home) and **ruled paper** (reports) are CSS gradients using the tokens.
- **Ring binding:** a left strip with punched holes (radial-gradient), and a red margin line. On mobile (< 720 px) the holes shrink to a thin strip.
- **Desk:** a plain `--desk` colour around the notebook, with a deep, soft shadow under the page.

### 5.3 Components

**Notebook shell**
- `NotebookLayout`: desk, notebook page, ring strip, margin line, grain, and the index-tab nav above the page.
- `IndexTabs`: coloured paper tabs (Flight log · Flight reports · Hangar · Seva · Contact). Mark the current one. Horizontal scroll on mobile.
- `ShriHeader`: **॥ श्री ॥** in red Kalam, centred at the top of the first page (as in a traditional bahi-khata), with the typewriter line `PILOT’S FIELD LOGBOOK · VOL. 01 · VISHNUVAHAN.COM`.

**Hand-made elements**
- `MarginNote`: a handwritten note in red or blue, slightly rotated, with an optional hand-drawn arrow.
- `HandUnderline`: a wobbly SVG underline under a heading.
- `Highlight`: a highlighter mark behind words.
- `TapedPhoto`: a photo with a white border and one or two masking-tape strips, rotated −5°…+5° (rotation set as a prop, not random, so it stays stable between builds). Opens in a lightbox. If there's no image, it shows a dashed placeholder with the caption in Kalam.
- `Stamp`: a rubber-stamp label (`INCIDENT LOGGED`, `RESOLVED`, `IN SERVICE`, `IN BUILD`, `MISSION FLOWN`), red or blue, rotated −4°, about 85% opacity.

**Playful details (all must work by keyboard and respect `prefers-reduced-motion`)**
- `LipoBattery`: fixed in the top corner. A 3S battery whose four cells and voltage readout **drain as you scroll**, from **12.6 V** at the top to **10.5 V** at the bottom (linear on scroll progress). At the very bottom it reads `LAND NOW` in red. Under it, the first time only, a handwritten hint: `drains as you scroll ↓`. Throttle updates with `requestAnimationFrame`.
- `PilotCard`: an ID-style card held on with an SVG paperclip, showing photo, name, callsign, base, rating and education (data from `profile.yaml`). **It must not imitate any official DGCA document or logo.** It's a personal card that simply names the certificate.
- `BoardingPass`: the résumé link, styled as a ticket stub with a perforated divider. `BOARDING PASS | RÉSUMÉ · PDF ↓ / GWL → ANYWHERE`.
- `FlightLogTable`: my career shown as a pilot's logbook (DATE · AIRCRAFT / ORGANISATION · ROLE · REMARKS), with remarks in blue handwriting. On mobile it becomes stacked entries, not a squeezed table.
- `ManilaFolder`: one per flight report, with the code (`FR-01`) on a folder tab, the edge of a white sheet peeking out, kind, title, one-line summary, and a `Stamp`. On hover/focus it lifts 4 px and straightens its rotation. The whole folder is the link.
- `LuggageTag`: a GitHub repo shown as a paper tag with a string hole, linking to the repo.
- `KalavaThread`: a red-and-yellow twisted thread (repeating gradient) tied across the top of the Seva section.
- `ArmSwitch`: an RC-transmitter panel with a metal toggle. **A real `<button aria-pressed>`**. Disarmed: `DISARMED · FLIP TO CONTACT`. Armed: the lever flips up, the label reads `ARMED · LINK UP` in green, and the contact links appear (email, GitHub, LinkedIn). The links must also be in the page source for no-JS visitors and crawlers (hidden visually, not removed).
- `MalaCounter` (footer): a row of beads, with the visitor count shown as **round and bead of a 108-bead mala**, e.g. `visitor no. 1,234 · round 12, bead 46 of 108`. Hidden until the Phase 6 API exists.

**Report components**
- `ReportHeaderForm`: a grid of boxed form fields (REPORT NO., AIRCRAFT, PILOT IN COMMAND, FLIGHT STACK, DATA LINK, DATE) filled in blue handwriting.
- `ReportSection`: numbered typewriter heading (`01 MISSION`). The **incident variant** has a red border, a faint red tint and a −0.4° rotation.
- `SketchDiagram`: reads `{nodes, edges}` JSON (from report front-matter or an import) and draws it with **Rough.js** in pencil style, with Kalam labels. Supports **drag to pan, wheel/pinch to zoom, and a reset button**. The strokes draw in once when scrolled into view (skipped for reduced motion). It needs a text description for screen readers (`aria-label` and a hidden list of the connections).
- `NumbersGrid`: boxed key numbers; `[ ]` placeholders are allowed while drafting.
- `Signature`: "Vipul" in Kalam over a line, with `PILOT IN COMMAND` under it.

Build a dev-only page **`/_kit`** that shows every component and token. It must not be part of the production build (exclude it or set `noindex`, and leave it out of the sitemap).

### 5.4 Motion & responsiveness

- Motion stays subtle and physical: folders lift, photos straighten on hover, the lever flips, stamps fade in with a small scale (0.96 → 1), diagram strokes draw in. Everything is off under `prefers-reduced-motion`.
- Rotations are halved below 720 px. The notebook fills the width on phones, leaving 12 px of desk on each side.
- Must look right from 360 px to 1440 px+.

---

## 6. Pages & content

### 6.1 Home `/`

Sections in order (match the mockup):

1. **Header strip:** typewriter volume line · ॥ श्री ॥ · `LipoBattery`.
2. **Hero, "Entry 001: Who is flying":**
   - `Vipul Kumar` (Kalam, blue) with a `HandUnderline`.
   - `UAV SYSTEMS · SOFTWARE · FOUNDER`
   - Body: *"I build drones that fly themselves, and software that keeps them (and people) on track. This logbook is where I write down what I built, what crashed, and what fixing it taught me."* (highlight "what crashed")
   - Red `MarginNote`: *"honest entries only. crashes included."*
   - Links: `read the flight reports →` and the `BoardingPass`.
   - Right side: a `TapedPhoto` (me in the field) behind the `PilotCard`.
3. **Flight log** (`log.yaml`), subtitle *"my career, logged like flight hours"*.
4. **Flight reports:** a grid of `ManilaFolder`s from the reports collection, ordered by `order`. Subtitle *"mission → incident → root cause → fix"*.
5. **Hangar:** `LuggageTag`s from `hangar.yaml`, then *"the rest of the hangar → github.com/VishnuVahanDas"*.
6. **Ventures:** two cards (Vainateya Skytech Private Limited, HolyTrail). Add this small section between Hangar and Seva in the same visual language. A pinned paper card works well.
7. **Seva (सेवा):** `KalavaThread`, then *"Websites and apps built for temples, devotees and yatris."* plus four cards from `seva.yaml`.
8. **Contact:** `ArmSwitch`.
9. **Footer:** `© <year> Vipul Kumar · logbook closed for today` and the `MalaCounter` (once Phase 6 exists).

### 6.2 Flight reports `/reports/` and `/reports/[slug]/`

- An index page with all folders, plus a filter by kind (Aerial · Software · Venture · Mentoring · App) using plain links or buttons.
- The report template (see the mockup) runs in this order:
  `← back to the logbook` → `RESOLVED`-style stamp → `ReportHeaderForm` → title (Kalam) → one-paragraph summary → 2–3 `TapedPhoto`s / video → **01 MISSION → 02 PRE-FLIGHT → 03 INCIDENT REPORT (red) → 04 ROOT CAUSE → 05 THE FIX → 06 SYSTEM SKETCH (`SketchDiagram`) → 07 POST-FLIGHT NUMBERS** → `Signature` → previous/next report.
- In MDX, the sections are components (`<Mission>`, `<Preflight>`, `<Incident>`, `<RootCause>`, `<Fix>`, `<Sketch />`, `<Numbers />`), so that I can write reports in plain Markdown inside them.
- **Report front-matter schema:** `code` (e.g. FR-01), `title`, `kind`, `summary`, `status` (stamp text), `stampColor` (red|blue), `order`, `date` (optional while drafting), `aircraft`, `stack`, `link`, `cover` (image + alt, optional), `photos[]` (image|video, alt, caption, rotation), `diagram` (nodes/edges, optional), `numbers[]` (label, value), `draft` (boolean; drafts are hidden in production).

**Seed these six reports.** Use only the facts given here. Everything else is `TODO(vipul)` prompts written in the blue handwriting style, as in the mockup.

| Code | Title | Kind | Facts we have | Stamp |
|---|---|---|---|---|
| FR-01 | 10-drone swarm (display title: *Ten drones, one formation*) | Aerial | 10 aircraft in formation; ArduPilot Follow Mode; RFD900x radios; Mission Planner GCS. Diagram: Mission Planner → RFD900x link → leader → followers. | INCIDENT LOGGED (red) / page stamp RESOLVED |
| FR-02 | SUAS 2026, Tulsa | Mentoring | Technical mentor for Team Trinetra at RoboNation SUAS 2026, Tulsa, USA. | MISSION FLOWN |
| FR-03 | Vyom ERP | Software | Internal company ERP. **Keep it general; confidential details are not allowed.** | IN SERVICE |
| FR-04 | Sadhana platform | Software | Daily sadhana entries, streaks, coordinator groups, analysis board, user/superuser roles; Django + Postgres + Nginx; live at sr.iskcongorakhpur.com. | INCIDENT LOGGED |
| FR-05 | HolyTrail | Venture | Yatra & pilgrimage brand, holytrail.in. | IN SERVICE |
| FR-06 | ISKCON Gorakhpur | Software | Temple website with EaseBuzz online donations (Django). | IN SERVICE |

### 6.3 Other pages

- `/resume/`: the boarding pass as a full page (name, roles, route "GWL → ANYWHERE", key experience) and a download of `public/resume.pdf` (`TODO(vipul)`: I will add the PDF).
- `/notes/`: field notes (a short blog in MDX, with an RSS feed). It may start empty with a friendly "no entries yet" page.
- `/404`: *"Link lost: failsafe triggered. Returning to launch…"*, with a big `RTL → home` link (no auto-redirect).

### 6.4 Structured data (seed files in `src/content/data/`)

**profile.yaml**
- name: Vipul Kumar
- callsign: VishnuVahanDas
- base: Gwalior, India
- roles: UAV Systems · Software · Founder
- tagline: (the hero body text above)
- rating: DGCA Remote Pilot Certificate (Small & Medium)
- education: B.Tech, Information Technology, Dr. A.P.J. Abdul Kalam Technical University
- email / linkedin / photo: `TODO(vipul)`
- github: https://github.com/VishnuVahanDas

**log.yaml** (newest last, displayed in this order)

| date | org | role | remark (handwritten; I may rewrite these) |
|---|---|---|---|
| B.Tech | Dr. A.P.J. Abdul Kalam Technical University | B.Tech, Information Technology | first Django sites & Flutter apps |
| Sep 2023 – Mar 2024 | Vyom Drones Pvt Ltd | Software Developer | where the drones began |
| 2024 → | Vainateya Skytech Private Limited | Founder & Director | my own venture |
| Feb 2026 → | Vyom Drones Pvt Ltd | Shareholder · Board of Directors · Head of Department (Technical & Software Development) | back as a partner |
| 2026 | RoboNation SUAS · Tulsa, USA | Technical mentor, Team Trinetra | flew the flag abroad |

**ventures.yaml**
- Vainateya Skytech Private Limited: Founder & Director; url `TODO(vipul)`; one-line description `TODO(vipul)`
- HolyTrail: Founder; Yatra & pilgrimage journeys; https://holytrail.in

**seva.yaml**
- ISKCON Gorakhpur: temple website
- Sadhana report: daily practice tracking (sr.iskcongorakhpur.com)
- Nitya Dāsa: self-tracking app
- HolyTrail: yatra & pilgrimage

**hangar.yaml** (GitHub repos, each linking to `https://github.com/VishnuVahanDas/<name>`)
nitya-dasa · Sadhana_App · holytrail · hrishikesh · vyom-erp · Ai_Drone · iskcongkp · generateQR
(Before publishing, confirm with me that each repo is public and fine to show.)

### 6.5 SEO & meta

- Title pattern: `Vipul Kumar · <page>`; description from profile/report summary.
- JSON-LD `Person` on the home page (name, url, sameAs GitHub, jobTitle, worksFor). Don't include anything that isn't in `profile.yaml`.
- Open Graph image: one static, handmade-style OG image for now. Per-report OG images are a later nice-to-have.
- Sitemap, `robots.txt`, canonical URLs on `https://vishnuvahan.com`, a favicon (a small hand-drawn quadcopter in blue ink).

---

## 7. Content still missing (render placeholders; never invent)

My email · LinkedIn URL · all photos/videos (hero, pilot card, report photos) · résumé PDF · report dates · swarm numbers (spacing, link range, flight time) · the real incident / root cause / fix stories for every report · Vainateya Skytech URL + one-liner · which repos are fine to show.

Add an npm script **`npm run todo`** that lists every `TODO(vipul)` across the repo with its file and line, so I can work through them.

---

## 8. Deployment (my VPS)

**Nginx** (`deploy/nginx/vishnuvahan.com.conf`, a new server block only):
- `vishnuvahan.com` + `www` → 301 to the apex; HTTP → HTTPS (Certbot-managed certificate paths).
- `root /var/www/vishnuvahan.com/current;`
- Cache headers: hashed `/_astro/*` files `immutable, max-age=31536000`; HTML `no-cache`; fonts and images long cache.
- Gzip/brotli if available; security headers (HSTS, X-Content-Type-Options, Referrer-Policy, a CSP that allows only self + what the site actually uses).
- `location /api/ { proxy_pass http://unix:/run/vishnuvahan-api.sock; … }`, commented out until Phase 6.
- Custom `404.html`.

**Release layout on the server:** `/var/www/vishnuvahan.com/releases/<timestamp>/`, with `current` → a symlink to the latest release. Keep the last 5 releases. Include a `deploy/scripts/rollback.sh`.

**GitHub Actions** (`.github/workflows/deploy.yml`):
- On push to `main`: checkout → setup Node → `npm ci` → `astro check` → lint → build (`site/`) → rsync `dist/` to a new release dir over SSH → swap the symlink → prune old releases.
- Secrets: `VPS_HOST`, `VPS_USER`, `VPS_SSH_KEY`, `VPS_PORT` (I create a restricted deploy user and key; give me the exact commands).
- Pull requests: build + check only, no deploy.
- **Never** run `systemctl reload nginx` from CI for the static site (it isn't needed). Any Nginx change is applied by me, with `sudo nginx -t` run before reloading.

Also give me a `deploy/README.md` with first-time server setup steps (create dirs, deploy user, place the Nginx conf, Certbot command, test commands).

---

## 9. Phases (stop after each one for my review)

**Phase 0: Scaffold**
Repo layout, `site/` Astro project (TypeScript strict, MDX, sitemap), Prettier/ESLint/`astro check`, `.nvmrc`, `.editorconfig`, `CLAUDE.md` (≤ 60 lines: stack, rules, where things live, "single repo, no submodules", "never invent content"), an empty `api/README.md`, `npm run todo`.
✅ `npm run dev` shows a blank page on desk + paper; lint/check pass.

**Phase 1: Design system**
`tokens.css`, `base.css`, `textures.css` (with the noise-tile script), self-hosted fonts, all components from 5.3 except `SketchDiagram` and `MalaCounter`, and the `/_kit` page.
✅ `/_kit` shows every component at 360 px and 1280 px; keyboard focus is visible everywhere; reduced motion is respected; contrast checked.

**Phase 2: Home page**
Content collections + schemas, the data files from 6.4, every home section from 6.1 wired to data, `LipoBattery` and `ArmSwitch` working.
✅ The home page matches the mockup's spirit at desktop and phone width; content comes only from files; it works without JS (except the battery/switch enhancements).

**Phase 3: Flight reports**
Report collection + MDX section components, `SketchDiagram` (Rough.js, pan/zoom/reset, draw-in), the report index with filter, the six seeded reports (FR-01 complete with its diagram, the others with TODO prompts), and previous/next navigation.
✅ FR-01 matches the mockup; adding a new report needs only a new `.mdx` file (documented in `docs/CONTENT-GUIDE.md`).

**Phase 4: Finishing**
`/resume/`, `/notes/` + RSS, `/404`, SEO/meta/JSON-LD/OG/favicon, image optimisation, lightbox, an accessibility pass (axe or similar), and a performance pass.
✅ Lighthouse (mobile) ≥ 95 for Performance, Accessibility, Best Practices and SEO on home and FR-01; no console errors.

**Phase 5: Deployment**
Everything in section 8: Nginx conf, workflow, release/rollback scripts, `deploy/README.md`.
✅ I can follow `deploy/README.md` from start to finish and the site goes live on https://vishnuvahan.com; a push to `main` redeploys automatically.

**Phase 6: Small API (later; only when I say so)**
A Django + DRF project in `api/`, gunicorn on a unix socket, a systemd service, and Postgres:
- `POST /api/visit/` + `GET /api/visits/`: the mala counter. Count once per browser session. Store **no IP addresses**; if de-duplication is needed, use a daily-salted hash.
- `POST /api/contact/`: a contact form behind the ARM switch (honeypot + rate limit; email notification through my SMTP; messages visible in Django admin).
- `GET /api/status/`: uptime of my live sites, filled by a systemd timer every 5 minutes (for a possible "systems in the air" panel later).
- Front end: show `MalaCounter` and the form only when the API responds; fail silently otherwise.
✅ Tests for each endpoint; `deploy/systemd/` units; the API deploy steps added to `deploy/README.md`.

---

## 10. Definition of done (whole project)

- It feels like a **real, handmade notebook**, not a template. If something looks generic, make it more physical (paper, ink, tape, stamps), never flashier.
- No invented facts; `npm run todo` lists everything still missing.
- Fast (static, small JS), accessible (AA, keyboard, reduced motion), works on a 360 px phone.
- I can add a flight report, a log entry or a photo by editing content files only, following `docs/CONTENT-GUIDE.md`.
