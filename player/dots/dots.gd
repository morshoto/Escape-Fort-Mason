class_name Dots
extends Node3D

enum MovementState {
	IDLE,
	WALK,
	RUN,
}

## Player-relative position: right, above, and behind the player.
@export var follow_offset := Vector3(1.8, 1.25, 1.8)
## Larger values make the companion catch up more quickly.
@export_range(0.1, 30.0, 0.1) var follow_speed := 8.0
## Larger values make the companion turn more quickly.
@export_range(0.1, 30.0, 0.1) var rotation_speed := 10.0
## Vertical idle motion in world units.
@export_range(0.0, 1.0, 0.01) var bob_height := 0.2
## Vertical idle motion frequency.
@export_range(0.0, 10.0, 0.1) var bob_speed := 2.0
## Horizontal speed below this value is treated as idle.
@export_range(0.0, 3.0, 0.05) var walk_speed_threshold := 0.25
## Horizontal speed at or above this value is treated as running.
@export_range(0.5, 15.0, 0.1) var run_speed_threshold := 5.0
@export var target_path: NodePath

var _target: CharacterBody3D
var _target_orientation: Node3D
var _bob_time := 0.0


func _ready() -> void:
	if not target_path.is_empty():
		set_target(get_node_or_null(target_path) as CharacterBody3D)
	if _target:
		global_position = get_follow_target_position()
		rotation.y = _target_heading_y()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target):
		return

	_bob_time += delta * bob_speed
	var desired_position := get_follow_target_position()
	desired_position.y += sin(_bob_time) * bob_height
	global_position = global_position.lerp(desired_position, _follow_weight(delta))

	var desired_rotation := _target_heading_y()
	rotation.y = lerp_angle(rotation.y, desired_rotation, _rotation_weight(delta))


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


func _follow_weight(delta: float) -> float:
	return 1.0 - exp(-follow_speed * delta)


func _rotation_weight(delta: float) -> float:
	return 1.0 - exp(-rotation_speed * delta)
