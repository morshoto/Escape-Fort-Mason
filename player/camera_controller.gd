class_name CameraController extends Node3D

enum CAMERA_PIVOT { OVER_SHOULDER, THIRD_PERSON }

@export var invert_mouse_y := false
## Mouse turn in degrees per screen pixel.
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25
@export_range(0.0, 8.0) var joystick_sensitivity := 2.0
@export_range(1.0, 30.0, 0.5) var position_smoothing_speed := 14.0
@export var tilt_upper_limit := deg_to_rad(-60.0)
@export var tilt_lower_limit := deg_to_rad(60.0)

@onready var camera: Camera3D = $PlayerCamera
@onready var _over_shoulder_pivot: Node3D = $CameraOverShoulderPivot
@onready var _camera_spring_arm: SpringArm3D = $CameraSpringArm
@onready var _third_person_pivot: Node3D = $CameraSpringArm/CameraThirdPersonPivot
@onready var _camera_raycast: RayCast3D = $PlayerCamera/CameraRayCast

var _aim_target: Vector3
var _aim_collider: Node
var _pivot: Node3D
var _current_pivot_type: CAMERA_PIVOT
var _rotation_input: float
var _tilt_input: float
var _mouse_input := false
var _offset: Vector3
var _anchor: CharacterBody3D
var _euler_rotation: Vector3


func _unhandled_input(event: InputEvent) -> void:
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input:
		_rotation_input = -event.relative.x * deg_to_rad(mouse_sensitivity)
		_tilt_input = -event.relative.y * deg_to_rad(mouse_sensitivity)


func _process(delta: float) -> void:
	if not _anchor:
		return

	var controller_rotation_delta := (
		Input.get_action_raw_strength("camera_left") - Input.get_action_raw_strength("camera_right")
	) * delta
	var controller_tilt_delta := (
		Input.get_action_raw_strength("camera_up") - Input.get_action_raw_strength("camera_down")
	) * delta
	var mouse_rotation_delta := _rotation_input if _mouse_input else 0.0
	var mouse_tilt_delta := _tilt_input if _mouse_input else 0.0
	if invert_mouse_y:
		controller_tilt_delta *= -1.0
		mouse_tilt_delta *= -1.0

	if _camera_raycast.is_colliding():
		_aim_target = _camera_raycast.get_collision_point()
		_aim_collider = _camera_raycast.get_collider()
	else:
		_aim_target = _camera_raycast.global_transform * _camera_raycast.target_position
		_aim_collider = null

	# Set camera controller to current ground level for the character
	var target_position := _anchor.global_position + _offset
	target_position.y = _anchor._ground_height
	global_position = global_position.lerp(
		target_position,
		1.0 - exp(-position_smoothing_speed * delta),
	)

	# Rotates camera using euler rotation
	_euler_rotation.x += controller_tilt_delta + mouse_tilt_delta
	_euler_rotation.x = clamp(_euler_rotation.x, tilt_lower_limit, tilt_upper_limit)
	_euler_rotation.y += controller_rotation_delta + mouse_rotation_delta

	transform.basis = Basis.from_euler(_euler_rotation)

	camera.global_transform = _pivot.global_transform
	camera.rotation.z = 0

	_rotation_input = 0.0
	_tilt_input = 0.0


func setup(anchor: CharacterBody3D) -> void:
	_anchor = anchor
	global_transform = _anchor.global_transform
	_offset = global_transform.origin - anchor.global_transform.origin
	set_pivot(CAMERA_PIVOT.THIRD_PERSON)
	camera.global_transform = camera.global_transform.interpolate_with(_pivot.global_transform, 0.1)
	_camera_spring_arm.add_excluded_object(_anchor.get_rid())
	_camera_raycast.add_exception_rid(_anchor.get_rid())


func set_pivot(pivot_type: CAMERA_PIVOT) -> void:
	if pivot_type == _current_pivot_type:
		return

	match (pivot_type):
		CAMERA_PIVOT.OVER_SHOULDER:
			_over_shoulder_pivot.look_at(_aim_target)
			_pivot = _over_shoulder_pivot
		CAMERA_PIVOT.THIRD_PERSON:
			_pivot = _third_person_pivot

	_current_pivot_type = pivot_type


func get_aim_target() -> Vector3:
	return _aim_target


func get_aim_collider() -> Node:
	if is_instance_valid(_aim_collider):
		return _aim_collider
	else:
		return null
