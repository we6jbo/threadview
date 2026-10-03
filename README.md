# ThreadView

ThreadView is a small Qt 6 desktop application for viewing and animating a 3D-printable threaded fastener.

## Features
- Embedded `share91f.stl`
- Automatic rotation animation
- Mouse drag rotation
- Mouse wheel zoom
- Reset view
- Save/export the original STL for slicing and 3D printing
- Separate McCabe provenance/context tab
- Portable `tg_context_snapshot.json`

## Manjaro build dependencies

```bash
sudo pacman -S --needed base-devel cmake qt6-base
```

## Build

```bash
cmake -S . -B build
cmake --build build -j"$(nproc)"
./build/threadview
```

## Notes

The app is intentionally simple and self-contained. The STL is embedded in the Qt resource system so the same source tree can later be adapted for GitHub, Snap, and Flatpak distribution.
