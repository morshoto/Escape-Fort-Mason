# Godot tests

The project tests are headless GDScript programs that extend `SceneTree`. Each
test owns its setup and exits with code `0` for success or `1` for failure.

Run the complete suite locally with:

```sh
bash tests/run-tests.sh
```

The runner discovers files named `tests/test_*.gd` in sorted order. Keep new
behavior tests in that directory, write the failing contract before the
implementation, and run the suite locally before opening a pull request.

These are project tests, not Godot Engine C++ tests. The Godot 4.4 engine
documentation's `scons tests=yes` and `--test` commands apply to building the
engine itself; this repository uses the headless GDScript entry point instead.
