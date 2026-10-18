class_name GameProgress
extends Node

signal puzzle_completed(puzzle_id: StringName, completed_count: int)
signal exit_unlocked
signal chapter_changed(chapter_state: int)

enum ChapterState { EXPLORING, EXIT_OPEN, ENDING, COMPLETE }

const PUZZLE_COUNT := 3

var _completed_puzzles: Dictionary[StringName, bool] = {}
var _chapter_state: ChapterState = ChapterState.EXPLORING
var _exit_is_unlocked := false


func complete_puzzle(puzzle_id: StringName) -> bool:
	if not _is_valid_puzzle_id(puzzle_id) or _completed_puzzles.has(puzzle_id):
		return false

	_completed_puzzles[puzzle_id] = true
	puzzle_completed.emit(puzzle_id, get_completed_count())
	if are_all_puzzles_completed():
		_unlock_exit()
	return true


func get_completed_count() -> int:
	return _completed_puzzles.size()


func is_puzzle_completed(puzzle_id: StringName) -> bool:
	return _completed_puzzles.has(puzzle_id)


func are_all_puzzles_completed() -> bool:
	return get_completed_count() == PUZZLE_COUNT


func is_exit_unlocked() -> bool:
	return _exit_is_unlocked


func get_chapter_state() -> ChapterState:
	return _chapter_state


func transition_to_chapter(next_state: int) -> bool:
	var is_valid_transition := (
		(_chapter_state == ChapterState.EXIT_OPEN and next_state == ChapterState.ENDING)
		or (_chapter_state == ChapterState.ENDING and next_state == ChapterState.COMPLETE)
	)
	if not is_valid_transition:
		return false

	_set_chapter_state(next_state as ChapterState)
	return true


func reset_run() -> void:
	_completed_puzzles.clear()
	_exit_is_unlocked = false
	_set_chapter_state(ChapterState.EXPLORING)


func _unlock_exit() -> void:
	if _exit_is_unlocked:
		return

	_exit_is_unlocked = true
	_set_chapter_state(ChapterState.EXIT_OPEN)
	exit_unlocked.emit()


func _set_chapter_state(next_state: ChapterState) -> void:
	if _chapter_state == next_state:
		return

	_chapter_state = next_state
	chapter_changed.emit(_chapter_state)


func _is_valid_puzzle_id(puzzle_id: StringName) -> bool:
	return puzzle_id == &"logo" or puzzle_id == &"devday" or puzzle_id == &"archive"
