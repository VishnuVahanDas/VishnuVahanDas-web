# api/ — reserved for Phase 6

A small Django + DRF service will live here **only when Vipul asks for it**:

- `POST /api/visit/`, `GET /api/visits/`: the mala visitor counter (no IP addresses stored)
- `POST /api/contact/`: contact form behind the ARM switch
- `GET /api/status/`: uptime of the live sites, filled by a systemd timer

Until then the site is fully static and does not call any API.
See `docs/BRIEF.md` → Phase 6.
