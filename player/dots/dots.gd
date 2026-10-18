class_name Dots
extends Node3D

signal interaction_started

const DotsVisuals = preload("res://player/dots/dots_visuals.gd")
const DECISION_INPUT_ACTION := "request_dots_decision"
const INTERACTION_INPUT_ACTION := "interact"
const DECISION_CONTEXT := "Sam wants to talk to Dots while exploring Fort Mason. Choose one helpful companion response."
const INTERACTION_PROMPT_HEIGHT := 0.95
const INTERACTION_PROMPT_HORIZONTAL_OFFSET := 0.9

enum VisualVariant {
	ALFRED,
	BLUE,
	GREEN,
	PINK,
}

enum MovementState {
	IDLE,
	WALK,
	RUN,
}

## Player-relative position: beside the player at chest height.
@export var follow_offset := Vector3(1.15, 0.62, 0.0)
## Larger values make the companion catch up more quickly.
@export_range(0.1, 30.0, 0.1) var follow_speed := 8.0
## Larger values make the companion turn more quickly.
@export_range(0.1, 30.0, 0.1) var rotation_speed := 10.0
## Vertical idle motion in world units.
@export_range(0.0, 1.0, 0.01) var bob_height := 0.15
## Vertical idle motion frequency.
@export_range(0.0, 10.0, 0.1) var bob_speed := 2.0
## Horizontal speed below this value is treated as idle.
@export_range(0.0, 3.0, 0.05) var walk_speed_threshold := 0.25
## Horizontal speed at or above this value is treated as running.
@export_range(0.5, 15.0, 0.1) var run_speed_threshold := 5.0
@export_range(0.5, 5.0, 0.1) var interaction_radius := 2.5
@export_range(0.0, 5.0, 0.05) var interaction_cooldown := 1.0
@export_range(0.1, 10.0, 0.1) var interaction_message_duration := 4.0
@export var target_path: NodePath
@export var visual_variant: VisualVariant = VisualVariant.ALFRED

var _target: CharacterBody3D
var _target_orientation: Node3D
var _bob_time := 0.0
var _visuals_built := false
var _interaction_cooldown_remaining := 0.0
var _message_time_remaining := 0.0

@onready var _interaction_prompt: Label3D = get_node_or_null("InteractionPrompt") as Label3D


func _ready() -> void:
	_build_visuals()
	_apply_readable_prompt_font_weight()
	var dialogue := get_node_or_null("DialogueUI")
	if dialogue != null and dialogue.has_signal("message_changed"):
		dialogue.message_changed.connect(_on_dialogue_message_changed)
	if not target_path.is_empty():
		set_target(get_node_or_null(target_path) as CharacterBody3D)
	if _target:
		global_position = get_follow_target_position()
		rotation.y = _target_heading_y()
	_update_interaction_prompt()


func _process(delta: float) -> void:
	if _interaction_cooldown_remaining > 0.0:
		_interaction_cooldown_remaining = maxf(_interaction_cooldown_remaining - delta, 0.0)
	if _message_time_remaining > 0.0:
		_message_time_remaining = maxf(_message_time_remaining - delta, 0.0)
		if _message_time_remaining <= 0.0:
			show_message("")
	_update_interaction_prompt()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target):
		return

	_bob_time += delta * bob_speed
	var desired_position := get_follow_target_position()
	desired_position.y += sin(_bob_time) * bob_height
	global_position = global_position.lerp(desired_position, _follow_weight(delta))

	var desired_rotation := _target_heading_y()
	rotation.y = lerp_angle(rotation.y, desired_rotation, _rotation_weight(delta))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(INTERACTION_INPUT_ACTION):
		if interact():
			get_viewport().set_input_as_handled()
		return
	if not event.is_action_pressed(DECISION_INPUT_ACTION):
		return
	var decisions_client := get_node_or_null("DecisionsClient") as DotsDecisionClient
	if decisions_client != null:
		decisions_client.request_decision(DECISION_CONTEXT)
		get_viewport().set_input_as_handled()


func is_interaction_available() -> bool:
	if not is_instance_valid(_target) or _interaction_cooldown_remaining > 0.0:
		return false
	if get_interaction_distance() > interaction_radius:
		return false
	var decisions_client := get_node_or_null("DecisionsClient") as DotsDecisionClient
	return decisions_client == null or not decisions_client.is_requesting()


