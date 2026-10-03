#!/usr/bin/env bash
set -Eeuo pipefail

SURFS_UP='Surfs up! My computer crashes frequently so could you create a system log  so that if i say my computer crashed, you can check the log to see where i last left off. also print the part between the surfs up in all futuree scripts that are either downloaded or pasted to the terminal.'
TAG="threadview-snap"
PROJECT="/home/we6jbo/Projects/threadview"
ZIP_NAME="threadview-0.3.1-snap.zip"
OWNER="we6jbo:we6jbo"
KEEPALIVE_PID=""

say() { printf '%s\n' "$*"; }
checkpoint() {
  local msg="$*"
  say "[ThreadView Snap] $msg"
  logger -t "$TAG" -- "$msg" 2>/dev/null || true
}
cleanup() {
  if [[ -n "${KEEPALIVE_PID:-}" ]]; then kill "$KEEPALIVE_PID" 2>/dev/null || true; fi
}
trap cleanup EXIT

say "$SURFS_UP"
checkpoint "BEGIN: installing ThreadView Snap fix 0.3.1."
say
if command -v t14-finish >/dev/null 2>&1; then
  t14-finish deadline || true
fi
say
say "Progress: 0% — expected time under 2 minutes."
say "This update fixes the Snapcraft/Flatpak-cache permission failure and preserves the Flatpak cache."
say

[[ -d "$PROJECT" ]] || { checkpoint "STOP: project directory missing."; exit 2; }

ZIP=""
for candidate in "$PWD/$ZIP_NAME" "$HOME/Downloads/$ZIP_NAME" "$HOME/Desktop/$ZIP_NAME" "/tmp/$ZIP_NAME"; do
  if [[ -f "$candidate" ]]; then ZIP="$candidate"; break; fi
done
[[ -n "$ZIP" ]] || { checkpoint "STOP: $ZIP_NAME not found."; say "Put $ZIP_NAME in ~/Downloads."; exit 3; }

checkpoint "Checkpoint 1/4: package located at $ZIP"
say "Progress: 25%"
unzip -o "$ZIP" -d "$PROJECT" >/dev/null
checkpoint "Checkpoint 2/4: corrected Snap files extracted."
say "Progress: 55%"

if find "$PROJECT" -xdev \( -user root -o -group root \) -print -quit | grep -q .; then
  say "Root-owned paths detected. One sudo authentication may be requested for repair."
  sudo -v
  (
    while sleep 50; do sudo -n true 2>/dev/null || exit; done
  ) &
  KEEPALIVE_PID=$!
  sudo chown -R "$OWNER" "$PROJECT"
fi

if find "$PROJECT" -xdev \( -user root -o -group root \) -print -quit | grep -q .; then
  checkpoint "WARNING: ownership verification did not fully pass."
else
  checkpoint "Checkpoint 3/4: ownership PASS ($OWNER)."
fi
say "Progress: 80%"

checkpoint "Checkpoint 4/4: Snap fix installed."
say "Progress: 100%"
say
say "Next:"
say "  cd $PROJECT"
say "  ./build_and_test_snap.sh"
say
say "Crash recovery:"
say "  journalctl -t $TAG -b -n 200 --no-pager"
say "  journalctl -t $TAG -b -1 -n 200 --no-pager"
