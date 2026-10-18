extends SceneTree

const PLAYER_SCENE_PATH := "res://player/player.tscn"
const FLOOR_LAYER := 2

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_tuning_ranges()
	var released_jump := await _simulate_jump(false)
	_assert(
		released_jump.height >= 0.8 and released_jump.height <= 1.3,
		"Jump apex should be deliberate (measured %.3fm)" % released_jump.height,
	)
	_assert(
		released_jump.airtime >= 0.55 and released_jump.airtime <= 0.85,
		"Normal jump should land promptly (measured %.3fs)" % released_jump.airtime,
	)
	var held_jump := await _simulate_jump(true)
	_assert(
		held_jump.height <= 1.3,
		"Holding jump should not extend the apex beyond 1.3m (measured %.3fm)" % held_jump.height,
	)
	print(
		"Measured jump arcs: released %.3fm/%.3fs, held %.3fm/%.3fs"
		% [released_jump.height, released_jump.airtime, held_jump.height, held_jump.airtime],
	)
	await _test_airborne_press_does_not_restart_jump()
	var cardinal := await _simulate_horizontal(60, false)
	var diagonal := await _simulate_horizontal(60, true)
	print("Measured horizontal travel: cardinal %.3fm, diagonal %.3fm" % [cardinal.distance, diagonal.distance])
	_assert(
		diagonal.distance <= cardinal.distance * 1.05,
		"Diagonal input should not move faster than cardinal input",
	)
	_assert(
		diagonal.distance >= cardinal.distance * 0.9,
		"Diagonal input should preserve full intended movement speed",
	)
	var distances: Array[float] = []
	for tick_rate in [30, 60, 120]:
		distances.append((await _simulate_horizontal(tick_rate, false)).distance)
	var minimum_distance: float = distances.min()
	var maximum_distance: float = distances.max()
	print(
		"Measured 30/60/120 Hz travel: %.3fm / %.3fm / %.3fm"
		% [distances[0], distances[1], distances[2]],
	)
	_assert(
		maximum_distance - minimum_distance <= 0.2,
		"Movement distance should stay stable at 30/60/120 Hz (range %.3fm)"
		% (maximum_distance - minimum_distance),
	)
	Engine.physics_ticks_per_second = 60
	if _failures.is_empty():
		print("Gameplay movement tests passed")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)


func _test_tuning_ranges() -> void:
	var player := _instantiate_player()
	_assert(
		player.move_speed >= 4.5 and player.move_speed <= 6.5,
		"Exploration speed should stay in the comfortable target range",
	)
	_assert(
		player.acceleration >= 12.0 and player.acceleration <= 30.0,
		"Ground acceleration should feel responsive",
	)
	_assert(
		float(player.get("_gravity")) >= -20.0 and float(player.get("_gravity")) <= -12.0,
		"Exploration gravity should support a short, controlled jump",
	)
	_assert(
		player.jump_initial_impulse >= 4.5 and player.jump_initial_impulse <= 6.5,
		"Jump impulse should match the measured jump arc",
	)
	_dispose_player(player)
	await process_frame


func _simulate_jump(hold: bool) -> Dictionary:
	Engine.physics_ticks_per_second = 60
	var floor := _create_floor()
	var player := _instantiate_player()
	await _wait_for_floor(player)
	var starting_y := player.global_position.y
	var max_height := 0.0
	var airtime := 0.0
	Input.action_press("jump")
	var started := false
	for frame in range(120):
		await physics_frame
		if player.global_position.y > starting_y + 0.01:
			started = true
		if started:
			max_height = maxf(max_height, player.global_position.y - starting_y)
			airtime = float(frame + 1) / 60.0
		if not hold and frame == 0:
			Input.action_release("jump")
		if started and player.is_on_floor() and frame > 2:
			break
	Input.action_release("jump")
	var result := {"height": max_height, "airtime": airtime}
	_dispose_player(player)
	floor.queue_free()
	await physics_frame
	return result


func _test_airborne_press_does_not_restart_jump() -> void:
	var floor := _create_floor()
	var player := _instantiate_player()
	await _wait_for_floor(player)
	Input.action_press("jump")
	await physics_frame
	Input.action_release("jump")
	for _frame in range(8):
		await physics_frame
	var velocity_before: float = player.velocity.y
	Input.action_press("jump")
	await physics_frame
	var velocity_after: float = player.velocity.y
	Input.action_release("jump")
	_assert(velocity_before > 0.0, "Test should press jump while Sam is still rising")
	_assert(
		velocity_after < velocity_before,
		"Airborne jump input should not add another vertical boost",
	)
	_dispose_player(player)
	floor.queue_free()
	await physics_frame


func _simulate_horizontal(tick_rate: int, diagonal: bool) -> Dictionary:
	Engine.physics_ticks_per_second = tick_rate
	var floor := _create_floor()
	var player := _instantiate_player()
	await _wait_for_floor(player)
	var start := player.global_position
	Input.action_press("move_up")
	if diagonal:
		Input.action_press("move_right")
	for _frame in range(tick_rate):
		await physics_frame
	Input.action_release("move_up")
	Input.action_release("move_right")
	var result := {
		"distance": Vector2(player.global_position.x - start.x, player.global_position.z - start.z).length(),
		"speed": Vector2(player.velocity.x, player.velocity.z).length(),
	}
	_dispose_player(player)
	floor.queue_free()
	await physics_frame
	return result


func _instantiate_player() -> CharacterBody3D:
	var scene := load(PLAYER_SCENE_PATH) as PackedScene
	var player := scene.instantiate() as CharacterBody3D
	player.collision_mask = 3
	(player.get_node("StepSound") as AudioStreamPlayer3D).stream = null
	(player.get_node("LandingSound") as AudioStreamPlayer3D).stream = null
	root.add_child(player)
	return player


func _dispose_player(player: CharacterBody3D) -> void:
	(player.get_node("StepSound") as AudioStreamPlayer3D).stop()
	(player.get_node("LandingSound") as AudioStreamPlayer3D).stop()
	player.queue_free()


func _create_floor() -> StaticBody3D:
	var floor := StaticBody3D.new()
	floor.position.y = -0.25
	floor.collision_layer = FLOOR_LAYER
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(30.0, 0.5, 30.0)
	shape.shape = box
	floor.add_child(shape)
	root.add_child(floor)
	return floor


func _wait_for_floor(player: CharacterBody3D) -> void:
	for _frame in range(10):
		await physics_frame
		if player.is_on_floor():
			return
	_assert(false, "Test player should begin grounded")


func _assert(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
