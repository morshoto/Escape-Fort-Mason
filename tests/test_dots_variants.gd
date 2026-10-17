extends SceneTree

const Dots = preload("res://player/dots/dots.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_all_visual_variants()
	await _test_variants_keep_common_follow_controller()
	await _test_gallery_scene()

	if _failures.is_empty():
		print("Dots variant tests passed")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)


func _test_all_visual_variants() -> void:
	var scene := load("res://player/dots/dots.tscn") as PackedScene
	_assert(scene != null, "Dots scene should be loadable for every variant")
	if scene == null:
		return

	var expected := [
		[Dots.VisualVariant.ALFRED, "AlfredVisual"],
		[Dots.VisualVariant.BLUE, "BlueVisual"],
		[Dots.VisualVariant.GREEN, "GreenVisual"],
		[Dots.VisualVariant.PINK, "PinkVisual"],
	]
	for variant_data in expected:
		var dots := scene.instantiate() as Dots
		dots.visual_variant = variant_data[0]
		root.add_child(dots)
		await process_frame
		_assert(
			dots.get_meta("visual_variant", "") == variant_data[1].trim_suffix("Visual").to_lower(),
			"variant metadata should identify %s" % variant_data[1],
		)
		_assert(
			dots.get_node_or_null(variant_data[1]) is Node3D,
			"variant should expose %s" % variant_data[1],
		)
		_assert(
			dots.find_children("*", "CollisionShape3D", true, false).is_empty(),
			"%s should remain visual-only" % variant_data[1],
		)
		if variant_data[0] == Dots.VisualVariant.BLUE:
			_assert(dots.get_node_or_null("BlueVisual/Cloud/CenterLobe") is MeshInstance3D, "Blue should have cloud lobes")
			_assert(dots.get_node_or_null("BlueVisual/Beret") is Node3D, "Blue should have a beret")
			_assert(dots.get_node_or_null("BlueVisual/LeftEye") is MeshInstance3D, "Blue should have a vertical eye")
		if variant_data[0] == Dots.VisualVariant.GREEN:
			_assert(dots.get_node_or_null("GreenVisual/LeftEyeWhite") is MeshInstance3D, "Green should have raised eye whites")
			_assert(dots.get_node_or_null("GreenVisual/LeftPupil") is MeshInstance3D, "Green should have black pupils")
		if variant_data[0] == Dots.VisualVariant.PINK:
			_assert(dots.get_node_or_null("PinkVisual/Sunglasses") is Node3D, "Pink should have sunglasses")
			_assert(dots.get_node_or_null("PinkVisual/HeartBody") is MeshInstance3D, "Pink should have a heart body")
		dots.queue_free()
		await process_frame


func _test_variants_keep_common_follow_controller() -> void:
	var scene := load("res://player/dots/dots.tscn") as PackedScene
	var target := CharacterBody3D.new()
	target.position = Vector3(4.0, 2.0, -7.0)
	target.rotation.y = PI / 2.0
	root.add_child(target)

	for variant in [Dots.VisualVariant.BLUE, Dots.VisualVariant.GREEN, Dots.VisualVariant.PINK]:
		var dots := scene.instantiate() as Dots
		dots.visual_variant = variant
		dots.bob_height = 0.0
		root.add_child(dots)
		dots.set_target(target)
		await process_frame
		_assert_vector_close(
			dots.global_position,
			dots.get_follow_target_position(),
			"variant %d should use the common follow spawn" % variant,
		)
		target.velocity = Vector3(0.0, 0.0, -2.0)
		_assert(dots.get_movement_state() == Dots.MovementState.WALK, "variant %d should use common movement state" % variant)
		dots.queue_free()
		await process_frame
	target.free()


func _test_gallery_scene() -> void:
	var scene := load("res://player/dots/dots_gallery.tscn") as PackedScene
	_assert(scene != null, "Dots Gallery scene should be loadable")
	if scene == null:
		return
	var gallery := scene.instantiate()
	root.add_child(gallery)
	await process_frame
	for variant_name in ["Blue", "Green", "Alfred", "Pink"]:
		_assert(gallery.get_node_or_null("Dots%s" % variant_name) is Dots, "gallery should include %s" % variant_name)
	_assert(gallery.get_node_or_null("GalleryCamera") is Camera3D, "gallery should provide a review camera")
	gallery.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _assert_vector_close(actual: Vector3, expected: Vector3, message: String) -> void:
	_assert(actual.distance_to(expected) < 0.001, "%s: %s != %s" % [message, actual, expected])
