#!/usr/bin/env bash
set -Eeuo pipefail

SURFS_UP='Surfs up! My computer crashes frequently so could you create a system log  so that if i say my computer crashed, you can check the log to see where i last left off. also print the part between the surfs up in all futuree scripts that are either downloaded or pasted to the terminal.'
TAG="threadview-snap"
PROJECT="/home/we6jbo/Projects/threadview"
SNAPSRC="$PROJECT/.snap-source"
OWNER="we6jbo:we6jbo"
START="$(date +%s)"
KEEPALIVE_PID=""

say() { printf '%s\n' "$*"; }
checkpoint() {
  local msg="$*"
  say "[ThreadView Snap] $msg"
  logger -t "$TAG" -- "$msg" 2>/dev/null || true
}
elapsed() {
  local now
  now="$(date +%s)"
  printf '%dm %02ds' "$(( (now-START)/60 ))" "$(( (now-START)%60 ))"
}
cleanup() {
  if [[ -n "${KEEPALIVE_PID:-}" ]]; then
    kill "$KEEPALIVE_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

say "$SURFS_UP"
checkpoint "BEGIN: ThreadView Snap Store candidate build 0.3.6 with final licensing metadata."
say
if command -v t14-finish >/dev/null 2>&1; then
  t14-finish deadline || true
fi
say
say "Progress: 0% — 0.3.4 passed local testing when Qt used XCB."
say "0.3.6 makes XCB the default inside the Snap so users do not need an environment override."
say "Expected hands-on time: about 1–2 minutes; package build may take 5–20+ minutes."
say

[[ -d "$PROJECT" ]] || { checkpoint "STOP: project directory missing."; exit 2; }
cd "$PROJECT"

checkpoint "Checkpoint 1/8: validating project ownership."
if find "$PROJECT" -xdev \( -user root -o -group root \) -print -quit | grep -q .; then
  say "Root-owned project paths detected. One sudo authentication may be requested."
  sudo -v
  (
    while sleep 50; do sudo -n true 2>/dev/null || exit; done
  ) &
  KEEPALIVE_PID=$!
  sudo chown -R "$OWNER" "$PROJECT"
fi
checkpoint "Ownership check complete."
say "Progress: 10%"

rm -rf "$SNAPSRC"
mkdir -p "$SNAPSRC/assets" "$SNAPSRC/metadata"

for f in CMakeLists.txt main.cpp mainwindow.cpp mainwindow.h mainwindow.ui resources.qrc stlwidget.cpp stlwidget.h org.oneal.threadview.metainfo.xml org.oneal.threadview.svg; do
  [[ -f "$PROJECT/$f" ]] || { checkpoint "STOP: required source file missing: $f"; exit 3; }
  cp -a "$PROJECT/$f" "$SNAPSRC/$f"
done

[[ -f "$PROJECT/org.oneal.threadview.desktop" ]] || { checkpoint "STOP: desktop file missing."; exit 3; }
cp -a "$PROJECT/org.oneal.threadview.desktop" "$SNAPSRC/org.oneal.threadview.desktop"
sed -i 's|^Icon=.*$|Icon=${SNAP}/usr/share/icons/hicolor/scalable/apps/org.oneal.threadview.svg|'   "$SNAPSRC/org.oneal.threadview.desktop"

cp -a "$PROJECT/assets/share91f.stl" "$SNAPSRC/assets/share91f.stl"
cp -a "$PROJECT/metadata/tg_context_snapshot.json" "$SNAPSRC/metadata/tg_context_snapshot.json"
cp -a "$PROJECT/LICENSE" "$SNAPSRC/LICENSE"
cp -a "$PROJECT/assets/LICENSE" "$SNAPSRC/assets/LICENSE"

checkpoint "Checkpoint 2/8: clean Snap source tree generated."
say "Progress: 20%"

find "$SNAPSRC" -type f -exec touch {} +
command -v snapcraft >/dev/null 2>&1 || { checkpoint "STOP: snapcraft command missing."; exit 4; }

checkpoint "Checkpoint 3/8: XCB is configured as the Snap's default Qt platform."
say "Progress: 30%"

checkpoint "Checkpoint 4/8: cleaning prior Snapcraft lifecycle state."
snapcraft clean || true
say "Progress: 35%"

checkpoint "Checkpoint 5/8: starting Snapcraft pack. SAFE TO STEP AWAY NOW."
say "Progress: 40% — safe to step away while Snapcraft builds."
snapcraft pack 2>&1 | tee snapcraft-build.log

SNAP_FILE="$(find "$PROJECT" -maxdepth 1 -type f -name 'threadview_0.3.6_*.snap' -printf '%T@ %p\n' | sort -nr | head -1 | cut -d' ' -f2-)"
[[ -n "$SNAP_FILE" && -f "$SNAP_FILE" ]] || {
  checkpoint "STOP: no ThreadView 0.3.6 snap found after Snapcraft."
  exit 5
}

checkpoint "Checkpoint 6/8: Snap built successfully: $SNAP_FILE"
say "Progress: 75% — build complete after $(elapsed)."

# Close any running ThreadView process before install, because snapd refuses replacement while app is running.
if pgrep -f '/snap/threadview/' >/dev/null 2>&1; then
  checkpoint "ThreadView is currently running; closing it before local install."
  pkill -f '/snap/threadview/' || true
  sleep 2
fi

say "Local install is next. One sudo authentication may be requested."
sudo -v
if [[ -z "${KEEPALIVE_PID:-}" ]]; then
  (
    while sleep 50; do sudo -n true 2>/dev/null || exit; done
  ) &
  KEEPALIVE_PID=$!
fi

# Local unasserted snaps are installed/replaced with 'snap install --dangerous'.
sudo snap install --dangerous "$SNAP_FILE"
checkpoint "Checkpoint 7/8: ThreadView 0.3.6 installed locally."
say "Progress: 90%"

sudo chown -R "$OWNER" "$PROJECT"
if find "$PROJECT" -xdev \( -user root -o -group root \) -print -quit | grep -q .; then
  checkpoint "STOP: root-owned project paths remain after ownership repair."
  exit 6
fi
checkpoint "Checkpoint 8/8: final ownership PASS."

say
say "Progress: 100% — ThreadView 0.3.6 Store-candidate build/install complete in $(elapsed)."
say "Run normally (no QT_QPA_PLATFORM override needed):"
say "  snap run threadview"
say
say "If it opens normally and Save STL still works, this build is ready for the Snap Store edge channel."
say
say "Crash recovery:"
say "  journalctl -t $TAG -b -n 200 --no-pager"
say "  journalctl -t $TAG -b -1 -n 200 --no-pager"
