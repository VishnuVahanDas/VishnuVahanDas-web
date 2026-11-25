#!/usr/bin/env bash
# Roll the live site back to an earlier release. Run on the VPS as root.
#   bash rollback.sh                       → the release before the live one
#   bash rollback.sh 20261125103000-abc…   → a specific folder in releases/
#   bash rollback.sh --list                → show releases
# A rollback PINS the site so the 5-minute auto-deploy does not undo it.
# To resume auto-deploy:  sudo -u vvdeploy vv-deploy --force
set -euo pipefail
BASE="${VV_BASE:-/var/www/vishnuvahan.com}"
cd "$BASE/releases"
LIVE="$(basename "$(readlink "$BASE/current")")"

if [[ "${1:-}" == "--list" ]]; then
  ls -1 | sort -r | sed "s/^$LIVE\$/$LIVE   ← live/"
  exit 0
fi

if [[ $# -ge 1 ]]; then
  TARGET="$1"
else
  TARGET="$(ls -1 | sort -r | grep -vx "$LIVE" | head -n 1 || true)"
fi
[[ -n "$TARGET" && -d "$BASE/releases/$TARGET" ]] || { echo "No such release: ${TARGET:-<none>}"; exit 1; }

ln -sfn "$BASE/releases/$TARGET" "$BASE/current.tmp"
mv -Tf "$BASE/current.tmp" "$BASE/current"
echo "$TARGET (pinned $(date -u +%FT%TZ))" > "$BASE/.pinned"
chown vvdeploy:vvdeploy "$BASE/.pinned" 2>/dev/null || true
echo "Rolled back. Live: $TARGET"
echo "Auto-deploy is paused. Resume with:  sudo -u vvdeploy vv-deploy --force"
