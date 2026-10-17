extends SceneTree

const Dots = preload("res://player/dots/dots.gd")

var _failures: Array[String] = []
var _target: CharacterBody3D
var _dots: Dots


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_create_fixture()
	_test_initial_spawn_and_turning()
	_test_player_skin_rotation_drives_companion()
	_test_follow_position_uses_target_frame()
	_test_follow_smoothing_converges_without_snapping()
	_test_idle_bobbing_changes_height()
	_test_movement_state_tracks_player_speed()
	await _test_visual_scene_has_alfred_contract()
	_test_fort_mason_scene_wires_dots()

	if _failures.is_empty():
		print("Dots companion tests passed")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)


func _create_fixture() -> void:
	_target = CharacterBody3D.new()
	_target.position = Vector3(4.0, 2.0, -7.0)
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


func _test_initial_spawn_and_turning() -> void:
	_dots.set_target(_target)
	_assert_vector_close(_dots.global_position, _dots.get_follow_target_position(), "companion should spawn at its offset")

	_dots.rotation.y = 0.0
	var initial_rotation := _dots.rotation.y
	_target.rotation.y += 0.5
	_dots._physics_process(0.1)
	_assert(not is_equal_approx(_dots.rotation.y, initial_rotation), "companion should turn with the player")
	_target.rotation.y -= 0.5


func _test_player_skin_rotation_drives_companion() -> void:
	var player_scene := load("res://player/player.tscn") as PackedScene
	_assert(player_scene != null, "GDQuest player scene should be loadable")
	if player_scene == null:
		return

	var player := player_scene.instantiate() as CharacterBody3D
	root.add_child(player)
	var character_skin := player.get_node("CharacterSkin") as Node3D
	character_skin.rotation.y = 0.0
	_dots.bob_height = 0.0
	_dots.set_target(player)

	character_skin.rotation.y = PI / 2.0
	var expected := player.global_position + character_skin.global_basis * _dots.follow_offset
	_assert_vector_close(
		_dots.get_follow_target_position(),
		expected,
		"follow offset should use the actual CharacterSkin frame",
	)

	_dots.rotation.y = 0.0
	_dots._physics_process(0.1)
	_assert(
		_dots.rotation.y > 0.0,
		"companion should turn with the actual CharacterSkin",
	)
	player.free()
	_dots.set_target(_target)


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


func _test_visual_scene_has_alfred_contract() -> void:
	var scene := load("res://player/dots/dots.tscn") as PackedScene
	_assert(scene != null, "Dots scene should be loadable")
	if scene == null:
		return
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame

	var body := instance.get_node_or_null("Body") as MeshInstance3D
	_assert(body != null, "Alfred body should exist")
	if body != null:
		_assert(body.mesh is ArrayMesh, "Alfred body should use a custom mesh")
		if body.mesh is ArrayMesh:
			var body_mesh := body.mesh as ArrayMesh
			var vertices := body_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array
			_assert(vertices.size() >= 40, "Alfred body should have a shaped silhouette")
		var body_material := body.material_override as StandardMaterial3D
		_assert(
			body_material != null
				and body_material.albedo_color.r > 0.8
				and body_material.albedo_color.g > 0.5
				and body_material.albedo_color.b < 0.3,
			"Alfred body should use a bright yellow material",
		)

	var glasses := instance.get_node_or_null("Glasses") as Node3D
	_assert(glasses != null, "Alfred glasses should exist")
	if glasses != null:
		_assert(glasses.get_node_or_null("LeftFrame") is MeshInstance3D, "Left round glasses frame should exist")
		_assert(glasses.get_node_or_null("RightFrame") is MeshInstance3D, "Right round glasses frame should exist")
		var left_frame := glasses.get_node_or_null("LeftFrame") as MeshInstance3D
		var right_frame := glasses.get_node_or_null("RightFrame") as MeshInstance3D
		_assert(left_frame != null and left_frame.mesh is TorusMesh, "Left frame should be round")
		_assert(right_frame != null and right_frame.mesh is TorusMesh, "Right frame should be round")
		_assert(glasses.get_node_or_null("LeftEye") is MeshInstance3D, "Left simple eye should exist")
		_assert(glasses.get_node_or_null("RightEye") is MeshInstance3D, "Right simple eye should exist")

	var bow_tie := instance.get_node_or_null("BowTie") as Node3D
	_assert(bow_tie != null, "Alfred bow tie should exist")
	if bow_tie != null:
		_assert(bow_tie.get_node_or_null("LeftWing") is MeshInstance3D, "Left bow tie wing should exist")
		_assert(bow_tie.get_node_or_null("RightWing") is MeshInstance3D, "Right bow tie wing should exist")
		_assert(bow_tie.get_node_or_null("Knot") is MeshInstance3D, "Bow tie knot should exist")

	var collision_shapes := instance.find_children("*", "CollisionShape3D", true, false)
	_assert(collision_shapes.is_empty(), "Dots visual should not add a collision shape")
	instance.queue_free()
	await process_frame


func _test_fort_mason_scene_wires_dots() -> void:
	var scene := load("res://level/fort_mason.tscn") as PackedScene
	_assert(scene != null, "Fort Mason scene should be loadable")
	if scene == null:
		return

	var fort_mason := scene.instantiate()
	var dots := fort_mason.get_node_or_null("Dots") as Dots
	_assert(dots != null, "Fort Mason scene should include Dots")
	if dots != null:
		_assert(dots.target_path == NodePath("../Sam"), "Fort Mason Dots should target Sam")
	fort_mason.free()


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _assert_vector_close(actual: Vector3, expected: Vector3, message: String) -> void:
	_assert(actual.distance_to(expected) < 0.001, "%s: %s != %s" % [message, actual, expected])
