#!/usr/bin/env bash
set -u

PROJECT_DIR="/home/we6jbo/Projects/threadview"
ZIP_NAME="threadview-0.2.zip"
STABLE_ID="threadview"
EXEC_PATH="$PROJECT_DIR/build/threadview"

echo "============================================================"
echo "ThreadView installer/update"
echo "============================================================"

if command -v t14-finish >/dev/null 2>&1; then
    echo
    echo "Project time/deadline:"
    t14-finish deadline || echo "t14-finish deadline returned a non-zero status; continuing."
else
    echo "t14-finish is not installed; continuing."
fi

echo

if [ ! -d "$PROJECT_DIR" ]; then
    echo "ThreadView project directory does not exist:"
    echo "  $PROJECT_DIR"
    echo
    echo "Create the project in Qt Creator first, then run this installer again."
    exit 2
fi

find_zip() {
    local candidates=(
        "$PWD/$ZIP_NAME"
        "$HOME/Downloads/$ZIP_NAME"
        "$HOME/Desktop/$ZIP_NAME"
        "/tmp/$ZIP_NAME"
    )
    local z
    for z in "${candidates[@]}"; do
        if [ -f "$z" ]; then
            printf '%s\n' "$z"
            return 0
        fi
    done
    return 1
}

ZIP_PATH="$(find_zip || true)"
if [ -z "$ZIP_PATH" ]; then
    echo "Could not find $ZIP_NAME."
    echo "Put the downloaded ZIP in your current directory or ~/Downloads and rerun this script."
    exit 3
fi

if ! command -v unzip >/dev/null 2>&1; then
    echo "The 'unzip' command is required."
    echo "On Manjaro: sudo pacman -S unzip"
    exit 4
fi

echo "Using package:"
echo "  $ZIP_PATH"
echo
echo "Extracting into:"
echo "  $PROJECT_DIR"

unzip -o "$ZIP_PATH" -d "$PROJECT_DIR" >/dev/null || {
    echo "Extraction failed."
    exit 5
}

echo "Source update installed."

# Best-effort local TG registration. Never fatal.
if command -v tg-register-project >/dev/null 2>&1; then
    tg-register-project \
        --project-id page.j03.threadview \
        --project-root "$PROJECT_DIR" \
        --codes TG315902,TG708346,TG628417,TG891052,TG654147 \
        --reference "ThreadView bundled McCabe context" \
        || echo "TG project registration failed; continuing installation."
else
    echo "tg-register-project is not installed; bundled metadata will be used."
fi

echo
echo "Attempting build..."
if command -v cmake >/dev/null 2>&1; then
    cmake -S "$PROJECT_DIR" -B "$PROJECT_DIR/build" && \
    cmake --build "$PROJECT_DIR/build" -j"$(nproc)" || \
    echo "Build failed; source files were still installed successfully."
else
    echo "cmake is not installed. On Manjaro:"
    echo "  sudo pacman -S --needed base-devel cmake qt6-base"
fi

# Best-effort Task Orchestrator registration. Never fatal.
if [ -x "$EXEC_PATH" ]; then
    if command -v taskorchestrator >/dev/null 2>&1; then
        taskorchestrator register \
            --id threadview \
            --name "ThreadView" \
            --exec "$EXEC_PATH" \
            --priority 20 \
            --duration 30 \
            --cadence weekly \
            || echo "Task Orchestrator registration failed; continuing installation."
    else
        echo "Task Orchestrator is not installed; skipping registration."
    fi
else
    echo "Executable is not built yet; skipping Task Orchestrator registration for now."
fi

echo
echo "Verification:"
echo "  test -f '$PROJECT_DIR/assets/share91f.stl' && echo STL_OK"
echo "  test -f '$PROJECT_DIR/metadata/tg_context_snapshot.json' && echo TG_METADATA_OK"
echo "  test -x '$EXEC_PATH' && echo BUILD_OK"
echo
echo "Run:"
echo "  $EXEC_PATH"
