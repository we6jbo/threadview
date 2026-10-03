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


## Snap packaging

ThreadView includes `snap/snapcraft.yaml` plus two helper scripts.

Build and locally test the Snap:

```bash
./build_and_test_snap.sh
```

After visually testing the local Snap, upload it to the Snap Store **edge** channel:

```bash
./publish_snap_edge.sh
```

The edge channel is used because ThreadView is an experimental, niche application.


## License

ThreadView source code is licensed under the MIT License. The bundled `assets/share91f.stl` model is dedicated under CC0 1.0 Universal. See `LICENSE` and `assets/LICENSE`.
