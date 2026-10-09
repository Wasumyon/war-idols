# War Idols

Design and prototype repository. A war-journalism story set on Io, and a
2.5D vehicle "filming runner" prototype built in Godot.

## Layout

| Folder / file | Contents |
|---|---|
| `War Idols - Design Doc (Clean Version).docx` | The design doc. |
| `Characters/` | Character concept art, sketches, turnarounds. |
| `Enemy models/` | Enemy and vehicle concepts (drone, buggy, tank). |
| `Environment and Concept art/` | Environment concepts and painterly reference. |
| `UI Base/` | UI reference. |
| `Stories/` | Prose. |
| `car/` | **Godot 4.7 prototype** (the "slice" minigame + the VN scenes). |
| `war idol.clip`, `image-48.webp` | Raw art sources. |

## Running the prototype

1. Install **Godot 4.7.x** (standard build, no .NET needed).
2. Import `car/project.godot`.
3. Open `car/slice.tscn` and press **F6** (run current scene).

**Controls**

| Input | Action |
|---|---|
| A / D (or arrows) | Strafe a lane |
| W | Boost |
| S | Duck / take cover |
| Ctrl | Slow |
| Space | Jump |
| Shift | Dash (super armour; smashes obstacles) |
| Mouse | Aim the viewfinder |
| Right mouse | Zoom (slower, tighter) |
| Left mouse | Camera snap (good-snap toast) |
| Side mouse buttons | Duck (alt) |
| R | Restart |

**Notes**
- `.godot/` is git-ignored; Godot regenerates it the first time you open the project.
- The prototype is a **grey-box test build** — some art is still placeholder.
- The **visual novel** is `car/vn/vn.tscn` — open it and press **F6** (click / Space to advance). Scenes are plain text in `car/vn/dialogue/`.
- `car/test.tscn` is a driving sandbox and `car/test_static.tscn` is an asset-viewer rig; neither is the game.

## Git

- Repo: private, `Wasumyon/war-idols`.
- `.docx` and images are binary: commit before destructive edits; history is the only recovery.
