class_name DialogueUI
extends Node3D

signal message_changed(message: String)

const DEFAULT_MESSAGE := "こんにちは、Sam！"
const DEBUG_INPUT_ACTION := "show_dots_dialogue"
const BUBBLE_REFERENCE_DISTANCE := 8.0

@export_range(4, 32, 1) var max_line_characters := 16
@export_range(1, 5, 1) var max_visible_lines := 3
@export_range(0.8, 1.5, 0.05) var max_bubble_scale := 1.2
@export var bubble_anchor_height := 1.7
@export var default_message := DEFAULT_MESSAGE

@onready var _message_label: Label3D = $Message
@onready var _bubble: Node3D = $Bubble

var _message := ""
var _home_local_position := Vector3.ZERO


func _ready() -> void:
	_home_local_position = position
	_message_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_message_label.fixed_size = true
	_message_label.no_depth_test = true
	_message_label.text = ""
	visible = false


func _process(_delta: float) -> void:
	if not visible:
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var base_position := _get_home_world_position()
	var anchor_position := base_position + Vector3(0.0, bubble_anchor_height, 0.0)
	if camera.is_position_behind(anchor_position):
		global_position = base_position
		return
	var distance: float = maxf(anchor_position.distance_to(camera.global_position), 1.0)
	var scale_factor := clampf(distance / BUBBLE_REFERENCE_DISTANCE, 0.8, max_bubble_scale)
	_bubble.scale = Vector3.ONE * scale_factor

	var viewport_rect := get_viewport().get_visible_rect()
	var viewport_size := viewport_rect.size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		global_position = base_position
		return
	var screen_position := camera.unproject_position(anchor_position)
	var horizontal_margin := minf(viewport_size.x * 0.08, 220.0)
	var vertical_margin := minf(viewport_size.y * 0.1, 120.0)
	var safe_position := Vector2(
		clampf(screen_position.x, horizontal_margin, viewport_size.x - horizontal_margin),
		clampf(screen_position.y, vertical_margin, viewport_size.y - vertical_margin)
	)
	var safe_world_position := camera.project_position(safe_position, distance)
	global_position = base_position + safe_world_position - anchor_position


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(DEBUG_INPUT_ACTION):
		show_message(default_message)
		get_viewport().set_input_as_handled()


func show_message(message: String) -> void:
	_message = message.strip_edges()
	_message_label.text = _wrap_message(_message)
	visible = not _message.is_empty()
	message_changed.emit(_message)


func get_message() -> String:
	return _message


func get_display_text() -> String:
	return _message_label.text


func _wrap_message(message: String) -> String:
	if message.is_empty():
		return ""

	var lines: Array[String] = []
	var line := ""
	var characters: Array[String] = []
	for character in message:
		characters.append(character)
	var was_truncated := false
	for index in range(characters.size()):
		var character := characters[index]
		if character == "\n":
			lines.append(line)
			line = ""
			if lines.size() >= max_visible_lines:
				was_truncated = index < characters.size() - 1
				break
			continue
		if line.length() >= max_line_characters:
			lines.append(line)
			line = ""
			if lines.size() >= max_visible_lines:
				was_truncated = true
				break
		line += character
	if not was_truncated and lines.size() < max_visible_lines and (not line.is_empty() or lines.is_empty()):
		lines.append(line)
	if was_truncated and not lines.is_empty():
		var last_line := lines[lines.size() - 1]
		if last_line.length() >= max_line_characters:
			last_line = last_line.substr(0, max_line_characters - 1)
		lines[lines.size() - 1] = last_line + "…"
	return "\n".join(lines)


func _get_home_world_position() -> Vector3:
	var parent := get_parent() as Node3D
	if parent != null:
		return parent.to_global(_home_local_position)
	return _home_local_position
