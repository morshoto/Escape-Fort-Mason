extends SceneTree

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var packed_scene := load("res://level/fort_mason.tscn") as PackedScene
	_assert(packed_scene != null, "Fort Mason should load for control hint checks")
	if packed_scene == null:
		_finish()
		return

	var stage := packed_scene.instantiate()
	root.add_child(stage)
	await process_frame
	var controls_hint := stage.get_node_or_null("ControlsHint") as CanvasLayer
	_assert(controls_hint != null, "Fort Mason should show a control hint on its opening screen")
	if controls_hint != null:
		var instructions := controls_hint.get_node_or_null("Panel/Instructions") as Label
		_assert(instructions != null, "The control hint should include readable instructions")
		if instructions != null:
			_assert(instructions.visible, "Control instructions should be visible when gameplay starts")
			_assert(instructions.text.contains("WASD"), "Control instructions should explain movement")
			_assert(instructions.text.contains("Space"), "Control instructions should explain jumping")
			_assert(instructions.text.contains("Mouse"), "Control instructions should explain camera movement")
	stage.queue_free()
	await process_frame
	_finish()


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("Control hint tests passed")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
