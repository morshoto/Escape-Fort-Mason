class_name DotsVisuals
extends RefCounted

const ALFRED_YELLOW := Color("#f4c33b")
const BLUE := Color("#2788e8")
const GREEN := Color("#9bd63b")
const PINK := Color("#f26ca7")
const GLASSES_BLACK := Color("#111317")
const BOW_TIE_BLACK := Color("#17191f")
const EYE_WHITE := Color("#f4f7ff")


static func build(parent: Node3D, variant: int) -> Node3D:
	match variant:
		1:
			return _build_blue(parent)
		2:
			return _build_green(parent)
		3:
			return _build_pink(parent)
		_:
			return _build_alfred(parent)


static func variant_name(variant: int) -> String:
	match variant:
		1:
			return "blue"
		2:
			return "green"
		3:
			return "pink"
		_:
			return "alfred"


static func _build_alfred(parent: Node3D) -> Node3D:
	var visual_root := _make_visual_root(parent, "AlfredVisual")
	var body := MeshInstance3D.new()
	body.name = "Body"
	body.mesh = _create_body_mesh(
		PackedVector2Array([
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
		]),
		PackedFloat32Array([-0.46, -0.30, 0.25, 0.40]),
		PackedFloat32Array([0.80, 1.0, 1.0, 0.80]),
	)
	var body_material := _make_material(ALFRED_YELLOW, 0.9, true)
	body.material_override = body_material
	visual_root.add_child(body)

	_build_alfred_glasses(visual_root)
	_build_bow_tie(visual_root)
	return visual_root


static func _build_blue(parent: Node3D) -> Node3D:
	var visual_root := _make_visual_root(parent, "BlueVisual")
	var cloud := Node3D.new()
	cloud.name = "Cloud"
	visual_root.add_child(cloud)
	var lobe_mesh := SphereMesh.new()
	lobe_mesh.radius = 0.46
	lobe_mesh.height = 0.86
	lobe_mesh.radial_segments = 16
	lobe_mesh.rings = 8
	var body_material := _make_material(BLUE, 0.88, true)
	for lobe_data in [
		["CenterLobe", Vector3(0.0, 0.78, 0.0), Vector3(1.08, 1.08, 0.92)],
		["LeftLobe", Vector3(-0.42, 0.72, 0.0), Vector3(0.88, 0.92, 0.85)],
		["RightLobe", Vector3(0.42, 0.72, 0.0), Vector3(0.88, 0.92, 0.85)],
		["TopLobe", Vector3(-0.16, 1.16, 0.0), Vector3(0.82, 0.80, 0.82)],
		["LowerLobe", Vector3(0.0, 0.34, 0.0), Vector3(0.82, 0.72, 0.80)],
	]:
		var lobe := MeshInstance3D.new()
		lobe.name = lobe_data[0]
		lobe.mesh = lobe_mesh
		lobe.material_override = body_material
		lobe.position = lobe_data[1]
		lobe.scale = lobe_data[2]
		cloud.add_child(lobe)

	var beret := Node3D.new()
	beret.name = "Beret"
	visual_root.add_child(beret)
	var brim := MeshInstance3D.new()
	brim.name = "Brim"
	var brim_mesh := CylinderMesh.new()
	brim_mesh.top_radius = 0.40
	brim_mesh.bottom_radius = 0.46
	brim_mesh.height = 0.08
	brim_mesh.radial_segments = 20
	brim.mesh = brim_mesh
	brim.material_override = _make_material(GLASSES_BLACK, 0.52)
	brim.position = Vector3(-0.02, 1.48, 0.02)
	brim.rotation.z = -0.12
	beret.add_child(brim)
	var crown := MeshInstance3D.new()
	crown.name = "Crown"
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 0.35
	crown_mesh.height = 0.25
	crown_mesh.radial_segments = 16
	crown_mesh.rings = 8
	crown.mesh = crown_mesh
	crown.material_override = _make_material(GLASSES_BLACK, 0.52)
	crown.position = Vector3(-0.07, 1.58, 0.02)
	crown.scale = Vector3(1.15, 0.64, 0.95)
	beret.add_child(crown)

	var eye_mesh := BoxMesh.new()
	eye_mesh.size = Vector3(0.10, 0.27, 0.045)
	var eye_material := _make_material(GLASSES_BLACK, 0.45)
	for eye_data in [
		["LeftEye", Vector3(-0.18, 0.84, -0.48), 0.08],
		["RightEye", Vector3(0.18, 0.84, -0.48), -0.08],
	]:
		var eye := MeshInstance3D.new()
		eye.name = eye_data[0]
		eye.mesh = eye_mesh
		eye.material_override = eye_material
		eye.position = eye_data[1]
		eye.rotation.z = eye_data[2]
		visual_root.add_child(eye)
	return visual_root


