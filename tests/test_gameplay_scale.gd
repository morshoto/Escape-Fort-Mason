extends SceneTree

const Dots = preload("res://player/dots/dots.gd")
const PLAYER_SCENE_PATH := "res://player/player.tscn"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_sam_visual_and_collision_scale()
	await _test_dots_variant_scale_and_follow_offset()
	if _failures.is_empty():
		print("Gameplay scale tests passed")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)


func _test_sam_visual_and_collision_scale() -> void:
	var scene := load(PLAYER_SCENE_PATH) as PackedScene
	_assert(scene != null, "Sam scene should load for scale checks")
	if scene == null:
		return
	var player := scene.instantiate() as CharacterBody3D
	root.add_child(player)
	await process_frame
	await process_frame

	var skin := player.get_node("CharacterSkin") as Node3D
	var bounds := _mesh_bounds_in(skin, skin)
	var visual_height := bounds.size.y
	_assert(
		visual_height >= 1.65 and visual_height <= 1.95,
		"Sam rendered height should be human scale (measured %.3fm)" % visual_height,
	)

	var collision := player.get_node("CharacterCollisionShape") as CollisionShape3D
	var capsule := collision.shape as CapsuleShape3D
	_assert(capsule != null, "Sam should use a capsule collision shape")
	if capsule != null:
		var collision_bottom := collision.position.y - capsule.height / 2.0
		var collision_center := collision.position.y
		_assert(absf(collision_bottom) < 0.08, "Sam collision capsule should meet the ground plane")
		_assert(
			absf(collision_center - visual_height / 2.0) <= 0.25,
			"Sam collision capsule should stay centered on the visible body",
		)
	player.queue_free()
	await process_frame


func _test_dots_variant_scale_and_follow_offset() -> void:
	var target := CharacterBody3D.new()
	target.name = "ScaleTestPlayer"
	root.add_child(target)
	for variant in [Dots.VisualVariant.ALFRED, Dots.VisualVariant.BLUE, Dots.VisualVariant.GREEN, Dots.VisualVariant.PINK]:
		var dots := Dots.new()
		dots.visual_variant = variant
		root.add_child(dots)
		dots.set_target(target)
		await process_frame
		var visual_root := dots.get_child(0) as Node3D
		var bounds := _mesh_bounds_in(visual_root, dots)
		_assert(
			bounds.size.y >= 0.85 and bounds.size.y <= 1.25,
			"Dots variant %s should be compact beside Sam (measured %.3fm)"
			% [Dots.VisualVariant.keys()[variant], bounds.size.y],
		)
		_assert(
			absf(dots.follow_offset.y) >= 0.4 and absf(dots.follow_offset.y) <= 0.8,
			"Dots should float at a chest-height follow offset",
		)
		_assert(
			Vector2(dots.follow_offset.x, dots.follow_offset.z).length() <= 1.5,
			"Dots should remain within a close companion offset",
		)
		_assert(
			dots.find_children("*", "CollisionShape3D", true, false).is_empty(),
			"Dots must remain visual-only and non-blocking",
		)
		dots.queue_free()
	await process_frame
	target.queue_free()
	await process_frame


func _mesh_bounds_in(node: Node3D, relative_to: Node3D) -> AABB:
	var found := false
	var result := AABB()
	var inverse := relative_to.global_transform.affine_inverse()
	var meshes: Array[Node] = []
	if node is MeshInstance3D:
		meshes.append(node)
	meshes.append_array(node.find_children("*", "MeshInstance3D", true, false))
	for child in meshes:
		var mesh_instance := child as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var bounds := mesh_instance.get_aabb()
		var transform := inverse * mesh_instance.global_transform
		for corner_index in range(8):
			var corner := bounds.position + Vector3(
				bounds.size.x if (corner_index & 1) != 0 else 0.0,
				bounds.size.y if (corner_index & 2) != 0 else 0.0,
				bounds.size.z if (corner_index & 4) != 0 else 0.0,
			)
			var point := transform * corner
			if found:
				result = result.expand(point)
			else:
				result = AABB(point, Vector3.ZERO)
				found = true
	return result


func _assert(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
