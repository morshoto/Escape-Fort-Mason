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

## Dots companion verification

| Check | Result | Evidence |
| --- | --- | --- |
| Dots scene and visual | PASS | `player/dots/dots.tscn` loads in Godot 4.7.2 Editor import; the Alfred visual contract covers the custom yellow body, round black glasses, simple eyes, bow tie, and no collision. |
| Four Dots variants | PASS | `tests/test_dots_variants.gd` loads Alfred, Blue, Green, and Pink, checks each visual root and defining geometry, and verifies all remain visual-only. |
| Dots Gallery | PASS | `player/dots/dots_gallery.tscn` instantiates the four variants side by side with a dedicated review camera and labels. |
| Variant visual evidence | PASS | `docs/dots-screenshots/` contains front, 45-degree, and side captures for Blue, Green, Alfred, and Pink, plus `dots-gallery.png`. |
| Player-relative spawn | PASS | `level/fort_mason.tscn` instantiates `Dots` beside `Sam` with `target_path = NodePath("../Sam")`; the exported right/above/rear offset is relative to Sam. |
| Follow, turn, and bob behavior | PASS | Headless `tests/test_dots_companion.gd` covers rotated offsets, smooth convergence, idle bobbing, and idle/walk/run thresholds. |
| Non-blocking companion | PASS | The visual scene contains no `CollisionShape3D` or physics body, so it cannot block Sam. |
| Chromium Web gameplay | PASS | The exported Compatibility build rendered Alfred beside Sam in Chromium; synthetic `W` input moved the player while Dots remained visible and followed. |
| Capture reproducibility | PASS | `tools/capture_dots_visuals.gd` regenerates all variant views, the four-Dot gallery, and the Sam-plus-Dots gameplay capture through a 640x640 Compatibility `SubViewport`. |
| Native headed Editor playtest | PENDING | Headless Editor import and runtime passed; a headed native Godot playtest was not available in this session. |

## Commands

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script tests/player_skin_contract_test.gd
godot --headless --path . --script tests/test_dots_companion.gd
godot --headless --path . --script tests/test_fort_mason_stage.gd
godot --headless --path . --export-release Web /tmp/escape-fort-mason-web/index.html
godot --path .
```

The sample’s source code and assets remain covered by the upstream `LICENSE`.

## MVP end-to-end QA — 2026-10-18

Target: [GitHub Pages](https://morshoto.github.io/Escape-Fort-Mason/), Chromium
on macOS, Godot 4.7.2 Compatibility export. After PR #17 merged as
`92656fb`, the public page deployed and rendered Fort Mason, Sam, Alfred Dots,
and the Japanese greeting. The existing Dots visual evidence is in
`docs/dots-screenshots/`.

| Check | Result | Evidence / limit |
| --- | --- | --- |
| Public Pages entry point and WASM/PCK/JS assets | PASS | Chromium rendered the published scene. `bash tools/smoke_web_assets.sh` checks the four same-origin assets over HTTPS. Pages workflow run [39082678298](https://github.com/morshoto/Escape-Fort-Mason/actions/runs/39082678298) completed successfully. |
| Godot import and gameplay contracts | PASS | Godot 4.7.2 headless import; player skin, Dots follow, dialogue, variants, Fort Mason stage, and Decisions client tests all passed on PR #17 head `1d8dc8c`. |
| Production Worker and CORS | PASS (HTTPS) | The production OPTIONS preflight returned HTTP 204 with `Access-Control-Allow-Origin: https://morshoto.github.io`. A synthetic HTTPS POST returned HTTP 200 with `source: "openai"` and an allowlisted choice. |
| API error and missing-endpoint fallback | PASS (contract) | Decisions client tests cover timeout, network/HTTP errors, malformed or unapproved responses, and an unset endpoint. These are not a public Worker test. |
| Secret exclusion from Web export | PASS | The final export was checked against the configured local key and `.dev.vars` path; neither was present. `.dev.vars` was removed after testing and was never committed. |
| Public Pages → production Worker → OpenAI | PASS (Chromium) | On the deployed public page, pressing `R` changed Dots’ line to `Fort Masonの景色を一緒に見よう。`; a concurrent Wrangler tail recorded `POST https://escape-fort-mason-decisions.escape-fort-mason.workers.dev/api/decision - Ok`. The Worker uses the rotated `OPENAI_API_KEY` stored as a Cloudflare secret; its value was not included in browser or repository output. |

