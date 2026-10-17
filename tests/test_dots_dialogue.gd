extends SceneTree

const DIALOGUE_SCENE_PATH := "res://player/dots/dialogue_ui.tscn"
const DOTS_SCENE_PATH := "res://player/dots/dots.tscn"
const DEBUG_ACTION := "show_dots_dialogue"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_dialogue_scene_contract()
	await _test_message_api_and_wrapping()
	await _test_debug_message_input()
	await _test_dots_forwards_dialogue_messages()

	if _failures.is_empty():
		print("Dots dialogue tests passed")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)


func _test_dialogue_scene_contract() -> void:
	var scene := load(DIALOGUE_SCENE_PATH) as PackedScene
	_assert(scene != null, "Dialogue UI scene should be loadable")
	if scene == null:
		return

	var dialogue := scene.instantiate()
	root.add_child(dialogue)
	await process_frame

	var message := dialogue.get_node_or_null("Message") as Label3D
	_assert(message != null, "Dialogue UI should expose a Label3D message")
	if message != null:
		_assert(message.font != null, "Dialogue message should use a bundled font")
		_assert(message.billboard == BaseMaterial3D.BILLBOARD_ENABLED, "Dialogue message should face the camera")
		_assert(message.fixed_size, "Dialogue message should stay readable at distance")
		_assert(message.outline_size > 0, "Dialogue message should have a readable outline")

	var bubble := dialogue.get_node_or_null("Bubble/Panel") as MeshInstance3D
	_assert(bubble != null, "Dialogue UI should include a speech bubble panel")
	if bubble != null:
		var material := bubble.material_override as StandardMaterial3D
		_assert(material != null, "Speech bubble should have a material")
		if material != null:
			_assert(material.billboard_mode == BaseMaterial3D.BILLBOARD_ENABLED, "Speech bubble should face the camera")

	_assert(dialogue.call("get_message") == "こんにちは、Sam！", "Dialogue UI should show the sample greeting")
	dialogue.queue_free()
	await process_frame


func _test_message_api_and_wrapping() -> void:
	var scene := load(DIALOGUE_SCENE_PATH) as PackedScene
	if scene == null:
		return
	var dialogue := scene.instantiate()
	root.add_child(dialogue)
	await process_frame

	_assert(dialogue.has_method("show_message"), "Dialogue UI should expose show_message")
	dialogue.call("show_message", "調査を始めよう。")
	_assert(dialogue.call("get_message") == "調査を始めよう。", "show_message should replace the current text")
	var message := dialogue.get_node("Message") as Label3D
	_assert(message.text == "調査を始めよう。", "Label3D should receive the updated text")

	var long_message := "これは日本語の長いテストメッセージです。Dotsが画面内で読みやすく表示されます。"
	dialogue.call("show_message", long_message)
	var display_text := message.text
	_assert(display_text.contains("\n"), "Long Japanese messages should wrap")
	var max_line_characters := int(dialogue.get("max_line_characters"))
	for line in display_text.split("\n"):
		_assert(line.length() <= max_line_characters, "Wrapped dialogue lines should stay within the limit")

	dialogue.call("show_message", "")
	_assert(not dialogue.visible, "Empty dialogue should hide the bubble")
	dialogue.queue_free()
	await process_frame


func _test_debug_message_input() -> void:
	_assert(InputMap.has_action(DEBUG_ACTION), "Dialogue debug input action should exist")
	var scene := load(DIALOGUE_SCENE_PATH) as PackedScene
	if scene == null:
		return
	var dialogue := scene.instantiate()
	root.add_child(dialogue)
	await process_frame

	dialogue.call("show_message", "別のセリフ")
	var event := InputEventKey.new()
	event.keycode = KEY_T
	event.pressed = true
	dialogue._unhandled_input(event)
	_assert(dialogue.call("get_message") == "こんにちは、Sam！", "T should restore the debug greeting")
	dialogue.queue_free()
	await process_frame


func _test_dots_forwards_dialogue_messages() -> void:
	var scene := load(DOTS_SCENE_PATH) as PackedScene
	_assert(scene != null, "Dots scene should be loadable with dialogue")
	if scene == null:
		return
	var dots := scene.instantiate()
	root.add_child(dots)
	await process_frame

	var dialogue := dots.get_node_or_null("DialogueUI")
	_assert(dialogue != null, "Dots should own a DialogueUI child")
	_assert(dots.has_method("show_message"), "Dots should forward show_message")
	if dialogue != null and dots.has_method("show_message"):
		dots.show_message("Dotsからの返事")
		_assert(dialogue.call("get_message") == "Dotsからの返事", "Dots should update its dialogue bubble")
	dots.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
