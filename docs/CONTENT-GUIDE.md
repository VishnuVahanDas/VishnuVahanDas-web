# Content guide: filling in the logbook

Everything on the site comes from files in `site/src/content/`. You never need to edit a
component to change text. After any change, `npm run dev` shows it instantly; `npm run todo`
shows what is still missing.

---

## 1. Your details: `site/src/content/data/profile.yaml`

Name, roles, tagline, DGCA ratings, education, links. To add what is missing:

```yaml
  email: you@example.com
  linkedin: https://www.linkedin.com/in/your-handle
  photo: ../../assets/photos/vipul-portrait.jpg       # pilot card photo (portrait)
  fieldPhoto: ../../assets/photos/vipul-field.jpg     # taped photo in the hero
  fieldPhotoAlt: Vipul holding a quadcopter at the test field
  resumePdf: /resume.pdf                              # put the file at site/public/resume.pdf
```

Photos go in `site/src/assets/photos/`. Any size or format (JPG, PNG, HEIC exported to JPG);
the build resizes and converts them to fast modern formats automatically.

## 2. Flight log (career): `data/log.yaml`

One block per entry, shown in `order`. The `remark` is written in blue handwriting, so keep
it short and in your own voice.

## 3. Ventures, Seva, Hangar: `data/ventures.yaml`, `data/seva.yaml`, `data/hangar.yaml`

- Ventures: add the Vainateya Skytech one-liner and URL.
- Hangar: GitHub repo names. Set `show: false` to hide one.

## 4. A flight report (the important part)

Each report is one file in `site/src/content/reports/`, e.g. `fr-07-fixed-wing.mdx`.
The file name becomes the URL: `/reports/fr-07-fixed-wing/`.

```mdx
---
code: FR-07                       # FR-01, FR-02 … (two digits)
title: Two tails, one lesson      # big handwritten title on the report
folderTitle: Fixed-wing pair      # shorter title on the folder (optional)
kind: Aerial                      # Aerial | Software | Venture | Mentoring | App
summary: One sentence about the project.
status: INCIDENT LOGGED           # stamp on the folder
pageStamp: RESOLVED               # stamp on the report page (optional)
order: 7                          # position in the list
date: Aug 2026                    # optional
aircraft: Flat-tail & V-tail fixed-wings
stack: ArduPlane · Cube Orange+
fields:                           # extra boxes in the report header (optional)
  - { k: Wingspan, v: 1.8 m }
link: https://example.com         # optional
photos:
  - { src: ../../assets/photos/fw-1.jpg, alt: Both aircraft on the bench, caption: both on the bench, rotate: -2 }
  - { video: /videos/fw-first-flight.mp4, alt: First flight, caption: first flight, rotate: 2 }
numbers:
  - { label: Flight time, value: 24 min }
diagram:                          # optional pencil sketch (see below)
  width: 900
  height: 240
  label: 'Describe the sketch in one sentence for screen readers.'
  nodes:
    - { id: gcs, label: Mission Planner, x: 0, y: 90, w: 180, h: 60 }
    - { id: plane, label: aircraft, x: 400, y: 90, w: 160, h: 60 }
  edges:
    - { from: gcs, to: plane, label: telemetry }
---

<Mission>
What you set out to do, and why.
</Mission>

<Preflight>
How you prepared: setup, parameters, checklist.
</Preflight>

<Incident>
What went wrong, exactly as it happened. This section is printed in red.
</Incident>

<RootCause>
Why it really happened.
</RootCause>

<Fix>
What you changed, and the flight that proved it.
</Fix>
```

- Write normal Markdown inside each section (paragraphs, **bold**, lists, links).
- Replace each `<Prompt>…</Prompt>` with your real story; `npm run todo` lists the ones left.
- Photos with no `src`/`video` show as taped placeholders with the caption.
- Videos go in `site/public/videos/` and are referenced as `/videos/name.mp4`.
- `draft: true` hides a report on the live site but keeps it visible in `npm run dev`.

### The sketch diagram

- Coordinates are in a `width × height` box; `x`, `y` are the top-left of each node.
- `shape`: `box` (default), `circle`, or `dots` (a row of `count` dots, e.g. a swarm).
- Arrows go from the side of one node facing the other; `label` is optional.
- On the site the sketch is drawn in pencil, draws itself in, and can be dragged and zoomed.

## 5. A field note: `site/src/content/notes/`

```md
---
title: What a dataflash log taught me
date: 2026-12-01
summary: One line shown in the list and the RSS feed.
draft: false
---

Your note in Markdown.
```

The "Notes" tab appears in the menu automatically once at least one note is published.

## 6. Before going live

Run `npm run todo` and work through the list, then `npm run build`. Push to `main` and
GitHub Actions deploys it (see `deploy/README.md`).