Overall result: **PASS** for the public Web MVP path. Public rendering, the Pages-origin API interaction, and the production OpenAI-backed response are verified. Native headed Editor interaction and controller input were not part of this Web acceptance and remain unverified.

Recheck published static assets with:

```sh
bash tools/smoke_web_assets.sh
```

## Phase 1 and Phase 2 gameplay polish — 2026-10-18

Environment: macOS 26.5.1 on Apple M4 Pro, Godot 4.7.2, Compatibility
renderer, and Chromium WebGL2. The Web build was served from
`http://127.0.0.1:8765/` after exporting to
`/tmp/escape-fort-mason-gameplay-polish-web/index.html`.

### Changes and test-first evidence

The branch adds regression coverage and tuning for character scale, movement
and jumping, third-person camera follow and collision, bounded Japanese
dialogue, Dots interaction, and nighttime stage readability. For each area,
the `test(...)` commit precedes its implementation commit. The interaction
placement test first failed on the old prompt placement (`y=-1.9` pixels and
only `26.5` pixels to the right of Dots); after repositioning, it passed. The
final interaction test also verifies the prompt remains inside a 1280×720
viewport and beside Dots.

### Automated checks

| Check | Result | Evidence |
| --- | --- | --- |
| Godot editor import | PASS | `godot --headless --path . --editor --quit` completed. |
| Gameplay regression | PASS | All 11 Godot scripts passed: player skin, Dots companion, dialogue, variants, Fort Mason stage, Decisions client, interaction, lighting, scale, movement, and camera. |
| Movement consistency | PASS | The movement test measured 4.901 m / 4.858 m / 4.835 m over the same interval at 30 / 60 / 120 Hz. |
| Worker regression | PASS | `node --test backend/worker.test.mjs`: 8 tests passed. |
| Web export | PASS | `godot --headless --path . --export-release Web /tmp/escape-fort-mason-gameplay-polish-web/index.html` produced the HTML, JS, WASM, PCK, and support files. |
| Diff whitespace | PASS | `git diff --check` completed cleanly. |

### Visual review and browser interaction

Two review passes were completed. The composition pass compared the baseline
and updated outdoor, warehouse entrance, and interior views. The readability
pass checked Dots’ prompt and dialogue; it caught the prompt blending into the
warehouse edge at a wide viewport. The prompt was moved closer to Dots and
rechecked after rebuilding the export.

The final Web build was inspected at 1280×720, 1366×768, and 1920×1080. At all
three sizes, pressing `E` opened the Japanese local fallback dialogue, and the
dialogue remained in the viewport. Screenshots from the Godot Compatibility
renderer are stored in `docs/screenshots/gameplay-polish/after/`; baseline
views are in `docs/screenshots/gameplay-polish/before/`:

- [Sam and Dots](docs/screenshots/gameplay-polish/after/sam-and-dots.png)
- [Outdoor view](docs/screenshots/gameplay-polish/after/outdoor.png)
- [Warehouse entrance](docs/screenshots/gameplay-polish/after/warehouse-entrance.png)
- [Warehouse interior](docs/screenshots/gameplay-polish/after/warehouse-interior.png)
- [Interaction prompt](docs/screenshots/gameplay-polish/after/interaction-prompt.png)
- [Dialogue](docs/screenshots/gameplay-polish/after/dialogue.png)

The local server origin is intentionally rejected by the Decisions API CORS
policy: an OPTIONS request from `http://127.0.0.1:8765` returned HTTP 403
`origin_not_allowed`; the configured Pages origin returned HTTP 204. The
browser therefore showed the expected local fallback. The CUA browser wrapper
also reported `WrongDocumentError` when the game requested pointer lock, so
mouse-driven camera rotation was not reverified in this run.

### Native GUI limitation

Native Godot interactive QA remains pending. The Computer Use call for the
running Godot app returned `cgWindowNotFound`, and the available desktop capture
showed the macOS lock screen. The saved Godot-rendered screenshots and headless
scene tests verify rendering and runtime contracts, but they do not count as a
native interactive playtest. Browser `E` interaction was verified as described
above; full native keyboard, mouse, and controller playthrough remains
unverified.
