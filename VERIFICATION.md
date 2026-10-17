# Third-person controller verification

Environment: macOS 26.5.1, Apple Silicon (`arm64`), Godot 4.7.2, local
Compatibility renderer, and a local Chromium WebGL2 run.

| Check | Result | Evidence |
| --- | --- | --- |
| WASD movement | PASS | Synthetic `W` input moved the player from `(-3.298, 0.5, -13.017)` to approximately `(-3.298, 0.501, -9.983)` in the loaded main scene. |
| Third-person mouse camera | PASS (Web) / native desktop pending | A real pointer drag in the locally served Chromium Web build changed the rendered third-person view. `player/camera_controller.gd` handles captured `InputEventMouseMotion`; native headed Godot could not be launched because the macOS session was locked. |
| Idle / Walk / Run animation | PASS | The loaded `AnimationTree` reached `Idle` after releasing movement and `Move` during movement; the walk/run blend parameter changed. The `walk`, `run`, and `idle` clips are defined in `player/gdbot/gdbot_skin.tscn`. |
| Wall / ground collision | PASS | `is_on_floor()` was true in the main scene, and `CharacterBody3D.test_move()` detected the nearby level boxes. The player scene contains a capsule collision shape and the terrain importer generates physics. |
| Replaceable 3D model | PASS (headless contract) | `player/player.tscn` uses `player/sam/sam_skin.tscn`; the contract test loads the skin, checks `CharacterSkin` methods, verifies the animation library, and enters the Move state. |
| Sam-inspired visual and provenance | PASS (code/assets) | The skin has explicit hair, glasses, hoodie, pants, and shoe nodes. `docs/ASSETS.md` records local authorship, primitive-mesh provenance, licensing, and the retained GDbot rollback path. |
| Web (Compatibility) | PASS | The Web preset exported successfully; the generated WASM/PCK package loaded through a local HTTP server and rendered the demo menu in Chromium. |

## Commands

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script tests/player_skin_contract_test.gd
godot --headless --path . --export-release Web /tmp/escape-fort-mason-web/index.html
godot --path .
```

The sample’s source code and assets remain covered by the upstream `LICENSE`.
