# Third-person controller verification

Environment: macOS 26.5.1, Apple Silicon (`arm64`), Godot 4.7.2, local
Compatibility renderer, and a local Chromium WebGL2 run.

| Check | Result | Evidence |
| --- | --- | --- |
| WASD movement | PASS (contract/main-scene smoke) | The Sam skin contract test passes, the full main scene launches headlessly, and the exported Chromium build accepts `W` input without runtime errors. The player movement script and collision body are unchanged. |
| Third-person mouse camera | PASS (Chromium Web) | A real pointer drag in the locally served Chromium Web build changed the rendered third-person view. `player/camera_controller.gd` still handles captured `InputEventMouseMotion`. |
| Idle / Walk / Run animation | PASS (contract + retarget) | The loaded Sam `AnimationTree` exposes `idle`, `walk`, and `run`; the visible Humanoid `Skeleton3D` receives state-driven arm and leg poses, while dedicated retarget preview clips target the same bone paths. Jump, fall, and attack clips are also present. |
| Wall / ground collision | PASS (unchanged contract) | The full main scene launches with the existing capsule collision, shape cast, terrain physics, camera, and weapon hierarchy unchanged. |
| Replaceable 3D model | PASS (headless contract) | `player/player.tscn` uses `player/sam/sam_skin.tscn`; the contract test loads the skin, checks `CharacterSkin` methods, verifies the animation library, and enters the Move state. |
| Sam-inspired visual and provenance | PASS (code/assets) | The skin has parted hair, a fitted jacket shell/front panel mesh, muted-blue top material, and charcoal trousers. `docs/ASSETS.md` records Quaternius provenance, licensing, and the retained GDbot rollback path. |
| Godot 4.7.2 Editor | PASS (import/headless) | `godot --headless --path . --editor --quit` completed with no parse or load errors. A headed Compatibility launch also started with the expected OpenGL/Metal renderer; native headed interaction was not separately captured. |
| Web (Compatibility) | PASS (Chromium) | The Web preset exported successfully; the generated WASM/PCK package loaded through a local HTTP server, entered the playable scene, rendered the Sam skin, accepted keyboard input, and responded to a camera drag. |

## Commands

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script tests/player_skin_contract_test.gd
godot --headless --path . --export-release Web /tmp/escape-fort-mason-web/index.html
godot --path .
```

The sample’s source code and assets remain covered by the upstream `LICENSE`.
