class_name DotsDecisionClient
extends Node

signal completed(result: Dictionary)

const REQUEST_TIMEOUT_SECONDS := 8.0
const FALLBACK_MESSAGE := "ごめんね、今はうまく通信できないみたい。"
const ACTION_MESSAGES := {
	"greet": "こんにちは、Sam！",
	"observe": "Fort Masonの景色を一緒に見よう。",
	"wait": "少しここで待っていよう。",
}

var _http: HTTPRequest
var _busy := false
var last_result: Dictionary = {}


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = REQUEST_TIMEOUT_SECONDS
	_http.request_completed.connect(_on_request_completed)
	add_child(_http)


func request_decision(context: String) -> bool:
	if _busy:
		completed.emit(_failure("request_in_progress"))
		return false

	var endpoint := str(ProjectSettings.get_setting("escape_fort_mason/decisions_endpoint", "")).strip_edges()
	if endpoint.is_empty():
		_finish(_failure("endpoint_not_configured"))
		return false
	if not is_endpoint_allowed(endpoint):
		_finish(_failure("https_required"))
		return false

	var cleaned_context := context.strip_edges()
	if cleaned_context.is_empty() or cleaned_context.length() > 280:
		_finish(_failure("invalid_context"))
		return false

	_busy = true
	_show_message("考え中…")
	var request_error := _http.request(
		endpoint,
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify({"context": cleaned_context}),
	)
	if request_error != OK:
		_busy = false
		_finish(_failure("request_start_failed"))
		return false
	return true


func is_requesting() -> bool:
	return _busy


static func is_endpoint_allowed(endpoint: String) -> bool:
	if endpoint.begins_with("https://"):
		return true
	if endpoint.contains("@") or endpoint.contains("#") or endpoint.contains("?"):
		return false
	return endpoint.begins_with("http://localhost:") or endpoint.begins_with("http://127.0.0.1:")


static func parse_response(result: int, response_code: int, body: PackedByteArray) -> Dictionary:
	if result == HTTPRequest.RESULT_TIMEOUT:
		return _failure("timeout")
	if result != HTTPRequest.RESULT_SUCCESS:
		return _failure("network_error")
	if response_code != 200:
		return _failure("http_error")

	var parser := JSON.new()
	if parser.parse(body.get_string_from_utf8()) != OK:
		return _failure("invalid_response")
	var payload = parser.data
	if typeof(payload) != TYPE_DICTIONARY:
		return _failure("invalid_response")

	var action := str(payload.get("action", ""))
	if not ACTION_MESSAGES.has(action):
		return _failure("invalid_response")
	if payload.get("message") != ACTION_MESSAGES[action] or payload.get("source") != "openai":
		return _failure("invalid_response")

	return {
		"ok": true,
		"action": action,
		"message": ACTION_MESSAGES[action],
		"source": "openai",
		"error": "",
	}


func _on_request_completed(
	result: int,
	response_code: int,
	_response_headers: PackedStringArray,
	body: PackedByteArray,
) -> void:
	_busy = false
	var parsed := parse_response(result, response_code, body)
	if not parsed.ok:
		push_warning("Dots Decisions request failed: %s" % parsed.error)
	_finish(parsed)


func _finish(result: Dictionary) -> void:
	last_result = result
	if result.ok:
		print("Dots Decisions source=%s action=%s" % [result.source, result.action])
	else:
		print("Dots Decisions fallback error=%s" % result.error)
	_show_message(str(result.message))
	completed.emit(result)


func _show_message(message: String) -> void:
	var dots := get_parent()
	if is_instance_valid(dots) and dots.has_method("show_message"):
		dots.show_message(message)


static func _failure(code: String) -> Dictionary:
	return {
		"ok": false,
		"action": "wait",
		"message": FALLBACK_MESSAGE,
		"source": "fallback",
		"error": code,
	}
