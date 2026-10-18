extends SceneTree

const DOTS_SCENE_PATH := "res://player/dots/dots.tscn"
const INTERACT_ACTION := "interact"

var _failures: Array[String] = []
var _saved_endpoint := ""


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_saved_endpoint = ProjectSettings.get_setting("escape_fort_mason/decisions_endpoint", "")
	ProjectSettings.set_setting("escape_fort_mason/decisions_endpoint", "")
	_test_interact_action_bindings()
	await _test_prompt_tracks_range()
	await _test_interaction_uses_decisions_client_and_cooldown()
	await _test_busy_client_and_dialogue_prompt_visibility()
	await _test_e_input_starts_interaction()
	ProjectSettings.set_setting("escape_fort_mason/decisions_endpoint", _saved_endpoint)

	if _failures.is_empty():
		print("Dots interaction tests passed")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)


func _test_interact_action_bindings() -> void:
	_assert(InputMap.has_action(INTERACT_ACTION), "Interaction should have an input action")
	if not InputMap.has_action(INTERACT_ACTION):
		return
	var has_keyboard := false
	var has_controller := false
	for event in InputMap.action_get_events(INTERACT_ACTION):
		if event is InputEventKey and event.physical_keycode == KEY_E:
			has_keyboard = true
		if event is InputEventJoypadButton and event.button_index == JOY_BUTTON_X:
			has_controller = true
	_assert(has_keyboard, "E should trigger companion interaction")
	_assert(has_controller, "Controller X should trigger companion interaction")


func _test_prompt_tracks_range() -> void:
	var pair := await _make_dots_and_target(Vector3.ZERO)
	var dots = pair.dots
	var target = pair.target
	var prompt := dots.get_node_or_null("InteractionPrompt") as Label3D
	_assert(prompt != null, "Dots should have an interaction prompt")
	if prompt != null:
		_assert(prompt.text.contains("話す"), "The interaction prompt should explain the companion action")
		_assert(prompt.billboard == BaseMaterial3D.BILLBOARD_ENABLED, "The prompt should face the camera")
		_assert(prompt.fixed_size, "The prompt should remain readable at distance")
		_assert(prompt.visible, "The prompt should appear when Dots is in range")
	_assert(dots.has_method("is_interaction_available"), "Dots should report interaction availability")
	_assert(dots.has_method("get_interaction_distance"), "Dots should report distance to Sam")
	if dots.has_method("is_interaction_available"):
		_assert(dots.call("is_interaction_available"), "Interaction should be available while Sam is nearby")
	if dots.has_method("get_interaction_distance"):
		_assert(dots.call("get_interaction_distance") <= dots.get("interaction_radius"), "Follow distance should fit inside the interaction radius")
	target.global_position = Vector3(20.0, 0.0, 0.0)
	if dots.has_method("_process"):
		dots._process(1.0 / 60.0)
	if dots.has_method("is_interaction_available"):
		_assert(not dots.call("is_interaction_available"), "Interaction should be unavailable outside its radius")
	if prompt != null:
		_assert(not prompt.visible, "The prompt should hide when Dots is out of range")
	dots.queue_free()
	target.queue_free()
	await process_frame


func _test_interaction_uses_decisions_client_and_cooldown() -> void:
	var pair := await _make_dots_and_target(Vector3.ZERO)
	var dots = pair.dots
	if _has_property(dots, "interaction_cooldown"):
		dots.set("interaction_cooldown", 0.15)
	if _has_property(dots, "interaction_message_duration"):
		dots.set("interaction_message_duration", 0.08)
	var client = dots.get_node("DecisionsClient")
	var dialogue = dots.get_node("DialogueUI")
	var prompt = dots.get_node_or_null("InteractionPrompt") as Label3D
	var started_count := [0]
	if dots.has_signal("interaction_started"):
		dots.interaction_started.connect(func(): started_count[0] += 1)

	_assert(dots.has_method("interact"), "Dots should expose an interaction method")
	if dots.has_method("interact"):
		_assert(dots.call("interact"), "A nearby interaction should start")
		_assert(not dots.call("interact"), "Cooldown should block repeated interaction")
	_assert(started_count[0] == 1, "One accepted interaction should emit one start signal")
	_assert(client.last_result.get("error") == "endpoint_not_configured", "Interaction should reuse the existing Decisions client")
	_assert(dialogue.call("get_message") == "ごめんね、今はうまく通信できないみたい。", "A missing endpoint should show the local Japanese fallback")
	if prompt != null:
		_assert(not prompt.visible, "The interaction prompt should hide while a response is visible")
	await create_timer(0.2).timeout
	if dots.has_method("is_interaction_available"):
		_assert(dots.call("is_interaction_available"), "Interaction should be available again after cooldown")
	_assert(not dialogue.visible, "A companion response should dismiss after a short readable interval")
	if prompt != null:
		_assert(prompt.visible, "The prompt should return after the response and cooldown")
	if dots.has_method("interact"):
		_assert(dots.call("interact"), "A later interaction should start after cooldown")
	_assert(started_count[0] == 2, "A later interaction should emit a new start signal")
	dots.queue_free()
	await process_frame


func _test_busy_client_and_dialogue_prompt_visibility() -> void:
	var pair := await _make_dots_and_target(Vector3.ZERO)
	var dots = pair.dots
	var client = dots.get_node("DecisionsClient")
	var prompt = dots.get_node_or_null("InteractionPrompt") as Label3D
	client.set("_busy", true)
	if dots.has_method("is_interaction_available"):
		_assert(not dots.call("is_interaction_available"), "An active Decisions request should block a second interaction")
	if dots.has_method("interact"):
		_assert(not dots.call("interact"), "An active Decisions request should not be duplicated")
	client.set("_busy", false)
	dots.show_message("返事を表示")
	if dots.has_method("_process"):
		dots._process(1.0 / 60.0)
	if prompt != null:
		_assert(not prompt.visible, "Showing dialogue should hide the interaction prompt")
	dots.show_message("")
	if dots.has_method("_process"):
		dots._process(1.0 / 60.0)
	if prompt != null:
		_assert(prompt.visible, "Hiding dialogue should restore the interaction prompt")
	dots.queue_free()
	await process_frame


func _test_e_input_starts_interaction() -> void:
	var pair := await _make_dots_and_target(Vector3.ZERO)
	var dots = pair.dots
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	event.pressed = true
	dots._unhandled_input(event)
	var client = dots.get_node("DecisionsClient")
	_assert(not client.last_result.is_empty(), "Pressing E should invoke the Decisions interaction path")
	dots.queue_free()
	await process_frame


func _make_dots_and_target(target_position: Vector3) -> Dictionary:
	var target := CharacterBody3D.new()
	target.position = target_position
	root.add_child(target)
	var scene := load(DOTS_SCENE_PATH) as PackedScene
	_assert(scene != null, "Dots scene should load for interaction tests")
	if scene == null:
		return {"dots": null, "target": target}
	var dots = scene.instantiate()
	root.add_child(dots)
	await process_frame
	dots.set_target(target)
	await process_frame
	return {"dots": dots, "target": target}


func _has_property(object: Object, property_name: String) -> bool:
	for property_info in object.get_property_list():
		if property_info.name == property_name:
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
