#!/usr/bin/env bash
set -Eeuo pipefail

SURFS_UP='Surfs up! My computer crashes frequently so could you create a system log  so that if i say my computer crashed, you can check the log to see where i last left off. also print the part between the surfs up in all futuree scripts that are either downloaded or pasted to the terminal.'
TAG="threadview-snap"
PROJECT="/home/we6jbo/Projects/threadview"
START="$(date +%s)"

say() { printf '%s\n' "$*"; }
checkpoint() { say "[ThreadView Snap] $*"; logger -t "$TAG" -- "$*" 2>/dev/null || true; }

say "$SURFS_UP"
checkpoint "BEGIN: ThreadView Snap Store edge publication."
say
if command -v t14-finish >/dev/null 2>&1; then t14-finish deadline || true; fi
say
say "Progress: 0% — hands-on time is usually a few minutes; Store review may take longer."
say "Once the upload starts, you can safely step away."
say

cd "$PROJECT"
command -v snapcraft >/dev/null 2>&1 || { checkpoint "STOP: snapcraft missing."; exit 2; }

if ! snapcraft whoami >/dev/null 2>&1; then
  checkpoint "STOP: Snapcraft account login required."
  say "Run: snapcraft login"
  say "Then rerun this script."
  exit 3
fi
checkpoint "Checkpoint 1/4: Snapcraft login confirmed."
say "Progress: 20%"

if ! snapcraft names 2>/dev/null | awk '{print $1}' | grep -Fxq threadview; then
  checkpoint "STOP: Snap Store name 'threadview' is not registered to this account."
  say "Register it first with:"
  say "  snapcraft register threadview"
  say "Then rerun this script."
  exit 4
fi
checkpoint "Checkpoint 2/4: Snap Store name 'threadview' is registered."
say "Progress: 40%"

SNAP_FILE="$(find "$PROJECT" -maxdepth 1 -type f -name 'threadview_0.3.4_*.snap' -printf '%T@ %p\n' | sort -nr | head -1 | cut -d' ' -f2-)"
[[ -n "$SNAP_FILE" && -f "$SNAP_FILE" ]] || {
  checkpoint "STOP: ThreadView 0.3.4 snap not found. Run ./build_and_test_snap.sh first."
  exit 5
}

checkpoint "Checkpoint 3/4: uploading $SNAP_FILE to latest/edge. SAFE TO STEP AWAY NOW."
say "Progress: 60% — safe to step away while upload/review completes."
snapcraft upload --release=edge "$SNAP_FILE"

checkpoint "Checkpoint 4/4: Snap Store edge upload/release command completed."
say "Progress: 100%"
say
say "Check the release with:"
say "  snapcraft status threadview"
say
say "Then open the ThreadView listing in the Snapcraft dashboard and add:"
say "  Screenshot: $PROJECT/screenshots/threadview.png"
say "  Category: Graphics (and Development/Utilities if the dashboard offers a suitable second category)"
say
say "One metadata item still needs your explicit choice: the software LICENSE."
say "I did not invent a license for your code or STL."
say
say "Crash recovery:"
say "  journalctl -t $TAG -b -n 200 --no-pager"
say "  journalctl -t $TAG -b -1 -n 200 --no-pager"
