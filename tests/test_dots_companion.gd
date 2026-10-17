extends SceneTree

const Dots = preload("res://player/dots/dots.gd")

var _failures: Array[String] = []
var _target: CharacterBody3D
var _dots: Dots


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_create_fixture()
	_test_follow_position_uses_target_frame()
	_test_follow_smoothing_converges_without_snapping()
	_test_idle_bobbing_changes_height()
	_test_movement_state_tracks_player_speed()
	_test_visual_scene_has_no_collision_shape()

	if _failures.is_empty():
		print("Dots companion tests passed")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)


func _create_fixture() -> void:
	_target = CharacterBody3D.new()
	_target.global_position = Vector3(4.0, 2.0, -7.0)
	_target.rotation.y = PI / 2.0
	root.add_child(_target)

	_dots = Dots.new()
	_dots.follow_offset = Vector3(1.5, 1.25, 2.0)
	_dots.follow_speed = 8.0
	_dots.bob_height = 0.2
	_dots.bob_speed = 2.0
	root.add_child(_dots)
	_dots.set_target(_target)


func _test_follow_position_uses_target_frame() -> void:
	_dots.bob_height = 0.0
	var expected := _target.global_position + _target.global_basis * _dots.follow_offset
	var actual: Vector3 = _dots.get_follow_target_position()
	_assert_vector_close(actual, expected, "follow offset should use target rotation")


func _test_follow_smoothing_converges_without_snapping() -> void:
	_dots.bob_height = 0.0
	_dots.global_position = _target.global_position
	var desired: Vector3 = _dots.get_follow_target_position()
	_dots._physics_process(0.05)
	var first_step_distance := _dots.global_position.distance_to(desired)
	_assert(first_step_distance > 0.01, "follow should not snap on the first frame")
	_assert(first_step_distance < _target.global_position.distance_to(desired), "follow should move toward the target")

	_dots._physics_process(1.0)
	_assert(_dots.global_position.distance_to(desired) < 0.01, "follow should converge to the offset")


func _test_idle_bobbing_changes_height() -> void:
	_dots.bob_height = 0.35
	_dots.bob_speed = 2.0
	_target.velocity = Vector3.ZERO
	_dots.global_position = _dots.get_follow_target_position()
	_dots._physics_process(0.2)
	var first_height := _dots.global_position.y
	_dots._physics_process(0.2)
	var second_height := _dots.global_position.y
	_assert(not is_equal_approx(first_height, second_height), "idle companion should bob vertically")


func _test_movement_state_tracks_player_speed() -> void:
	_target.velocity = Vector3.ZERO
	_assert(_dots.get_movement_state() == Dots.MovementState.IDLE, "stationary player should produce idle state")
	_target.velocity = Vector3(0.0, 0.0, -2.0)
	_assert(_dots.get_movement_state() == Dots.MovementState.WALK, "slow player should produce walk state")
	_target.velocity = Vector3(0.0, 0.0, -7.0)
	_assert(_dots.get_movement_state() == Dots.MovementState.RUN, "fast player should produce run state")


func _test_visual_scene_has_no_collision_shape() -> void:
	var scene := load("res://player/dots/dots.tscn") as PackedScene
	_assert(scene != null, "Dots scene should be loadable")
	if scene == null:
		return
	var instance := scene.instantiate()
	var collision_shapes := instance.find_children("*", "CollisionShape3D", true, false)
	_assert(collision_shapes.is_empty(), "Dots visual should not add a collision shape")
	instance.free()


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _assert_vector_close(actual: Vector3, expected: Vector3, message: String) -> void:
	_assert(actual.distance_to(expected) < 0.001, "%s: %s != %s" % [message, actual, expected])