func get_interaction_distance() -> float:
	if not is_instance_valid(_target):
		return INF
	return global_position.distance_to(_target.global_position)


func interact() -> bool:
	if not is_interaction_available():
		return false
	_interaction_cooldown_remaining = interaction_cooldown
	_message_time_remaining = 0.0
	show_message("")
	_update_interaction_prompt()
	interaction_started.emit()
	var decisions_client := get_node_or_null("DecisionsClient") as DotsDecisionClient
	if decisions_client != null:
		decisions_client.request_decision(DECISION_CONTEXT)
	else:
		show_message("ごめんね、今はうまく通信できないみたい。")
	return true


func set_target(target: CharacterBody3D) -> void:
	_target = target
	_target_orientation = null
	if _target:
		_target_orientation = _target.get_node_or_null("CharacterSkin") as Node3D
	if _target and is_inside_tree():
		global_position = get_follow_target_position()
		rotation.y = _target_heading_y()


func get_follow_target_position() -> Vector3:
	if not is_instance_valid(_target):
		return global_position
	return _target.global_position + _target_heading_basis() * follow_offset


func _target_heading_basis() -> Basis:
	if is_instance_valid(_target_orientation):
		return _target_orientation.global_basis
	return _target.global_basis


func _target_heading_y() -> float:
	if is_instance_valid(_target_orientation):
		return _target_orientation.global_rotation.y
	return _target.global_rotation.y


func get_movement_state() -> MovementState:
	if not is_instance_valid(_target):
		return MovementState.IDLE

	var horizontal_velocity := Vector3(_target.velocity.x, 0.0, _target.velocity.z).length()
	if horizontal_velocity >= run_speed_threshold:
		return MovementState.RUN
	if horizontal_velocity > walk_speed_threshold:
		return MovementState.WALK
	return MovementState.IDLE


func show_message(message: String) -> void:
	var dialogue := get_node_or_null("DialogueUI")
	if dialogue != null and dialogue.has_method("show_message"):
		dialogue.call("show_message", message)
	else:
		_on_dialogue_message_changed(message)


func _on_dialogue_message_changed(message: String) -> void:
	_message_time_remaining = interaction_message_duration if not message.is_empty() else 0.0
	_update_interaction_prompt()


func _update_interaction_prompt() -> void:
	if _interaction_prompt == null:
		return
	var camera := get_viewport().get_camera_3d()
	var screen_right := global_basis.x
	if camera != null:
		screen_right = camera.global_basis.x
	var prompt_side := 1.0
	if is_instance_valid(_target) and (_target.global_position - global_position).dot(screen_right) > 0.0:
		prompt_side = -1.0
	_interaction_prompt.global_position = (
		global_position
		+ Vector3.UP * INTERACTION_PROMPT_HEIGHT
		+ screen_right * INTERACTION_PROMPT_HORIZONTAL_OFFSET * prompt_side
	)
	var dialogue := get_node_or_null("DialogueUI")
	var dialogue_visible: bool = false
	if dialogue != null:
		dialogue_visible = dialogue.visible
	_interaction_prompt.visible = is_interaction_available() and not dialogue_visible


func _apply_readable_prompt_font_weight() -> void:
	if _interaction_prompt == null or _interaction_prompt.font == null:
		return
	var base_font := _interaction_prompt.font
	var weight_tag := TextServerManager.get_primary_interface().name_to_tag("wght")
	if not base_font.get_supported_variation_list().has(weight_tag):
		return
	var variation := FontVariation.new()
	variation.base_font = base_font
	variation.variation_opentype = {weight_tag: 700.0}
	_interaction_prompt.font = variation


func _follow_weight(delta: float) -> float:
	return 1.0 - exp(-follow_speed * delta)


func _rotation_weight(delta: float) -> float:
	return 1.0 - exp(-rotation_speed * delta)


func _build_visuals() -> void:
	if _visuals_built:
		return
	_visuals_built = true
	set_meta("visual_variant", DotsVisuals.variant_name(visual_variant))
	DotsVisuals.build(self, visual_variant)
