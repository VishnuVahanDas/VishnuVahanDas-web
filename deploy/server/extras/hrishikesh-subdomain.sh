#!/usr/bin/env bash
# =============================================================================
#  Serve the Hrishikesh Django app at https://hrishikesh.vishnuvahan.com
#  (it used to answer on http://vishnuvahan.com, which now serves the logbook site).
#
#  Before running: add a DNS A record  hrishikesh.vishnuvahan.com → 88.222.241.219
#  Run as root on the VPS:
#     bash deploy/server/extras/hrishikesh-subdomain.sh
#
#  Adds ONE new nginx site. Every change is tested with `nginx -t` and undone if it
#  fails. The app itself (hrishikesh.service, /run/hrishikesh.sock) is not modified.
#  Safe to run again.
# =============================================================================
set -euo pipefail

SUB="hrishikesh.vishnuvahan.com"
SOCK="/run/hrishikesh.sock"
SERVICE="hrishikesh.service"
ACME_ROOT="/var/www/letsencrypt"
SERVER_IP="88.222.241.219"
SITE_FILE="/etc/nginx/sites-available/$SUB.conf"
SITE_LINK="/etc/nginx/sites-enabled/$SUB.conf"
CERT="/etc/letsencrypt/live/$SUB/fullchain.pem"

bold() { printf '\n\033[1m== %s\033[0m\n' "$*"; }
ok() { printf '   \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '   \033[33m!\033[0m %s\n' "$*"; }
die() { printf '\n\033[31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Run as root."

bold "1/4  Checks"
nginx -t >/dev/null 2>&1 || die "'nginx -t' already fails before any change; fix that first."
ok "current nginx config is valid"
systemctl is-active --quiet "$SERVICE" || die "$SERVICE is not running (systemctl status $SERVICE)."
[[ -S "$SOCK" ]] || die "Socket $SOCK not found."
ok "$SERVICE is running on $SOCK"

IPS="$(getent ahostsv4 "$SUB" 2>/dev/null | awk '{print $1}' | sort -u | tr '\n' ' ')"
LOCAL_IPS=" $(hostname -I 2>/dev/null || true) $SERVER_IP "
if [[ -z "$IPS" ]]; then
  die "DNS: $SUB does not resolve yet. Add an A record → $SERVER_IP, wait a few minutes, run again."
fi
for ip in $IPS; do
  [[ "$LOCAL_IPS" == *" $ip "* ]] || die "DNS: $SUB points to $IPS, not this server ($SERVER_IP). Fix the A record, then run again."
done
ok "DNS: $SUB → this server"

# Does Django accept the new host name? (400 = not in ALLOWED_HOSTS)
APP_CODE="$(curl -s -o /dev/null -w '%{http_code}' --unix-socket "$SOCK" -H "Host: $SUB" -H "X-Forwarded-Proto: https" http://localhost/ || true)"
if [[ "$APP_CODE" == "400" ]]; then
  APP_NOTE="needs ALLOWED_HOSTS"
  warn "The app answers 400 for $SUB: Django's ALLOWED_HOSTS does not include it yet (see the end)."
else
  APP_NOTE="answers $APP_CODE"
  ok "the app answers $APP_CODE for $SUB"
fi

PREV=""
[[ -f "$SITE_FILE" ]] && PREV="$(cat "$SITE_FILE")"
apply() { # $1 = config text
  printf '%s\n' "$1" > "$SITE_FILE"
  ln -sfn "$SITE_FILE" "$SITE_LINK"
  [[ -e /proc/net/if_inet6 ]] || sed -i '/listen \[::\]/d' "$SITE_FILE"
  if ! nginx -t >/dev/null 2>&1; then
    nginx -t || true
    if [[ -n "$PREV" ]]; then printf '%s\n' "$PREV" > "$SITE_FILE"; else rm -f "$SITE_FILE" "$SITE_LINK"; fi
    nginx -t >/dev/null 2>&1 && systemctl reload nginx
    die "nginx rejected the config; it was undone and nothing else changed."
  fi
  systemctl reload nginx
}

PROXY='    location = /favicon.ico { access_log off; log_not_found off; }

    location / {
        include proxy_params;
        proxy_pass http://unix:'"$SOCK"';
    }'

HTTP_ONLY="# $SUB → Hrishikesh Django app (temporary HTTP config until the certificate exists)
server {
    listen 80;
    listen [::]:80;
    server_name $SUB;

    location ^~ /.well-known/acme-challenge/ {
        root $ACME_ROOT;
        default_type text/plain;
    }
$PROXY
}"

FULL="# $SUB → Hrishikesh Django app (hrishikesh.service, $SOCK)
server {
    listen 80;
    listen [::]:80;
    server_name $SUB;

    location ^~ /.well-known/acme-challenge/ {
        root $ACME_ROOT;
        default_type text/plain;
    }
    location / {
        return 301 https://$SUB\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $SUB;

    ssl_certificate     $CERT;
    ssl_certificate_key /etc/letsencrypt/live/$SUB/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    server_tokens off;
    add_header Strict-Transport-Security \"max-age=31536000\" always;
    add_header X-Content-Type-Options \"nosniff\" always;

$PROXY
}"

bold "2/4  nginx (HTTP)"
mkdir -p "$ACME_ROOT"
if [[ -f "$CERT" ]]; then
  ok "certificate already exists; skipping the HTTP-only step"
else
  apply "$HTTP_ONLY"
  ok "HTTP site for $SUB enabled"
fi

bold "3/4  HTTPS certificate"
certbot certonly --webroot -w "$ACME_ROOT" --cert-name "$SUB" -d "$SUB" \
  --keep-until-expiring --non-interactive --deploy-hook "systemctl reload nginx"
[[ -f "$CERT" ]] || die "No certificate was issued; the site stays on HTTP. Check the certbot output above."
apply "$FULL"
ok "HTTPS enabled for $SUB (renews automatically)"

bold "4/4  Result"
CODE="$(curl -s -o /dev/null -w '%{http_code}' --resolve "$SUB:443:127.0.0.1" "https://$SUB/" || true)"
ok "https://$SUB/ answers $CODE"

cat <<EOF

   App URL        https://$SUB
   nginx file     $SITE_FILE
   App status     $APP_NOTE

   Remember: the Flutter app's base URL must change to  https://$SUB
EOF

if [[ "$APP_NOTE" == "needs ALLOWED_HOSTS" || "$CODE" == "400" ]]; then
  echo
  echo "   Django needs the new host name. Files that set ALLOWED_HOSTS:"
  grep -rlE "ALLOWED_HOSTS|CSRF_TRUSTED_ORIGINS" /home/vishnuvahan/hrishikesh* \
    --include='*.py' --include='.env*' --exclude-dir='venv' --exclude-dir='.venv' \
    --exclude-dir='env' --exclude-dir='site-packages' 2>/dev/null | sed 's/^/     /' || true
  cat <<EOF

   Add to ALLOWED_HOSTS:          "$SUB"
   Add to CSRF_TRUSTED_ORIGINS:   "https://$SUB"
   Then:  systemctl restart $SERVICE
EOF
fi
