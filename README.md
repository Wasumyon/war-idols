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
| `car/` | **Godot 4.4 prototype** (the "slice"). |
| `war idol.clip`, `image-48.webp` | Raw art sources. |

## Running the prototype

1. Install **Godot 4.7.x** (standard build, no .NET needed).
2. Import `car/project.godot`.
3. Open `car/slice.tscn` and press **F6** (run current scene).

**Controls**

| Input | Action |
|---|---|
| A / D (or arrows) | Strafe one lane |
| W / S | Boost / slow |
| Space | Jump |
| Left Shift | Duck / take cover |
| Mouse | Aim the film reticle |
| R | Restart (after the run ends) |

**Notes**
- `.godot/` is git-ignored; Godot regenerates it the first time you open the project.
- The prototype is a **grey-box test build** — enemies and the environment use placeholder shapes.
- `car/test.tscn` is a driving sandbox and `car/test_static.tscn` is an asset-viewer rig; neither is the game.

## Git

- Repo: private, `Wasumyon/war-idols`.
- `.docx` and images are binary: commit before destructive edits; history is the only recovery.
