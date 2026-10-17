class_name Dots
extends Node3D

const ALFRED_YELLOW := Color("#f4c33b")
const GLASSES_BLACK := Color("#111317")
const BOW_TIE_BLACK := Color("#17191f")

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
var _visuals_built := false


func _ready() -> void:
	_build_alfred_visuals()
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


func _build_alfred_visuals() -> void:
	if _visuals_built:
		return
	_visuals_built = true
	set_meta("visual_variant", "alfred")
	var visual_root := Node3D.new()
	visual_root.name = "AlfredVisual"
	visual_root.rotation.y = PI
	add_child(visual_root)

	var body := MeshInstance3D.new()
	body.name = "Body"
	body.mesh = _create_body_mesh()
	var body_material := _make_material(ALFRED_YELLOW, 0.9)
	body_material.emission_enabled = true
	body_material.emission = Color("#6b4d0f")
	body_material.emission_energy_multiplier = 0.22
	body.material_override = body_material
	visual_root.add_child(body)

	_build_glasses(visual_root)
	_build_bow_tie(visual_root)


func _build_glasses(parent: Node3D) -> void:
	var glasses := Node3D.new()
	glasses.name = "Glasses"
	parent.add_child(glasses)

	var frame_mesh := TorusMesh.new()
	frame_mesh.inner_radius = 0.13
	frame_mesh.outer_radius = 0.18
	frame_mesh.rings = 24
	frame_mesh.ring_segments = 10
	var frame_material := _make_material(GLASSES_BLACK, 0.42)
	for frame_data in [
		["LeftFrame", Vector3(-0.22, 1.12, -0.48)],
		["RightFrame", Vector3(0.22, 1.12, -0.48)],
	]:
		var frame := MeshInstance3D.new()
		frame.name = frame_data[0]
		frame.mesh = frame_mesh
		frame.material_override = frame_material
		frame.position = frame_data[1]
		frame.rotation.x = PI / 2.0
		glasses.add_child(frame)

	var eye_mesh := BoxMesh.new()
	eye_mesh.size = Vector3(0.13, 0.025, 0.025)
	var eye_material := _make_material(GLASSES_BLACK, 0.35)
	for eye_data in [
		["LeftEye", Vector3(-0.22, 1.12, -0.68), 0.12],
		["RightEye", Vector3(0.22, 1.12, -0.68), -0.12],
	]:
		var eye := MeshInstance3D.new()
		eye.name = eye_data[0]
		eye.mesh = eye_mesh
		eye.material_override = eye_material
		eye.position = eye_data[1]
		eye.rotation.z = eye_data[2]
		glasses.add_child(eye)

	var bridge := MeshInstance3D.new()
	bridge.name = "Bridge"
	var bridge_mesh := BoxMesh.new()
	bridge_mesh.size = Vector3(0.18, 0.04, 0.045)
	bridge.mesh = bridge_mesh
	bridge.material_override = frame_material
	bridge.position = Vector3(0.0, 1.12, -0.48)
	glasses.add_child(bridge)

	var temple_mesh := BoxMesh.new()
	temple_mesh.size = Vector3(0.035, 0.035, 0.36)
	for temple_data in [
		["LeftTemple", Vector3(-0.42, 1.12, -0.30)],
		["RightTemple", Vector3(0.42, 1.12, -0.30)],
	]:
		var temple := MeshInstance3D.new()
		temple.name = temple_data[0]
		temple.mesh = temple_mesh
		temple.material_override = frame_material
		temple.position = temple_data[1]
		glasses.add_child(temple)


func _build_bow_tie(parent: Node3D) -> void:
	var bow_tie := Node3D.new()
	bow_tie.name = "BowTie"
	parent.add_child(bow_tie)

	var bow_material := _make_material(BOW_TIE_BLACK, 0.5)
	for wing_data in [
		["LeftWing", -1.0],
		["RightWing", 1.0],
	]:
		var wing := MeshInstance3D.new()
		wing.name = wing_data[0]
		wing.mesh = _create_bow_wing_mesh(wing_data[1])
		wing.material_override = bow_material
		wing.position = Vector3(0.0, 0.52, -0.52)
		bow_tie.add_child(wing)

	var knot := MeshInstance3D.new()
	knot.name = "Knot"
	var knot_mesh := SphereMesh.new()
	knot_mesh.radius = 0.09
	knot_mesh.height = 0.16
	knot_mesh.radial_segments = 16
	knot_mesh.rings = 8
	knot.mesh = knot_mesh
	knot.material_override = bow_material
	knot.position = Vector3(0.0, 0.52, -0.56)
	bow_tie.add_child(knot)