static func _build_green(parent: Node3D) -> Node3D:
	var visual_root := _make_visual_root(parent, "GreenVisual")
	var body := MeshInstance3D.new()
	body.name = "Body"
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.76
	body_mesh.height = 1.52
	body_mesh.radial_segments = 20
	body_mesh.rings = 10
	body.mesh = body_mesh
	body.scale = Vector3(1.0, 1.0, 0.78)
	body.position = Vector3(0.0, 0.78, 0.0)
	body.material_override = _make_material(GREEN, 0.88, true)
	visual_root.add_child(body)

	var white_mesh := SphereMesh.new()
	white_mesh.radius = 0.20
	white_mesh.height = 0.40
	white_mesh.radial_segments = 16
	white_mesh.rings = 8
	var pupil_mesh := SphereMesh.new()
	pupil_mesh.radius = 0.09
	pupil_mesh.height = 0.18
	pupil_mesh.radial_segments = 12
	pupil_mesh.rings = 6
	for eye_data in [
		["Left", -0.23],
		["Right", 0.23],
	]:
		var eye_white := MeshInstance3D.new()
		eye_white.name = "%sEyeWhite" % eye_data[0]
		eye_white.mesh = white_mesh
		eye_white.material_override = _make_material(EYE_WHITE, 0.42)
		eye_white.position = Vector3(eye_data[1], 1.43, -0.18)
		eye_white.scale = Vector3(1.0, 1.12, 0.82)
		visual_root.add_child(eye_white)

		var pupil := MeshInstance3D.new()
		pupil.name = "%sPupil" % eye_data[0]
		pupil.mesh = pupil_mesh
		pupil.material_override = _make_material(GLASSES_BLACK, 0.45)
		pupil.position = Vector3(eye_data[1], 1.44, -0.36)
		visual_root.add_child(pupil)
	return visual_root


static func _build_pink(parent: Node3D) -> Node3D:
	var visual_root := _make_visual_root(parent, "PinkVisual")
	var heart := MeshInstance3D.new()
	heart.name = "HeartBody"
	heart.mesh = _create_body_mesh(
		PackedVector2Array([
			Vector2(0.0, 1.40),
			Vector2(0.22, 1.57),
			Vector2(0.48, 1.52),
			Vector2(0.68, 1.34),
			Vector2(0.74, 1.06),
			Vector2(0.66, 0.76),
			Vector2(0.46, 0.48),
			Vector2(0.0, 0.02),
			Vector2(-0.46, 0.48),
			Vector2(-0.66, 0.76),
			Vector2(-0.74, 1.06),
			Vector2(-0.68, 1.34),
			Vector2(-0.48, 1.52),
			Vector2(-0.22, 1.57),
		]),
		PackedFloat32Array([-0.40, -0.26, 0.20, 0.34]),
		PackedFloat32Array([0.80, 1.0, 1.0, 0.80]),
	)
	heart.material_override = _make_material(PINK, 0.88, true)
	visual_root.add_child(heart)
	_build_sunglasses(visual_root)
	return visual_root


static func _build_alfred_glasses(parent: Node3D) -> void:
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


static func _build_sunglasses(parent: Node3D) -> void:
	var sunglasses := Node3D.new()
	sunglasses.name = "Sunglasses"
	parent.add_child(sunglasses)
	var frame_mesh := TorusMesh.new()
	frame_mesh.inner_radius = 0.16
	frame_mesh.outer_radius = 0.21
	frame_mesh.rings = 24
	frame_mesh.ring_segments = 10
	var black_material := _make_material(GLASSES_BLACK, 0.28)
	var lens_mesh := CylinderMesh.new()
	lens_mesh.top_radius = 0.18
	lens_mesh.bottom_radius = 0.18
	lens_mesh.height = 0.025
	lens_mesh.radial_segments = 24
	for side_data in [
		["Left", -0.25],
		["Right", 0.25],
	]:
		var frame := MeshInstance3D.new()
		frame.name = "%sFrame" % side_data[0]
		frame.mesh = frame_mesh
		frame.material_override = black_material
		frame.position = Vector3(side_data[1], 1.08, -0.54)
		frame.rotation.x = PI / 2.0
		sunglasses.add_child(frame)

		var lens := MeshInstance3D.new()
		lens.name = "%sLens" % side_data[0]
		lens.mesh = lens_mesh
		lens.material_override = black_material
		lens.position = Vector3(side_data[1], 1.08, -0.55)
		lens.rotation.x = PI / 2.0
		sunglasses.add_child(lens)

	var bridge := MeshInstance3D.new()
	bridge.name = "Bridge"
	var bridge_mesh := BoxMesh.new()
	bridge_mesh.size = Vector3(0.18, 0.045, 0.05)
	bridge.mesh = bridge_mesh
	bridge.material_override = black_material
	bridge.position = Vector3(0.0, 1.08, -0.54)
	sunglasses.add_child(bridge)


static func _build_bow_tie(parent: Node3D) -> void:
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


static func _make_visual_root(parent: Node3D, name: String) -> Node3D:
	var visual_root := Node3D.new()
	visual_root.name = name
	visual_root.rotation.y = PI
	visual_root.scale = Vector3.ONE * 0.72
	parent.add_child(visual_root)
	return visual_root


static func _create_body_mesh(
	profile: PackedVector2Array,
	ring_depths: PackedFloat32Array,
	ring_scales: PackedFloat32Array,
) -> ArrayMesh:
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


static func _create_bow_wing_mesh(direction: float) -> ArrayMesh:
	var profile := PackedVector2Array([
		Vector2(0.0, 0.10),
		Vector2(0.42 * direction, 0.26),
		Vector2(0.52 * direction, 0.02),
		Vector2(0.42 * direction, -0.24),
		Vector2(0.0, -0.10),
	])
	return _create_extruded_profile_mesh(profile, 0.12)


static func _create_extruded_profile_mesh(profile: PackedVector2Array, depth: float) -> ArrayMesh:
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


static func _make_material(color: Color, roughness: float, emissive: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = 0.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emissive:
		material.emission_enabled = true
		material.emission = color * 0.35
		material.emission_energy_multiplier = 0.22
	return material
