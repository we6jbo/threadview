#!/usr/bin/env bash
set -Eeuo pipefail

SURFS_UP='Surfs up! My computer crashes frequently so could you create a system log  so that if i say my computer crashed, you can check the log to see where i last left off. also print the part between the surfs up in all futuree scripts that are either downloaded or pasted to the terminal.'
TAG="threadview-snap"
PROJECT="/home/we6jbo/Projects/threadview"

say() { printf '%s\n' "$*"; }
checkpoint() { say "[ThreadView Snap] $*"; logger -t "$TAG" -- "$*" 2>/dev/null || true; }

say "$SURFS_UP"
checkpoint "BEGIN: publishing licensed ThreadView 0.3.6 to latest/edge."
say
if command -v t14-finish >/dev/null 2>&1; then t14-finish deadline || true; fi
say
say "Progress: 0% — this script is pinned specifically to ThreadView 0.3.6."
say "Once upload begins, it is safe to step away."
say

cd "$PROJECT"
SNAP_FILE="$PROJECT/threadview_0.3.6_amd64.snap"
[[ -f "$SNAP_FILE" ]] || {
  checkpoint "STOP: $SNAP_FILE not found. Run ./build_and_test_snap.sh first."
  exit 2
}

snapcraft whoami >/dev/null 2>&1 || {
  checkpoint "STOP: Snapcraft login required."
  say "Run: snapcraft login"
  exit 3
}

checkpoint "Checkpoint 1/3: login confirmed and 0.3.6 package found."
say "Progress: 30%"
checkpoint "Checkpoint 2/3: uploading 0.3.6 to latest/edge. SAFE TO STEP AWAY NOW."
say "Progress: 60%"
snapcraft upload "$SNAP_FILE" --release=edge

checkpoint "Checkpoint 3/3: upload/release command completed."
say "Progress: 90%"
snapcraft status threadview
say "Progress: 100% — ThreadView 0.3.6 licensing release complete."
say
say "Crash recovery:"
say "  journalctl -t $TAG -b -n 200 --no-pager"
say "  journalctl -t $TAG -b -1 -n 200 --no-pager"
