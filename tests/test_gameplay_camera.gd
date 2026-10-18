extends SceneTree

const STAGE_PATH := "res://level/fort_mason.tscn"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := load(STAGE_PATH) as PackedScene
	_assert(scene != null, "Fort Mason should load for camera checks")
	if scene == null:
		_finish()
		return
	var stage := scene.instantiate() as Node3D
	root.add_child(stage)
	for _frame in range(3):
		await process_frame
	var sam := stage.get_node("Sam") as CharacterBody3D
	var controller := sam.get_node("CameraController") as CameraController
	var arm := controller.get_node("CameraSpringArm") as SpringArm3D
	var ground_shapecast := sam.get_node("GroundShapeCast") as ShapeCast3D
	var third_person_pivot := controller.get_node("CameraSpringArm/CameraThirdPersonPivot") as Marker3D

	ground_shapecast.force_shapecast_update()
	_assert(
		(ground_shapecast.collision_mask & FortMasonStage.LEVEL_COLLISION_LAYER) != 0,
		"Ground height ShapeCast should detect the Fort Mason level layer",
	)
	_assert(
		ground_shapecast.get_collision_count() > 0,
		"Ground height ShapeCast should find the floor under Sam",
	)
	if ground_shapecast.get_collision_count() > 0:
		_assert(
			absf(sam._ground_height - ground_shapecast.get_collision_point(0).y) < 0.1,
			"Camera ground target should match the detected floor height",
		)
	_test_default_framing(controller, arm, third_person_pivot)
	_test_collision_and_pivot_modes(stage, controller, arm)
	_test_smooth_follow(sam, controller)
	await _test_jump_framing(sam, controller)
	_test_pitch_and_input(controller)

	stage.queue_free()
	await process_frame
	_finish()


func _test_default_framing(
	controller: CameraController,
	arm: SpringArm3D,
	third_person_pivot: Marker3D,
) -> void:
	_assert(
		arm.spring_length >= 5.0 and arm.spring_length <= 6.5,
		"Third-person camera follow distance should be 5.0–6.5m",
	)
	_assert(
		absf(third_person_pivot.position.z - arm.spring_length) < 0.05,
		"Third-person pivot should reach the configured spring length",
	)
	_assert(
		controller._pivot == third_person_pivot,
		"Gameplay should start on the third-person pivot",
	)
	_assert(
		controller.camera.fov >= 45.0 and controller.camera.fov <= 60.0,
		"Gameplay camera FOV should remain comfortable",
	)
	_assert(
		controller.camera.global_position.distance_to(third_person_pivot.global_position) < 0.05,
		"Player camera should track the active third-person pivot",
	)


func _test_collision_and_pivot_modes(stage: Node3D, controller: CameraController, arm: SpringArm3D) -> void:
	_assert(
		(arm.collision_mask & FortMasonStage.LEVEL_COLLISION_LAYER) != 0,
		"Camera spring arm should detect level walls and the warehouse roof",
	)
	controller.set_pivot(CameraController.CAMERA_PIVOT.OVER_SHOULDER)
	_assert(
		controller._pivot == controller.get_node("CameraOverShoulderPivot"),
		"Aim should retain the existing over-shoulder pivot",
	)
	controller.set_pivot(CameraController.CAMERA_PIVOT.THIRD_PERSON)
	_assert(
		controller._pivot == controller.get_node("CameraSpringArm/CameraThirdPersonPivot"),
		"Releasing aim should restore the third-person pivot",
	)
	var sam := stage.get_node("Sam") as CharacterBody3D
	sam.global_position = Vector3(0.0, 1.0, -12.0)
	controller._process(1.0 / 60.0)
	_assert(
		(arm.collision_mask & FortMasonStage.LEVEL_COLLISION_LAYER) != 0,
		"Indoor camera should continue using warehouse collision",
	)


func _test_smooth_follow(sam: CharacterBody3D, controller: CameraController) -> void:
	var starting_x := controller.global_position.x
	sam.global_position.x += 3.0
	controller._process(1.0 / 60.0)
	var first_step := controller.global_position.x - starting_x
	_assert(first_step > 0.0 and first_step < 3.0, "Camera should ease toward player movement")
	for _frame in range(30):
		controller._process(1.0 / 60.0)
	_assert(
		absf(controller.global_position.x - sam.global_position.x) < 0.05,
		"Camera should settle on the player after movement",
	)


func _test_jump_framing(sam: CharacterBody3D, controller: CameraController) -> void:
	var grounded_height := sam.global_position.y
	sam.global_position.y += 1.1
	sam.velocity.y = 5.7
	await physics_frame
	controller._process(1.0)
	var projected_head := controller.camera.unproject_position(
		sam.global_position + Vector3.UP * 2.0
	)
	var viewport_height := controller.camera.get_viewport().get_visible_rect().size.y
	_assert(
		projected_head.y >= 0.0 and projected_head.y <= viewport_height,
		"Sam's head should remain in frame at the jump apex (screen y %.1f / %.1f)"
		% [projected_head.y, viewport_height],
	)
	sam.global_position.y = grounded_height
	sam.velocity = Vector3.ZERO
	await physics_frame
	controller._process(1.0)


func _test_pitch_and_input(controller: CameraController) -> void:
	controller._tilt_input = 100.0
	controller._process(1.0 / 60.0)
	_assert(
		controller._euler_rotation.x <= controller.tilt_upper_limit,
		"Camera pitch should respect the upper limit",
	)
	controller._tilt_input = -100.0
	controller._process(1.0 / 60.0)
	_assert(
		controller._euler_rotation.x >= controller.tilt_lower_limit,
		"Camera pitch should respect the lower limit",
	)

	var starting_yaw := controller._euler_rotation.y
	var mouse_turn_degrees: Array[float] = []
	for frame_delta in [1.0 / 30.0, 1.0 / 60.0, 1.0 / 120.0]:
		controller._mouse_input = true
		controller._rotation_input = -40.0 * deg_to_rad(controller.mouse_sensitivity)
		controller._process(frame_delta)
		mouse_turn_degrees.append(rad_to_deg(absf(controller._euler_rotation.y - starting_yaw)))
		controller._euler_rotation.y = starting_yaw
	controller._mouse_input = false
	_assert(
		absf(mouse_turn_degrees[1] - 10.0) < 0.1,
		"A 40-pixel mouse delta should turn the camera by 10 degrees at 60 Hz",
	)
	_assert(
		maxf(maxf(mouse_turn_degrees[0], mouse_turn_degrees[1]), mouse_turn_degrees[2])
			- minf(minf(mouse_turn_degrees[0], mouse_turn_degrees[1]), mouse_turn_degrees[2])
			< 0.1,
		"Mouse camera sensitivity should stay consistent at 30, 60, and 120 Hz",
	)

	Input.action_press("camera_left")
	starting_yaw = controller._euler_rotation.y
	controller._process(0.1)
	Input.action_release("camera_left")
	_assert(
		absf(controller._euler_rotation.y - starting_yaw) > 0.05,
		"Existing controller camera input should remain active",
	)


func _assert(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)


func _finish() -> void:
	if _failures.is_empty():
		print("Gameplay camera tests passed")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
