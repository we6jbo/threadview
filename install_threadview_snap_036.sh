#!/usr/bin/env bash
set -Eeuo pipefail

SURFS_UP='Surfs up! My computer crashes frequently so could you create a system log  so that if i say my computer crashed, you can check the log to see where i last left off. also print the part between the surfs up in all futuree scripts that are either downloaded or pasted to the terminal.'
TAG="threadview-snap"
PROJECT="/home/we6jbo/Projects/threadview"
ZIP_NAME="threadview-0.3.6-snap.zip"
OWNER="we6jbo:we6jbo"

say() { printf '%s\n' "$*"; }
checkpoint() { say "[ThreadView Snap] $*"; logger -t "$TAG" -- "$*" 2>/dev/null || true; }

say "$SURFS_UP"
checkpoint "BEGIN: installing ThreadView 0.3.6 licensing update."
say
if command -v t14-finish >/dev/null 2>&1; then t14-finish deadline || true; fi
say
say "Progress: 0% — expected install time under 2 minutes."
say "This update adds MIT licensing for the source code and CC0-1.0 for assets/share91f.stl."

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

checkpoint "Checkpoint 1/4: package found at $ZIP"
say "Progress: 25%"
unzip -o "$ZIP" -d "$PROJECT" >/dev/null
checkpoint "Checkpoint 2/4: 0.3.6 files extracted."
say "Progress: 60%"

grep -q '^license: MIT AND CC0-1.0$' "$PROJECT/snap/snapcraft.yaml" || {
  checkpoint "STOP: Snap license metadata was not updated correctly."
  exit 4
}
[[ -f "$PROJECT/LICENSE" && -f "$PROJECT/assets/LICENSE" ]] || {
  checkpoint "STOP: expected license files are missing."
  exit 5
}
checkpoint "Checkpoint 3/4: licensing files and Snap metadata verified."
say "Progress: 80%"

if find "$PROJECT" -xdev \( -user root -o -group root \) -print -quit | grep -q .; then
  say "Root-owned paths detected; one sudo authentication may be requested."
  sudo -v
  sudo chown -R "$OWNER" "$PROJECT"
fi

if find "$PROJECT" -xdev \( -user root -o -group root \) -print -quit | grep -q .; then
  checkpoint "STOP: ownership verification failed."
  exit 6
fi

checkpoint "Checkpoint 4/4: ThreadView 0.3.6 licensing update installed."
say "Progress: 100%"
say
say "Next:"
say "  cd $PROJECT"
say "  ./build_and_test_snap.sh"
say
say "When the build says SAFE TO STEP AWAY NOW, you can leave it running."
say
say "Crash recovery:"
say "  journalctl -t $TAG -b -n 200 --no-pager"
say "  journalctl -t $TAG -b -1 -n 200 --no-pager"
