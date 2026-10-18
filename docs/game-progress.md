# Game progress contract

`FortMason` owns one `GameProgress` node at
`/root/FortMason/GameProgress`. The node is created with
`level/fort_mason.tscn`, so a fresh scene instance starts a fresh run. Progress
is in memory for the current scene only; save data is not part of the MVP.

Puzzle implementations report a success only after Godot has checked the
answer:

```gdscript
@onready var game_progress: GameProgress = get_node("/root/FortMason/GameProgress")

func _on_logo_solved() -> void:
	if game_progress.complete_puzzle(&"logo"):
		show_completion_feedback()
```

The only accepted IDs are `logo`, `devday`, and `archive`. The first call for a
valid ID returns `true` and emits `puzzle_completed(puzzle_id, completed_count)`.
Repeated calls and unknown IDs return `false` without changing state or
emitting a completion event. `DotsDecisionClient` and other network responses
do not call this API or decide whether a puzzle is solved.

## Read API and signals

- `get_completed_count()` returns the number of unique completed puzzles.
- `is_puzzle_completed(id)` checks one allowlisted puzzle.
- `are_all_puzzles_completed()` and `is_exit_unlocked()` report the run gates.
- `puzzle_completed(puzzle_id, completed_count)` fires once for each new valid
  completion, in solve order.
- `exit_unlocked` fires once when the third distinct puzzle completes.
- `chapter_changed(chapter_state)` fires when the chapter state changes.

The chapter state begins at `EXPLORING`. The third puzzle moves it to
`EXIT_OPEN` and unlocks the exit. Finale code may call
`transition_to_chapter(GameProgress.ChapterState.ENDING)`, followed by
`transition_to_chapter(GameProgress.ChapterState.COMPLETE)`. Skips, repeats,
backward transitions, and unknown values are rejected. `reset_run()` clears all
puzzle flags, relocks the exit, and returns the chapter to `EXPLORING`; a later
completion can emit a new exit event for the new run.

## Lifecycle for listeners

UI, door, and foreshadow nodes can resolve the sibling with
`get_node("/root/FortMason/GameProgress")` while this scene is active, then
connect to its signals during their `_ready()` lifecycle. They should read the
current state after connecting so they also handle a listener added after a
completion. Puzzle scripts should call `complete_puzzle()` only from their
validated success path. Restarting `level/fort_mason.tscn` creates a new node
and resets progress without a global singleton or network dependency.
