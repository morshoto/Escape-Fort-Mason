extends SceneTree

const STAGE_PATH := "res://level/fort_mason.tscn"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage := (load(STAGE_PATH) as PackedScene).instantiate() as Node3D
	root.add_child(stage)
	var sam := stage.get_node("Sam") as Player
	var spawn_position: Vector3 = sam.get("_start_position")
	var fall_recovery := stage.get_node_or_null("DeathPlane") as Area3D
	_assert(fall_recovery != null, "Fort Mason should include an off-map fall recovery plane")

	for _frame in range(90):
		await physics_frame
		if sam.is_on_floor():
			break
	_assert(sam.is_on_floor(), "Sam should settle on the plaza before the fall recovery check")

	sam.global_position = Vector3(12.0, 1.0, -8.0)
	sam.velocity = Vector3(0.0, -1.0, 0.0)
	sam.set("_jump_hold_time_left", 0.1)
	var respawned := false
	for _frame in range(120):
		await physics_frame
		var horizontal_offset := Vector2(
		sam.global_position.x - spawn_position.x,
		sam.global_position.z - spawn_position.z,
		)
		if horizontal_offset.length() < 0.5 and sam.is_on_floor():
			respawned = true
			break
	_assert(respawned, "Falling beside the warehouse should return Sam to the spawn")
	_assert(sam.velocity.is_zero_approx(), "Respawn should clear carried fall velocity")
	_assert(
		is_zero_approx(float(sam.get("_jump_hold_time_left"))),
		"Respawn should clear the active jump hold",
	)

	stage.queue_free()
	await process_frame
	if _failures.is_empty():
		print("Gameplay respawn tests passed")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)


func _assert(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
