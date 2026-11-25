#!/usr/bin/env bash
# =============================================================================
#  vishnuvahan.com: one-time production setup for the VPS.  Run as root:
#
#     curl -fsSLO https://raw.githubusercontent.com/VishnuVahanDas/VishnuVahanDas-web/main/deploy/server/setup.sh
#     bash setup.sh
#
#  Safe to run again (it skips what is already done). What it does:
#    1. Checks the server (OS, nginx, DNS) and prints what it found.
#    2. Creates a locked-down `vvdeploy` system user (no password, no login shell).
#    3. Installs Node 24 privately in /opt/node24. The system `node`, if any, is untouched.
#    4. Clones the repo and builds the first release into /var/www/vishnuvahan.com.
#    5. Adds ONE new nginx site for vishnuvahan.com. Other sites are never edited.
#       Every nginx change is checked with `nginx -t` first and undone if it fails.
#    6. Gets a Let's Encrypt certificate (webroot) and switches the site to HTTPS.
#    7. Installs a systemd timer: every 5 minutes, if GitHub `main` has a new commit,
#       it builds and goes live automatically.
# =============================================================================
set -euo pipefail

DOMAIN="vishnuvahan.com"
WWW="www.vishnuvahan.com"
REPO_URL="https://github.com/VishnuVahanDas/VishnuVahanDas-web.git"
BRANCH="main"
BASE="/var/www/vishnuvahan.com"
ACME_ROOT="/var/www/letsencrypt"
DEPLOY_USER="vvdeploy"
NODE_DIR="/opt/node24"
SERVER_IP="88.222.241.219"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="/root/vishnuvahan-nginx-backup-$TS"

