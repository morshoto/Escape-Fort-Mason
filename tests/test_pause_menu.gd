extends SceneTree

const STAGE_PATH := "res://level/fort_mason.tscn"
const RESUME_BUTTON_PATH := "Overlay/Panel/MarginContainer/Content/ResumeButton"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage_scene := load(STAGE_PATH) as PackedScene
	_assert(stage_scene != null, "Fort Mason scene should load")
	if stage_scene == null:
		_finish()
		return

	var stage := stage_scene.instantiate() as Node3D
	root.add_child(stage)
	await process_frame
	var pause_menu := stage.get_node_or_null("PauseMenu") as CanvasLayer
	_assert(pause_menu != null, "Fort Mason should include a pause menu")
	if pause_menu == null:
		stage.queue_free()
		_finish()
		return

	_assert(not paused, "Gameplay should start unpaused")
	_assert(not pause_menu.get_node("Overlay").visible, "Pause overlay should start hidden")

	await _press_escape()
	_assert(paused, "Escape should pause gameplay")
	_assert(pause_menu.get_node("Overlay").visible, "Escape should show the pause overlay")

	await _press_escape()
	_assert(not paused, "Escape should resume gameplay")
	_assert(not pause_menu.get_node("Overlay").visible, "Resume should hide the pause overlay")

	await _press_escape()
	var resume_button := pause_menu.get_node(RESUME_BUTTON_PATH) as Button
	_assert(resume_button != null, "Pause overlay should provide a Resume button")
	if resume_button != null:
		resume_button.pressed.emit()
		await process_frame
		_assert(not paused, "Resume button should resume gameplay")
		_assert(not pause_menu.get_node("Overlay").visible, "Resume button should hide the pause overlay")

	stage.queue_free()
	await process_frame
	_finish()


func _press_escape() -> void:
	var key_event := InputEventKey.new()
	key_event.keycode = KEY_ESCAPE
	key_event.physical_keycode = KEY_ESCAPE
	key_event.pressed = true
	Input.parse_input_event(key_event)
	await process_frame

	key_event = key_event.duplicate() as InputEventKey
	key_event.pressed = false
	Input.parse_input_event(key_event)
	await process_frame


func _assert(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)


func _finish() -> void:
	if _failures.is_empty():
		print("Pause menu tests passed")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