func _create_body_mesh() -> ArrayMesh:
	var profile := PackedVector2Array([
		Vector2(0.04, 1.65),
		Vector2(0.32, 1.56),
		Vector2(0.60, 1.32),
		Vector2(0.82, 0.91),
		Vector2(0.85, 0.56),
		Vector2(0.70, 0.20),
		Vector2(0.32, 0.02),
		Vector2(-0.18, 0.0),
		Vector2(-0.58, 0.14),
		Vector2(-0.82, 0.46),
		Vector2(-0.78, 0.86),
		Vector2(-0.55, 1.30),
		Vector2(-0.26, 1.55),
	])
	var ring_depths := PackedFloat32Array([-0.46, -0.30, 0.25, 0.40])
	var ring_scales := PackedFloat32Array([0.80, 1.0, 1.0, 0.80])
	var rings: Array[Array] = []
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)

	for ring_index in range(ring_depths.size()):
		var ring: Array[Vector3] = []
		for point in profile:
			ring.append(Vector3(point.x * ring_scales[ring_index], point.y, ring_depths[ring_index]))
		rings.append(ring)

	for ring_index in range(rings.size() - 1):
		var current: Array = rings[ring_index]
		var next: Array = rings[ring_index + 1]
		for point_index in range(profile.size()):
			var next_point := (point_index + 1) % profile.size()
			surface.set_smooth_group(1)
			surface.add_vertex(current[point_index])
			surface.add_vertex(next[point_index])
			surface.add_vertex(next[next_point])
			surface.add_vertex(current[point_index])
			surface.add_vertex(next[next_point])
			surface.add_vertex(current[next_point])

	var front_center := Vector3(0.0, 0.78, ring_depths[0])
	var back_center := Vector3(0.0, 0.78, ring_depths[ring_depths.size() - 1])
	var front: Array = rings[0]
	var back: Array = rings[rings.size() - 1]
	for point_index in range(profile.size()):
		var next_point := (point_index + 1) % profile.size()
		surface.set_smooth_group(-1)
		surface.add_vertex(front_center)
		surface.add_vertex(front[next_point])
		surface.add_vertex(front[point_index])
		surface.add_vertex(back_center)
		surface.add_vertex(back[point_index])
		surface.add_vertex(back[next_point])

	surface.generate_normals()
	surface.index()
	return surface.commit()


func _create_bow_wing_mesh(direction: float) -> ArrayMesh:
	var profile := PackedVector2Array([
		Vector2(0.0, 0.10),
		Vector2(0.42 * direction, 0.26),
		Vector2(0.52 * direction, 0.02),
		Vector2(0.42 * direction, -0.24),
		Vector2(0.0, -0.10),
	])
	return _create_extruded_profile_mesh(profile, 0.12)


func _create_extruded_profile_mesh(profile: PackedVector2Array, depth: float) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var front: Array[Vector3] = []
	var back: Array[Vector3] = []
	for point in profile:
		front.append(Vector3(point.x, point.y, -depth / 2.0))
		back.append(Vector3(point.x, point.y, depth / 2.0))

	var front_center := Vector3.ZERO
	var back_center := Vector3.ZERO
	for point in profile:
		front_center += Vector3(point.x, point.y, -depth / 2.0)
		back_center += Vector3(point.x, point.y, depth / 2.0)
	front_center /= profile.size()
	back_center /= profile.size()

	for point_index in range(profile.size()):
		var next_point := (point_index + 1) % profile.size()
		surface.set_smooth_group(-1)
		surface.add_vertex(front_center)
		surface.add_vertex(front[next_point])
		surface.add_vertex(front[point_index])
		surface.add_vertex(back_center)
		surface.add_vertex(back[point_index])
		surface.add_vertex(back[next_point])
		surface.add_vertex(front[point_index])
		surface.add_vertex(back[point_index])
		surface.add_vertex(back[next_point])
		surface.add_vertex(front[point_index])
		surface.add_vertex(back[next_point])
		surface.add_vertex(front[next_point])

	surface.generate_normals()
	surface.index()
	return surface.commit()


func _make_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = 0.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
