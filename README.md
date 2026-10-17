# Escape-Fort-Mason

This repository currently contains a locally verified baseline from GDQuest's
Godot 4 third-person controller demo:

<https://github.com/gdquest-demos/godot-4-3d-third-person-controller>

## Run locally

```sh
godot --path .
```

Controls are configured in `project.godot`: WASD moves, Space jumps, the mouse
aims/attacks, Tab swaps weapons, and Escape pauses.

The imported baseline was tested with Godot 4.7.2 using both editor/import
initialization and a headless main-scene launch. See `LICENSE` for the source
and art licensing terms from the upstream project. This local copy selects
Godot's compatibility renderer for Apple Silicon/macOS because the upstream
project has an open Mac/Vulkan compatibility report.

See [VERIFICATION.md](VERIFICATION.md) for the six-item local check list and
its evidence.

## GitHub Pages deployment

Every push to `main`, including pull request merges, exports the `Web` preset
and deploys the result to GitHub Pages:

<https://morshoto.github.io/Escape-Fort-Mason/>

The repository's Pages source must be set to **GitHub Actions** once in
**Settings → Pages**. The workflow can also be started manually from the
Actions tab. GitHub Pages must be available for the repository's visibility and
plan; the current private-repository plan rejected the initial Pages setup.

The current player visual is the locally authored Sam-inspired skin described
in [docs/ASSETS.md](docs/ASSETS.md). The original GDbot skin remains available
as a rollback/reference implementation.
