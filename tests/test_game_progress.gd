extends SceneTree

const GAME_PROGRESS_PATH := "res://gameplay/game_progress.gd"
const STAGE_PATH := "res://level/fort_mason.tscn"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_progress_script := load(GAME_PROGRESS_PATH) as GDScript
	_check(game_progress_script != null, "GameProgress script should be loadable")
	if game_progress_script == null:
		_finish()
		return

	var chapter_states: Dictionary = game_progress_script.get_script_constant_map().get("ChapterState", {})
	_check(
		chapter_states.has_all(["EXPLORING", "EXIT_OPEN", "ENDING", "COMPLETE"]),
		"GameProgress should expose the ordered chapter states",
	)
	if not chapter_states.has_all(["EXPLORING", "EXIT_OPEN", "ENDING", "COMPLETE"]):
		_finish()
		return

	var progress = game_progress_script.new()
	root.add_child(progress)
	await process_frame
	await _test_initial_state(progress, chapter_states)
	var events := await _test_puzzles_in_any_order(progress, chapter_states)
	_test_reset_and_replay(progress, chapter_states, events)
	await _test_all_solve_orders(game_progress_script)
	await _test_scene_ownership_and_restart(game_progress_script, chapter_states)
	progress.queue_free()
	await process_frame
	_finish()


func _test_initial_state(progress: Object, chapter_states: Dictionary) -> void:
	_check(progress.get_completed_count() == 0, "A new run should have zero completed puzzles")
	_check(not progress.is_puzzle_completed("logo"), "Logo should start incomplete")
	_check(not progress.is_puzzle_completed("devday"), "DevDay should start incomplete")
	_check(not progress.is_puzzle_completed("archive"), "Archive should start incomplete")
	_check(not progress.are_all_puzzles_completed(), "A new run should not be complete")
	_check(not progress.is_exit_unlocked(), "The exit should start locked")
	_check(
		progress.get_chapter_state() == chapter_states["EXPLORING"],
		"A new run should start in the exploring chapter",
	)
	_check(
		not progress.transition_to_chapter(chapter_states["ENDING"]),
		"The ending should not be reachable before the exit opens",
	)
	_check(
		not progress.transition_to_chapter(999),
		"Unknown chapter states should be rejected",
	)


func _test_puzzles_in_any_order(progress: Object, chapter_states: Dictionary) -> Dictionary:
	var puzzle_events: Array[Dictionary] = []
	var exit_events: Array[bool] = []
	progress.puzzle_completed.connect(
		func(puzzle_id: StringName, completed_count: int) -> void:
			puzzle_events.append({"id": String(puzzle_id), "count": completed_count})
	)
	progress.exit_unlocked.connect(func() -> void: exit_events.append(true))

	_check(not progress.complete_puzzle("logo_started"), "An in-progress puzzle callback should be rejected")
	_check(not progress.complete_puzzle("unknown"), "An unknown puzzle ID should be rejected")
	_check(progress.get_completed_count() == 0, "Rejected IDs should not change progress")
	_check(not progress.is_puzzle_completed("unknown"), "Unknown IDs should never be reported complete")

	_check(progress.complete_puzzle("archive"), "Archive should complete first")
	_check(not progress.complete_puzzle("archive"), "Completing Archive twice should be ignored")
	_check(progress.complete_puzzle("logo"), "Logo should complete second")
	_check(progress.complete_puzzle("devday"), "DevDay should complete third")
	_check(not progress.complete_puzzle("devday"), "Completing after all puzzles should be ignored")

	_check(progress.is_puzzle_completed("archive"), "Archive should be recorded complete")
	_check(progress.is_puzzle_completed("logo"), "Logo should be recorded complete")
	_check(progress.is_puzzle_completed("devday"), "DevDay should be recorded complete")
	_check(progress.get_completed_count() == 3, "All three puzzles should be counted")
	_check(progress.are_all_puzzles_completed(), "All three puzzles should report complete")
	_check(progress.is_exit_unlocked(), "The exit should unlock after all puzzles")
	_check(
		progress.get_chapter_state() == chapter_states["EXIT_OPEN"],
		"The final puzzle should move the chapter to exit open",
	)
	_check(puzzle_events.size() == 3, "Each unique puzzle should emit one completion event")
	_check(
		puzzle_events.map(func(event: Dictionary) -> int: return event["count"]) == [1, 2, 3],
		"Completion events should report increasing counts",
	)
	_check(
		puzzle_events.map(func(event: Dictionary) -> String: return event["id"])
		== ["archive", "logo", "devday"],
		"Completion events should preserve solve order",
	)
	_check(exit_events.size() == 1, "The exit should emit one unlock event per run")
	_check(not progress.transition_to_chapter(chapter_states["COMPLETE"]), "The ending should not be skippable")
	_check(not progress.transition_to_chapter(999), "Unknown chapter states should remain rejected")
	_check(progress.transition_to_chapter(chapter_states["ENDING"]), "The exit-open chapter should enter the ending")
	_check(
		progress.get_chapter_state() == chapter_states["ENDING"],
		"A valid transition should update the chapter state",
	)
	_check(not progress.transition_to_chapter(chapter_states["ENDING"]), "Repeated chapter transitions should be rejected")
	_check(progress.transition_to_chapter(chapter_states["COMPLETE"]), "The ending should complete")
	_check(not progress.transition_to_chapter(chapter_states["ENDING"]), "Completed runs should not move backwards")
	return {"puzzles": puzzle_events, "exits": exit_events}


