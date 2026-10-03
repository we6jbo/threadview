#!/usr/bin/env bash
set -Eeuo pipefail

SURFS_UP='Surfs up! My computer crashes frequently so could you create a system log  so that if i say my computer crashed, you can check the log to see where i last left off. also print the part between the surfs up in all futuree scripts that are either downloaded or pasted to the terminal.'
TAG="threadview-snap"
PROJECT="/home/we6jbo/Projects/threadview"
ZIP_NAME="threadview-0.3.3-snap.zip"
OWNER="we6jbo:we6jbo"

say() { printf '%s\n' "$*"; }
checkpoint() { say "[ThreadView Snap] $*"; logger -t "$TAG" -- "$*" 2>/dev/null || true; }

say "$SURFS_UP"
checkpoint "BEGIN: installing ThreadView Snap desktop-path fix 0.3.3."
say
if command -v t14-finish >/dev/null 2>&1; then t14-finish deadline || true; fi
say
say "Progress: 0% — expected time under 2 minutes."
say "The previous build compiled successfully; this update only fixes the Snap desktop entry path."

[[ -d "$PROJECT" ]] || { checkpoint "STOP: project directory missing."; exit 2; }

ZIP=""
for candidate in "$PWD/$ZIP_NAME" "$HOME/Downloads/$ZIP_NAME" "$HOME/Desktop/$ZIP_NAME" "/tmp/$ZIP_NAME"; do
  if [[ -f "$candidate" ]]; then ZIP="$candidate"; break; fi
done
[[ -n "$ZIP" ]] || {
  checkpoint "STOP: $ZIP_NAME not found."
  say "Put $ZIP_NAME in ~/Downloads and rerun."
  exit 3
}

checkpoint "Checkpoint 1/3: package found at $ZIP"
say "Progress: 30%"
unzip -o "$ZIP" -d "$PROJECT" >/dev/null
checkpoint "Checkpoint 2/3: corrected Snap desktop-path files extracted."
say "Progress: 70%"

if find "$PROJECT" -xdev \( -user root -o -group root \) -print -quit | grep -q .; then
  say "Root-owned paths detected; one sudo authentication may be requested."
  sudo -v
  sudo chown -R "$OWNER" "$PROJECT"
fi

checkpoint "Checkpoint 3/3: 0.3.3 desktop-path fix installed."
say "Progress: 100%"
say
say "Next:"
say "  cd $PROJECT"
say "  ./build_and_test_snap.sh"
say
say "Crash recovery:"
say "  journalctl -t $TAG -b -n 200 --no-pager"
say "  journalctl -t $TAG -b -1 -n 200 --no-pager"
