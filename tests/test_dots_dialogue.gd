extends SceneTree

const DIALOGUE_SCENE_PATH := "res://player/dots/dialogue_ui.tscn"
const DOTS_SCENE_PATH := "res://player/dots/dots.tscn"
const DEBUG_ACTION := "show_dots_dialogue"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_dialogue_scene_contract()
	await _test_dialogue_camera_side_offset()
	await _test_message_api_and_wrapping()
	await _test_debug_message_input()
	await _test_dialogue_safe_screen_margin()
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
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 0.0, 8.0)
	camera.current = true
	root.add_child(camera)
	await process_frame

	var message := dialogue.get_node_or_null("Message") as Label3D
	_assert(message != null, "Dialogue UI should expose a Label3D message")
	if message != null:
		_assert(message.font != null, "Dialogue message should use a bundled font")
		_assert(message.billboard == BaseMaterial3D.BILLBOARD_ENABLED, "Dialogue message should face the camera")
		_assert(message.fixed_size, "Dialogue message should stay readable at distance")
		_assert(message.outline_size > 0, "Dialogue message should have a readable outline")
		_assert(message.font_size <= 26, "Dialogue text should use a compact readable font size")

	var bubble_root := dialogue.get_node_or_null("Bubble") as Node3D
	var bubble := dialogue.get_node_or_null("Bubble/Panel") as MeshInstance3D
	_assert(bubble_root != null, "Dialogue UI should expose a speech bubble root")
	_assert(bubble != null, "Dialogue UI should include a speech bubble panel")
	_assert(not dialogue.visible, "Dialogue UI should start hidden until Dots speaks")
	if bubble != null:
		var anchor_height := float(dialogue.get("bubble_anchor_height"))
		_assert(is_equal_approx(bubble_root.position.y, anchor_height), "Speech bubble root should sit at its screen-clamped anchor")
		_assert(is_zero_approx(bubble.position.y), "Speech panel should scale around the bubble anchor")
		if message != null:
			_assert(is_equal_approx(message.position.y, anchor_height), "Dialogue text should align with the speech bubble root")
	if bubble != null:
		dialogue.call("show_message", "拡大縮小テスト")
		var material := bubble.material_override as StandardMaterial3D
		_assert(material != null, "Speech bubble should have a material")
		if material != null:
			_assert(material.billboard_mode == BaseMaterial3D.BILLBOARD_ENABLED, "Speech bubble should face the camera")
		var panel_mesh := bubble.mesh as QuadMesh
		_assert(panel_mesh != null, "Speech bubble panel should use a QuadMesh")
		if panel_mesh != null:
			_assert(panel_mesh.size.x <= 2.6 and panel_mesh.size.y <= 0.95, "Speech bubble panel should be compact")
		var horizontal_offset = dialogue.get("bubble_horizontal_offset")
		_assert(horizontal_offset != null and float(horizontal_offset) >= 1.6, "Dialogue should sit to the side of Dots")
		var anchor_height = dialogue.get("bubble_anchor_height")
		_assert(anchor_height != null and float(anchor_height) >= 2.8, "Dialogue should sit above the characters")
		var near_scale: float = bubble_root.scale.x
		camera.position.z = 16.0
		await process_frame
		_assert(bubble_root.scale.x > near_scale, "Speech bubble should scale for distant cameras")
		camera.position.z = 64.0
		await process_frame
		_assert(bubble_root.scale.x <= 1.25, "Speech bubble scale should stay bounded at long distances")
		dialogue.call("show_message", "")

	_assert(dialogue.call("get_message").is_empty(), "Dialogue UI should not show a greeting before interaction")
	dialogue.queue_free()
	camera.queue_free()
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

	var long_message := "これは日本語の長いテストメッセージです。Dotsが画面内で読みやすく表示されます。さらに続く文章も制限されます。"
	dialogue.call("show_message", long_message)
	var display_text := message.text
	_assert(display_text.contains("\n"), "Long Japanese messages should wrap")
	var max_line_characters := int(dialogue.get("max_line_characters"))
	var max_visible_lines = dialogue.get("max_visible_lines")
	var lines := display_text.split("\n")
	_assert(lines.size() <= 3, "Long dialogue should be limited to three visible lines")
	_assert(lines[lines.size() - 1].ends_with("…"), "Truncated dialogue should end with an ellipsis")
	for line in lines:
		_assert(line.length() <= max_line_characters, "Wrapped dialogue lines should stay within the limit")
	_assert(max_visible_lines == 3, "Dialogue should expose a three-line limit")

	dialogue.call("show_message", "")
	_assert(not dialogue.visible, "Empty dialogue should hide the bubble")
	dialogue.queue_free()
	await process_frame


