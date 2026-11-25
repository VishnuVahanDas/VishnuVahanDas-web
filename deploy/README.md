# Deploying vishnuvahan.com

**How it works:** the VPS pulls `main` from GitHub every 5 minutes. When there is a new
commit, it builds the site and switches to it in one step. No server passwords or SSH
keys are stored in GitHub; GitHub only runs a check-and-build (CI) so you see a ✗ if a
commit is broken.

```
/var/www/vishnuvahan.com/
├─ repo/                         git clone of this repository (owned by vvdeploy)
├─ releases/
│  ├─ 20261125103000-<commit>/   each build (newest 5 kept)
│  └─ 20261126091500-<commit>/
└─ current → releases/20261126091500-<commit>     ← nginx serves this
```

| Piece | Where |
|---|---|
| Deploy script | `deploy/server/vv-deploy` → installed as `/usr/local/bin/vv-deploy` |
| Rollback | `deploy/scripts/rollback.sh` → installed as `/usr/local/bin/vv-rollback` |
| Timer | `deploy/server/vv-deploy.{service,timer}` → `/etc/systemd/system/` |
| Nginx | `deploy/nginx/vishnuvahan.com.conf` + `vishnuvahan-headers.conf` (snippet) |
| Node | a private Node 24 in `/opt/node24` (the system `node`, if any, is untouched) |
| User | `vvdeploy`: system user, no password, no login shell |

---

## First-time setup (once)

1. **DNS:** at your domain provider, point `vishnuvahan.com` and `www.vishnuvahan.com`
   (A records) to `88.222.241.219`. Remove any AAAA record that points elsewhere.
2. **On the VPS, as root:**

   ```bash
   curl -fsSLO https://raw.githubusercontent.com/VishnuVahanDas/VishnuVahanDas-web/main/deploy/server/setup.sh
   bash setup.sh
   ```

   The script prints each step. It is safe to run again; it skips what is done.
   If DNS was not ready, it leaves the site on HTTP; run it again later for HTTPS.

**What it will never do:** edit another site's nginx file, or leave nginx broken. Every
change is tested with `nginx -t`; if the test fails, the change is undone and the script
stops. If an old config for vishnuvahan.com shares a file with another domain, the script
stops and asks you to remove that block by hand.

## Everyday use

| Task | Command (on the VPS) |
|---|---|
| Publish | Just `git push` to `main`. Live within about 5 minutes. |
| Publish right now | `sudo -u vvdeploy vv-deploy --force` |
| See deploy logs | `journalctl -u vv-deploy -n 50` |
| Next automatic check | `systemctl list-timers vv-deploy.timer` |
| Roll back | `vv-rollback` (previous) · `vv-rollback --list` · `vv-rollback <folder>` |
| Resume after a rollback | `sudo -u vvdeploy vv-deploy --force` |

A rollback **pins** the site, so the 5-minute check does not redeploy over it until you
run `vv-deploy --force`.

## Checks

```bash
curl -I https://vishnuvahan.com              # 200 + security headers
curl -I https://www.vishnuvahan.com          # 301 → https://vishnuvahan.com
curl -I http://vishnuvahan.com               # 301 → https://
curl -s https://vishnuvahan.com/nothing | grep "Link lost"   # custom 404
sudo certbot renew --dry-run                 # certificate renewal works
```

## If the repository becomes private

The server clones over HTTPS without a password, so that only works while the repo is public.
For a private repo, add a read-only **deploy key**: run
`sudo -u vvdeploy ssh-keygen -t ed25519 -N "" -f /home/vvdeploy/.ssh/id_ed25519`, add the
`.pub` file in GitHub → repo → Settings → Deploy keys, then run
`sudo -u vvdeploy git -C /var/www/vishnuvahan.com/repo remote set-url origin git@github.com:VishnuVahanDas/VishnuVahanDas-web.git`.

## Later: the small API (Phase 6)

The commented `location /api/` block in the nginx config is where the Django API will go.
