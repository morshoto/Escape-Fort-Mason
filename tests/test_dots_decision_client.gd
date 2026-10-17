extends SceneTree

const DecisionsClient = preload("res://player/dots/dots_decision_client.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_success_response_maps_only_fixed_japanese_copy()
	_test_invalid_and_error_responses_use_local_fallback()
	_test_endpoint_validation_allows_only_https_or_loopback_http()
	await _test_dots_scene_wires_the_decision_key()
	await _test_missing_endpoint_does_not_stop_dots()

	if _failures.is_empty():
		print("Dots Decisions client tests passed")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)


func _test_success_response_maps_only_fixed_japanese_copy() -> void:
	var success := DecisionsClient.parse_response(
		HTTPRequest.RESULT_SUCCESS,
		200,
		JSON.stringify({
			"action": "observe",
			"message": "Fort Masonの景色を一緒に見よう。",
			"source": "openai",
		}).to_utf8_buffer(),
	)
	_assert(success.ok, "A valid Decisions response should succeed")
	_assert(success.action == "observe", "The response should preserve its allowlisted action")
	_assert(success.message == "Fort Masonの景色を一緒に見よう。", "The mapped Japanese message should be returned")
	_assert(success.source == "openai", "A valid live response should identify its source")

	var unapproved_action := DecisionsClient.parse_response(
		HTTPRequest.RESULT_SUCCESS,
		200,
		JSON.stringify({
			"action": "unlock_everything",
			"message": "任意のモデル文章",
			"source": "openai",
		}).to_utf8_buffer(),
	)
	_assert(not unapproved_action.ok, "Unapproved actions should be rejected")
	_assert(unapproved_action.source == "fallback", "Unapproved responses should use local fallback copy")


func _test_invalid_and_error_responses_use_local_fallback() -> void:
	var malformed := DecisionsClient.parse_response(
		HTTPRequest.RESULT_SUCCESS,
		200,
		"not-json".to_utf8_buffer(),
	)
	_assert(not malformed.ok, "Malformed JSON should not be treated as a decision")

	var http_error := DecisionsClient.parse_response(
		HTTPRequest.RESULT_SUCCESS,
		503,
		"{}".to_utf8_buffer(),
	)
	_assert(not http_error.ok, "HTTP errors should use the local fallback")

	var timeout := DecisionsClient.parse_response(
		HTTPRequest.RESULT_TIMEOUT,
		0,
		PackedByteArray(),
	)
	_assert(not timeout.ok and timeout.error == "timeout", "Timeouts should be identified and contained")
	_assert(timeout.message == "ごめんね、今はうまく通信できないみたい。", "Errors should provide readable Japanese fallback copy")


func _test_endpoint_validation_allows_only_https_or_loopback_http() -> void:
	_assert(DecisionsClient.is_endpoint_allowed("https://api.example/decision"), "Production HTTPS should be allowed")
	_assert(DecisionsClient.is_endpoint_allowed("http://127.0.0.1:8787/api/decision"), "Local loopback HTTP should be allowed for development")
	_assert(DecisionsClient.is_endpoint_allowed("http://localhost:8787/api/decision"), "Localhost HTTP should be allowed for development")
	_assert(not DecisionsClient.is_endpoint_allowed("http://api.example/decision"), "Remote insecure HTTP should be rejected")
	_assert(not DecisionsClient.is_endpoint_allowed("http://localhost.evil:8787/api/decision"), "Lookalike hosts should be rejected")
	_assert(not DecisionsClient.is_endpoint_allowed("http://user@localhost:8787/api/decision"), "Credentialed URLs should be rejected")


func _test_dots_scene_wires_the_decision_key() -> void:
	_assert(InputMap.has_action("request_dots_decision"), "R should have a Decisions input action")
	var dots_scene := load("res://player/dots/dots.tscn") as PackedScene
	_assert(dots_scene != null, "The Dots scene should load with its Decisions client")
	if dots_scene == null:
		return
	var dots := dots_scene.instantiate()
	root.add_child(dots)
	await process_frame
	_assert(dots.get_node_or_null("DecisionsClient") is DecisionsClient, "Dots should own its Decisions client")
	dots.queue_free()
	await process_frame


func _test_missing_endpoint_does_not_stop_dots() -> void:
	ProjectSettings.set_setting("escape_fort_mason/decisions_endpoint", "")
	var dots_scene := load("res://player/dots/dots.tscn") as PackedScene
	_assert(dots_scene != null, "The Dots scene should load for client integration")
	if dots_scene == null:
		return

	var dots := dots_scene.instantiate()
	root.add_child(dots)
	await process_frame
	var client := DecisionsClient.new()
	dots.add_child(client)
	await process_frame

	var started := client.request_decision("Sam is exploring Fort Mason.")
	_assert(not started, "An unconfigured endpoint should not start a network request")
	_assert(not client.last_result.is_empty(), "The client should report a safe fallback result")
	_assert(client.last_result.get("source") == "fallback", "An unavailable backend should identify local copy")
	var dialogue := dots.get_node("DialogueUI")
	_assert(dialogue.call("get_message") == "ごめんね、今はうまく通信できないみたい。", "Dots should display fallback without crashing")
	dots.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