func _test_dialogue_camera_side_offset() -> void:
	var anchor := Node3D.new()
	root.add_child(anchor)
	var dialogue_scene := load(DIALOGUE_SCENE_PATH) as PackedScene
	if dialogue_scene == null:
		return
	var dialogue := dialogue_scene.instantiate()
	anchor.add_child(dialogue)
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.position = Vector3(0.0, 3.0, 8.0)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	await process_frame
	dialogue.call("show_message", "画面中央のテスト")
	dialogue._process(1.0 / 60.0)
	var offset := float(dialogue.get("bubble_horizontal_offset"))
	var height := float(dialogue.get("bubble_anchor_height"))
	var expected_anchor := anchor.global_position + camera.global_basis.x * offset + Vector3(0.0, height, 0.0)
	var bubble_root := dialogue.get_node("Bubble") as Node3D
	_assert(
		camera.unproject_position(bubble_root.global_position).distance_to(camera.unproject_position(expected_anchor)) <= 1.0,
		"Speech bubble should render at its camera-side offset when the anchor is inside the safe area"
	)
	anchor.queue_free()
	camera.queue_free()
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
	event.physical_keycode = KEY_T
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


func _test_dialogue_safe_screen_margin() -> void:
	var scene := load(DIALOGUE_SCENE_PATH) as PackedScene
	if scene == null:
		return
	var anchor := Node3D.new()
	anchor.position = Vector3(80.0, 0.0, 0.0)
	root.add_child(anchor)
	var dialogue := scene.instantiate()
	anchor.add_child(dialogue)
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.position = Vector3(0.0, 3.0, 8.0)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	await process_frame
	dialogue.call("show_message", "画面端のテスト")
	dialogue._process(1.0 / 60.0)
	var horizontal_offset_value := 0.0
	var horizontal_offset = dialogue.get("bubble_horizontal_offset")
	if horizontal_offset != null:
		horizontal_offset_value = horizontal_offset
	var bubble_anchor_height := 0.0
	var configured_anchor_height = dialogue.get("bubble_anchor_height")
	if configured_anchor_height != null:
		bubble_anchor_height = configured_anchor_height
	var bubble_anchor: Vector3 = dialogue.global_position + camera.global_basis.x * horizontal_offset_value + Vector3(0.0, bubble_anchor_height, 0.0)
	var screen_position := camera.unproject_position(bubble_anchor)
	var viewport_size := get_root().get_visible_rect().size
	_assert(screen_position.x >= viewport_size.x * 0.08, "Dialogue should stay inside the left screen margin")
	_assert(screen_position.x <= viewport_size.x * 0.92 + 2.0, "Dialogue should stay inside the right screen margin")
	_assert(screen_position.y >= viewport_size.y * 0.1, "Dialogue should stay inside the top screen margin")
	_assert(screen_position.y <= viewport_size.y * 0.9, "Dialogue should stay inside the bottom screen margin")
	var panel := dialogue.get_node("Bubble/Panel") as MeshInstance3D
	var panel_mesh := panel.mesh as QuadMesh
	var half_panel_width: float = panel_mesh.size.x * dialogue.get_node("Bubble").scale.x * 0.5
	var left_edge := camera.unproject_position(bubble_anchor - camera.global_basis.x * half_panel_width)
	var right_edge := camera.unproject_position(bubble_anchor + camera.global_basis.x * half_panel_width)
	var half_panel_height: float = panel_mesh.size.y * dialogue.get_node("Bubble").scale.y * 0.5
	var top_edge := camera.unproject_position(bubble_anchor + camera.global_basis.y * half_panel_height)
	var bottom_edge := camera.unproject_position(bubble_anchor - camera.global_basis.y * half_panel_height)
	_assert(left_edge.x >= viewport_size.x * 0.04, "Speech bubble panel should stay inside the left screen margin")
	_assert(right_edge.x <= viewport_size.x * 0.96, "Speech bubble panel should stay inside the right screen margin")
	_assert(top_edge.y >= viewport_size.y * 0.04, "Speech bubble panel should stay inside the top screen margin")
	_assert(bottom_edge.y <= viewport_size.y * 0.96, "Speech bubble panel should stay inside the bottom screen margin")
	anchor.queue_free()
	camera.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
