class_name DialogueUI
extends Node3D

signal message_changed(message: String)

const DEFAULT_MESSAGE := "こんにちは、Sam！"
const DEBUG_INPUT_ACTION := "show_dots_dialogue"
const BUBBLE_REFERENCE_DISTANCE := 8.0

@export_range(4, 32, 1) var max_line_characters := 16
@export var default_message := DEFAULT_MESSAGE

@onready var _message_label: Label3D = $Message
@onready var _bubble: Node3D = $Bubble

var _message := ""


func _ready() -> void:
	_message_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_message_label.fixed_size = true
	_message_label.no_depth_test = true
	show_message(default_message)


func _process(_delta: float) -> void:
	if not visible:
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var distance: float = maxf(global_position.distance_to(camera.global_position), 1.0)
	_bubble.scale = Vector3.ONE * (distance / BUBBLE_REFERENCE_DISTANCE)


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
	var line_characters := 0
	for character in message:
		if character == "\n":
			lines.append(line)
			line = ""
			line_characters = 0
			continue
		if line_characters >= max_line_characters:
			lines.append(line)
			line = ""
			line_characters = 0
		line += character
		line_characters += 1
	if not line.is_empty() or lines.is_empty():
		lines.append(line)
	return "\n".join(lines)