bold() { printf '\n\033[1m== %s\033[0m\n' "$*"; }
ok() { printf '   \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '   \033[33m!\033[0m %s\n' "$*"; }
die() { printf '\n\033[31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Run as root (you are $(whoami))."
command -v apt-get >/dev/null || die "This script expects a Debian/Ubuntu server (apt-get)."

# ---------------------------------------------------------------------------
bold "1/7  Checking the server"
. /etc/os-release
ok "OS: $PRETTY_NAME ($(uname -m))"
command -v nginx >/dev/null || die "nginx is not installed. (Your other sites use it, so this is unexpected; stopping.)"
ok "nginx: $(nginx -v 2>&1 | sed 's/.*nginx\///')"
nginx -t >/dev/null 2>&1 || die "'nginx -t' already fails BEFORE any change. Fix that first, then re-run."
ok "current nginx config is valid"
systemctl is-active --quiet nginx || die "nginx is not running."

if [[ -d /etc/nginx/sites-enabled ]]; then
  LAYOUT="sites"
  SITE_FILE="/etc/nginx/sites-available/$DOMAIN.conf"
  SITE_LINK="/etc/nginx/sites-enabled/$DOMAIN.conf"
else
  LAYOUT="confd"
  SITE_FILE="/etc/nginx/conf.d/$DOMAIN.conf"
  SITE_LINK=""
fi
ok "nginx layout: $LAYOUT"

LOCAL_IPS="$(hostname -I 2>/dev/null || true) $SERVER_IP"
resolves_here() {
  local ips
  ips="$(getent ahostsv4 "$1" 2>/dev/null | awk '{print $1}' | sort -u | tr '\n' ' ')"
  [[ -n "$ips" ]] || return 1
  for ip in $ips; do [[ " $LOCAL_IPS " == *" $ip "* ]] || return 1; done
}
DNS_APEX=0; DNS_WWW=0
if resolves_here "$DOMAIN"; then DNS_APEX=1; ok "DNS: $DOMAIN → this server"; else
  warn "DNS: $DOMAIN does not point here yet (it resolves to: $(getent ahostsv4 "$DOMAIN" | awk '{print $1}' | sort -u | tr '\n' ' ')). HTTPS will be skipped for now."
fi
if resolves_here "$WWW"; then DNS_WWW=1; ok "DNS: $WWW → this server"; else
  warn "DNS: $WWW does not point here; the site will run without www."
fi
if getent ahostsv6 "$DOMAIN" 2>/dev/null | grep -q .; then
  warn "DNS: $DOMAIN also has an IPv6 (AAAA) record. If it does not point to this server, Let's Encrypt may fail; remove it at your DNS provider."
fi

# ---------------------------------------------------------------------------
bold "2/7  Packages and deploy user"
NEED=()
for pkg in git curl ca-certificates xz-utils; do dpkg -s "$pkg" >/dev/null 2>&1 || NEED+=("$pkg"); done
command -v certbot >/dev/null || NEED+=("certbot")
if ((${#NEED[@]})); then
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${NEED[@]}" >/dev/null
  ok "installed: ${NEED[*]}"
else
  ok "git, curl, xz-utils, certbot already present"
fi

if id "$DEPLOY_USER" >/dev/null 2>&1; then
  ok "user $DEPLOY_USER exists"
else
  useradd --system --create-home --home-dir "/home/$DEPLOY_USER" --shell /usr/sbin/nologin "$DEPLOY_USER"
  ok "created system user $DEPLOY_USER (no password, no login shell)"
fi

# ---------------------------------------------------------------------------
bold "3/7  Node 24 (private copy in $NODE_DIR)"
if [[ -x "$NODE_DIR/bin/node" ]] && [[ "$("$NODE_DIR/bin/node" -v)" == v24.* ]]; then
  ok "already installed: $("$NODE_DIR/bin/node" -v)"
else
  case "$(uname -m)" in
    x86_64) NARCH="x64" ;;
    aarch64 | arm64) NARCH="arm64" ;;
    *) die "Unsupported CPU: $(uname -m)" ;;
  esac
  TMPD="$(mktemp -d)"
  curl -fsSL "https://nodejs.org/dist/latest-v24.x/SHASUMS256.txt" -o "$TMPD/SHASUMS256.txt"
  TARBALL="$(grep -o "node-v24[^ ]*-linux-$NARCH.tar.xz" "$TMPD/SHASUMS256.txt" | head -n1)"
  [[ -n "$TARBALL" ]] || die "Could not find a Node 24 build for linux-$NARCH"
  curl -fsSL "https://nodejs.org/dist/latest-v24.x/$TARBALL" -o "$TMPD/$TARBALL"
  (cd "$TMPD" && grep " $TARBALL\$" SHASUMS256.txt | sha256sum -c --quiet -) || die "Node download checksum mismatch"
  rm -rf "$NODE_DIR" && mkdir -p "$NODE_DIR"
  tar -xJf "$TMPD/$TARBALL" -C "$NODE_DIR" --strip-components=1
  rm -rf "$TMPD"
  ok "installed $("$NODE_DIR/bin/node" -v) (checksum verified)"
fi

# ---------------------------------------------------------------------------
bold "4/7  Code and first build"
mkdir -p "$BASE/releases" "$ACME_ROOT"
chown "$DEPLOY_USER:$DEPLOY_USER" "$BASE" "$BASE/releases"
if [[ -d "$BASE/repo/.git" ]]; then
  ok "repo already cloned"
else
  runuser -u "$DEPLOY_USER" -- git clone --quiet --branch "$BRANCH" "$REPO_URL" "$BASE/repo"
  ok "cloned $REPO_URL"
fi
runuser -u "$DEPLOY_USER" -- git -C "$BASE/repo" fetch --quiet origin "$BRANCH"
runuser -u "$DEPLOY_USER" -- git -C "$BASE/repo" reset --quiet --hard "origin/$BRANCH"
[[ -f "$BASE/repo/site/package.json" ]] || die "The repo has no site/package.json. Push the full project (with site/, deploy/, docs/) to $BRANCH first."

install -m 0755 "$BASE/repo/deploy/server/vv-deploy" /usr/local/bin/vv-deploy
install -m 0755 "$BASE/repo/deploy/scripts/rollback.sh" /usr/local/bin/vv-rollback
ok "installed /usr/local/bin/vv-deploy and /usr/local/bin/vv-rollback"

echo "   building (first build takes 1–3 minutes)…"
runuser -u "$DEPLOY_USER" -- env HOME="/home/$DEPLOY_USER" /usr/local/bin/vv-deploy --force
[[ -f "$BASE/current/index.html" ]] || die "Build finished but $BASE/current/index.html is missing."
ok "live release: $(basename "$(readlink "$BASE/current")")"

# ---------------------------------------------------------------------------
bold "5/7  nginx site for $DOMAIN"
mkdir -p /etc/nginx/snippets
install -m 0644 "$BASE/repo/deploy/nginx/vishnuvahan-headers.conf" /etc/nginx/snippets/vishnuvahan-headers.conf

# Old configs for this domain (e.g. a previous portfolio) would clash with the new one.
# Disable them ONLY if the file serves nothing but this domain; otherwise stop and ask.
OLD_FILES=()
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  real="$(readlink -f "$f")"
  [[ "$real" == "$(readlink -f "$SITE_FILE" 2>/dev/null || echo none)" ]] && continue
  OLD_FILES+=("$f")
done < <(grep -lsE "server_name[^;]*(^|[[:space:]])(www\.)?vishnuvahan\.com([[:space:];]|$)" /etc/nginx/sites-enabled/* /etc/nginx/conf.d/*.conf 2>/dev/null || true)

for f in "${OLD_FILES[@]}"; do
  others="$(grep -hoE "server_name[^;]*;" "$f" | tr ' ;' '\n\n' | grep -vE '^(server_name|_?|(www\.)?vishnuvahan\.com)$' | grep . || true)"
  if [[ -n "$others" ]]; then
    die "$f also serves other domains: $(echo $others). Not touching it. Remove the vishnuvahan.com server block from it by hand, then re-run."
  fi
done

restore_old() {
  for f in "${OLD_FILES[@]}"; do
    name="$(basename "$f")"
    if [[ -L "$BACKUP/$name.link" ]]; then ln -sfn "$(readlink "$BACKUP/$name.link")" "$f"; fi
    if [[ -f "$BACKUP/$name.moved" ]]; then mv "$BACKUP/$name.moved" "$f"; fi
  done
}

if ((${#OLD_FILES[@]})); then
  mkdir -p "$BACKUP"
  for f in "${OLD_FILES[@]}"; do
    name="$(basename "$f")"
    cp -L "$f" "$BACKUP/$name.content"
    if [[ -L "$f" ]]; then
      ln -s "$(readlink "$f")" "$BACKUP/$name.link" && rm "$f"
    else
      mv "$f" "$BACKUP/$name.moved"
    fi
    warn "disabled old config for this domain: $f (backup in $BACKUP)"
  done
fi

PREV_SITE=""
[[ -f "$SITE_FILE" ]] && PREV_SITE="$(cat "$SITE_FILE")"

apply_site() { # $1 = config file to install
  install -m 0644 "$1" "$SITE_FILE"
  if [[ -n "$SITE_LINK" ]]; then ln -sfn "$SITE_FILE" "$SITE_LINK"; fi
  if [[ ! -e /proc/net/if_inet6 ]]; then sed -i '/listen \[::\]/d' "$SITE_FILE"; fi
  if ! nginx -t >/dev/null 2>&1; then
    nginx -t || true
    if [[ -n "$PREV_SITE" ]]; then printf '%s\n' "$PREV_SITE" > "$SITE_FILE"; else rm -f "$SITE_FILE" ${SITE_LINK:+"$SITE_LINK"}; fi
    restore_old
    nginx -t >/dev/null 2>&1 && systemctl reload nginx
    die "nginx rejected the new config. Everything was put back exactly as before; no site was affected."
  fi
  systemctl reload nginx
}

CERT="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
FULL_CONF="$(mktemp)"
cp "$BASE/repo/deploy/nginx/vishnuvahan.com.conf" "$FULL_CONF"
if [[ $DNS_WWW -eq 0 ]]; then
  sed -i '/# BEGIN-WWW/,/# END-WWW/d; s/ www\.vishnuvahan\.com//' "$FULL_CONF"
fi

if [[ -f "$CERT" ]]; then
  apply_site "$FULL_CONF"
  ok "HTTPS site enabled (existing certificate)"
else
  apply_site "$BASE/repo/deploy/nginx/vishnuvahan.com.http-only.conf"
  ok "HTTP site enabled (certificate comes next)"
fi

# ---------------------------------------------------------------------------
bold "6/7  HTTPS certificate"
if [[ $DNS_APEX -eq 1 ]]; then
  DOMAINS=(-d "$DOMAIN")
  [[ $DNS_WWW -eq 1 ]] && DOMAINS+=(-d "$WWW")
  CB=(certbot certonly --webroot -w "$ACME_ROOT" --cert-name "$DOMAIN" "${DOMAINS[@]}"
      --keep-until-expiring --expand --deploy-hook "systemctl reload nginx")
  if ls /etc/letsencrypt/accounts/*/directory/* >/dev/null 2>&1; then
    "${CB[@]}" --non-interactive
  else
    echo "   First certificate on this server: certbot will ask for an email and the Let's Encrypt terms."
    "${CB[@]}"
  fi
  if [[ -f "$CERT" ]]; then
    apply_site "$FULL_CONF"
    ok "HTTPS enabled; certificate renews automatically (certbot timer)"
  else
    warn "No certificate yet; the site stays on HTTP. Re-run this script after fixing DNS."
  fi
else
  warn "Skipped: point $DOMAIN (A record) to $SERVER_IP, wait for DNS, then run 'bash setup.sh' again."
fi
rm -f "$FULL_CONF"

# ---------------------------------------------------------------------------
bold "7/7  Auto-deploy from GitHub"
install -m 0644 "$BASE/repo/deploy/server/vv-deploy.service" /etc/systemd/system/vv-deploy.service
install -m 0644 "$BASE/repo/deploy/server/vv-deploy.timer" /etc/systemd/system/vv-deploy.timer
systemctl daemon-reload
systemctl enable --now vv-deploy.timer >/dev/null 2>&1
ok "vv-deploy.timer active: checks GitHub every 5 minutes"

# ---------------------------------------------------------------------------
bold "Done"
SCHEME="http"; [[ -f "$CERT" ]] && SCHEME="https"
CODE="$(curl -s -o /dev/null -w '%{http_code}' --resolve "$DOMAIN:443:127.0.0.1" --resolve "$DOMAIN:80:127.0.0.1" "$SCHEME://$DOMAIN/" || true)"
ok "$SCHEME://$DOMAIN/ answers $CODE from this server"
cat <<EOF

   Live site      $SCHEME://$DOMAIN
   Files          $BASE/current  →  $(readlink "$BASE/current")
   Deploy now     sudo -u $DEPLOY_USER vv-deploy --force
   Deploy log     journalctl -u vv-deploy -n 50
   Roll back      vv-rollback          (list: vv-rollback --list)
   Old config     ${OLD_FILES[*]:+backed up in $BACKUP}${OLD_FILES[*]:-none was found}

EOF