func _test_reset_and_replay(progress: Object, chapter_states: Dictionary, events: Dictionary) -> void:
	progress.reset_run()
	_check(progress.get_completed_count() == 0, "Reset should clear completed puzzle count")
	_check(not progress.is_puzzle_completed("archive"), "Reset should clear puzzle flags")
	_check(not progress.are_all_puzzles_completed(), "Reset should clear the complete state")
	_check(not progress.is_exit_unlocked(), "Reset should relock the exit")
	_check(
		progress.get_chapter_state() == chapter_states["EXPLORING"],
		"Reset should return to exploring",
	)

	_check(progress.complete_puzzle("devday"), "A puzzle should be solvable after reset")
	_check(progress.complete_puzzle("archive"), "A reset run should allow any solve order")
	_check(progress.complete_puzzle("logo"), "The last reset puzzle should complete")
	_check(progress.get_completed_count() == 3, "A replay should count all puzzles")
	_check(progress.is_exit_unlocked(), "A replay should unlock the exit again")
	_check(events["puzzles"].size() == 6, "Replay should emit one event per puzzle")
	_check(events["exits"].size() == 2, "Replay should emit one new exit event")


func _test_all_solve_orders(game_progress_script: GDScript) -> void:
	var solve_orders: Array[Array] = [
		[&"logo", &"devday", &"archive"],
		[&"logo", &"archive", &"devday"],
		[&"devday", &"logo", &"archive"],
		[&"devday", &"archive", &"logo"],
		[&"archive", &"logo", &"devday"],
		[&"archive", &"devday", &"logo"],
	]
	for solve_order in solve_orders:
		var progress = game_progress_script.new()
		root.add_child(progress)
		await process_frame
		var puzzle_events: Array[StringName] = []
		var exit_events: Array[bool] = []
		progress.puzzle_completed.connect(
			func(puzzle_id: StringName, _completed_count: int) -> void: puzzle_events.append(puzzle_id)
		)
		progress.exit_unlocked.connect(func() -> void: exit_events.append(true))

		for index in range(solve_order.size()):
			_check(progress.complete_puzzle(solve_order[index]), "Each solve order should accept every puzzle")
			_check(
				progress.is_exit_unlocked() == (index == solve_order.size() - 1),
				"Each solve order should unlock only on its last puzzle",
			)
		_check(puzzle_events == solve_order, "Completion events should preserve each solve order")
		_check(exit_events.size() == 1, "Each solve order should unlock exactly once")
		_check(not progress.complete_puzzle(solve_order[0]), "Duplicate solves should not unlock again")
		_check(exit_events.size() == 1, "A duplicate solve should not emit another unlock")
		progress.queue_free()
		await process_frame


func _test_scene_ownership_and_restart(game_progress_script: GDScript, chapter_states: Dictionary) -> void:
	var stage_scene := load(STAGE_PATH) as PackedScene
	_check(stage_scene != null, "The Fort Mason scene should load")
	if stage_scene == null:
		return

	var first_stage := stage_scene.instantiate() as Node3D
	root.add_child(first_stage)
	await process_frame
	await process_frame
	var first_progress := first_stage.get_node_or_null("GameProgress")
	_check(first_progress != null, "GameProgress should be owned by Fort Mason")
	_check(first_progress != null and first_progress.get_script() == game_progress_script, "Fort Mason should use GameProgress")
	_check(first_stage.get_node_or_null("Sam") is CharacterBody3D, "Sam should remain in the Fort Mason scene")
	_check(first_stage.get_node_or_null("Dots") is Node3D, "Dots should remain in the Fort Mason scene")
	if first_progress != null:
		_check(first_progress.get_completed_count() == 0, "A newly loaded scene should start a fresh run")
		_check(not first_progress.is_exit_unlocked(), "A newly loaded scene should keep the exit locked")
		_check(
			first_progress.get_chapter_state() == chapter_states["EXPLORING"],
			"A newly loaded scene should start in exploring",
		)
	first_stage.queue_free()
	await process_frame

	var restarted_stage := stage_scene.instantiate() as Node3D
	root.add_child(restarted_stage)
	await process_frame
	await process_frame
	var restarted_progress := restarted_stage.get_node_or_null("GameProgress")
	_check(restarted_progress != null, "Restart should recreate GameProgress")
	if restarted_progress != null:
		_check(restarted_progress.get_completed_count() == 0, "Restart should not preserve puzzle progress")
		_check(not restarted_progress.is_exit_unlocked(), "Restart should relock the exit")
		_check(
			restarted_progress.get_chapter_state() == chapter_states["EXPLORING"],
			"Restart should reset the chapter",
		)
	restarted_stage.queue_free()
	await process_frame


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
		push_error(description)


func _finish() -> void:
	if _failures.is_empty():
		print("GameProgress tests passed")
		quit(0)
		return
	printerr("GameProgress tests failed: ", _failures.size())
	quit(1)
