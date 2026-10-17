@tool
extends CharacterSkin

## Quaternius-based, stylized Sam Altman character skin.

const BODY_SHADER := preload("res://player/sam/sam_body_shader.gdshader")
const BODY_TEXTURE := preload("res://player/sam/quaternius/T_Superhero_Male_Dark.png")
const HUMANOID_ANIMATIONS := {
	"idle": {
		"Head": [[0.0, Vector3.ZERO], [1.2, Vector3(0.0, 1.5, 0.0)], [2.4, Vector3.ZERO]],
		"upperarm_l": [[0.0, Vector3(0.0, 0.0, 3.0)], [1.2, Vector3(0.0, 0.0, 1.0)], [2.4, Vector3(0.0, 0.0, 3.0)]],
		"upperarm_r": [[0.0, Vector3(0.0, 0.0, -3.0)], [1.2, Vector3(0.0, 0.0, -1.0)], [2.4, Vector3(0.0, 0.0, -3.0)]],
	},
	"walk": {
		"upperarm_l": [[0.0, Vector3(-24.0, 0.0, 3.0)], [0.4, Vector3(24.0, 0.0, 3.0)], [0.8, Vector3(-24.0, 0.0, 3.0)]],
		"upperarm_r": [[0.0, Vector3(24.0, 0.0, -3.0)], [0.4, Vector3(-24.0, 0.0, -3.0)], [0.8, Vector3(24.0, 0.0, -3.0)]],
		"thigh_l": [[0.0, Vector3(28.0, 0.0, 0.0)], [0.4, Vector3(-28.0, 0.0, 0.0)], [0.8, Vector3(28.0, 0.0, 0.0)]],
		"thigh_r": [[0.0, Vector3(-28.0, 0.0, 0.0)], [0.4, Vector3(28.0, 0.0, 0.0)], [0.8, Vector3(-28.0, 0.0, 0.0)]],
	},
	"run": {
		"upperarm_l": [[0.0, Vector3(-38.0, 0.0, 5.0)], [0.275, Vector3(38.0, 0.0, 5.0)], [0.55, Vector3(-38.0, 0.0, 5.0)]],
		"upperarm_r": [[0.0, Vector3(38.0, 0.0, -5.0)], [0.275, Vector3(-38.0, 0.0, -5.0)], [0.55, Vector3(38.0, 0.0, -5.0)]],
		"thigh_l": [[0.0, Vector3(38.0, 0.0, 0.0)], [0.275, Vector3(-38.0, 0.0, 0.0)], [0.55, Vector3(38.0, 0.0, 0.0)]],
		"thigh_r": [[0.0, Vector3(-38.0, 0.0, 0.0)], [0.275, Vector3(38.0, 0.0, 0.0)], [0.55, Vector3(-38.0, 0.0, 0.0)]],
	},
	"jump": {
		"upperarm_l": [[0.0, Vector3(0.0, 0.0, 3.0)], [0.45, Vector3(-28.0, 0.0, 3.0)]],
		"upperarm_r": [[0.0, Vector3(0.0, 0.0, -3.0)], [0.45, Vector3(-28.0, 0.0, -3.0)]],
	},
	"fall": {
		"upperarm_l": [[0.0, Vector3(-18.0, 0.0, 30.0)], [0.3, Vector3(-12.0, 0.0, 30.0)], [0.6, Vector3(-18.0, 0.0, 30.0)]],
		"upperarm_r": [[0.0, Vector3(-18.0, 0.0, -30.0)], [0.3, Vector3(-12.0, 0.0, -30.0)], [0.6, Vector3(-18.0, 0.0, -30.0)]],
	},
	"attack": {
		"upperarm_r": [[0.0, Vector3(0.0, 0.0, -3.0)], [0.12, Vector3(-75.0, 0.0, -3.0)], [0.35, Vector3(-15.0, 0.0, -3.0)]],
	},
}

var _humanoid_skeleton: Skeleton3D
var _base_humanoid_rotations := {}
var _motion_elapsed := 0.0

func _ready() -> void:
	super._ready()
	process_priority = 100
	var skeleton := _find_skeleton()
	if skeleton != null:
		_humanoid_skeleton = skeleton
		_apply_natural_proportions(skeleton)
		_relax_quaternius_pose(skeleton)
		_cache_base_humanoid_rotations(skeleton)
		_install_humanoid_animation_previews(skeleton)
		_build_fitted_jacket_mesh()
	_apply_stylized_materials()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _humanoid_skeleton == null:
		return
	_motion_elapsed += delta
	_retarget_active_state_to_humanoid()


func _apply_stylized_materials() -> void:
	var model := get_node("SamModel/QuaterniusModel")
	var body := model.find_child("SuperHero_Male", true, false) as MeshInstance3D
	if body != null:
		var body_material := ShaderMaterial.new()
		body_material.shader = BODY_SHADER
		body_material.set_shader_parameter("base_texture", BODY_TEXTURE)
		body.material_override = body_material

	var hair_material := StandardMaterial3D.new()
	hair_material.albedo_color = Color("#201911")
	hair_material.roughness = 0.88
	for hair_mesh in get_node("SamModel/Hair").find_children("*", "MeshInstance3D", true, false):
		hair_mesh.material_override = hair_material


func _build_fitted_jacket_mesh() -> void:
	var front_top_left := Vector3(-0.17, 1.46, 0.08)
	var front_top_right := Vector3(0.17, 1.46, 0.08)
	var front_bottom_right := Vector3(0.14, 1.12, 0.08)
	var front_bottom_left := Vector3(-0.14, 1.12, 0.08)
	var back_top_left := Vector3(-0.17, 1.46, -0.02)
	var back_top_right := Vector3(0.17, 1.46, -0.02)
	var back_bottom_right := Vector3(0.14, 1.12, -0.02)
	var back_bottom_left := Vector3(-0.14, 1.12, -0.02)
	var vertices := [
		front_top_left, front_top_right, front_bottom_right, front_bottom_left,
		back_top_left, back_top_right, back_bottom_right, back_bottom_left,
	]
	var triangles := [
		0, 2, 1, 0, 3, 2,
		4, 5, 6, 4, 6, 7,
		0, 5, 4, 0, 1, 5,
		1, 6, 5, 1, 2, 6,
		2, 7, 6, 2, 3, 7,
		3, 4, 7, 3, 0, 4,
	]
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface_tool.set_material(jacket_shell_material())
	for vertex_index in triangles:
		surface_tool.set_uv(Vector2.ZERO)
		surface_tool.add_vertex(vertices[vertex_index])
	surface_tool.index()
	surface_tool.generate_normals()
	var jacket_mesh := surface_tool.commit()
	var jacket_shell := get_node("SamModel/Jacket/JacketShell") as MeshInstance3D
	if jacket_shell != null:
		jacket_shell.position = Vector3.ZERO
		jacket_shell.mesh = jacket_mesh


func jacket_shell_material() -> Material:
	var jacket_shell := get_node("SamModel/Jacket/JacketShell") as MeshInstance3D
	return jacket_shell.material_override if jacket_shell != null else null


func _find_skeleton() -> Skeleton3D:
	return get_node("SamModel/QuaterniusModel").find_child("Skeleton3D", true, false) as Skeleton3D


func _apply_natural_proportions(skeleton: Skeleton3D) -> void:
	_set_bone_scale(skeleton, "Head", Vector3(1.08, 1.08, 1.08))
	_set_bone_scale(skeleton, "clavicle_l", Vector3(0.78, 0.9, 0.84))
	_set_bone_scale(skeleton, "clavicle_r", Vector3(0.78, 0.9, 0.84))
	_set_bone_scale(skeleton, "upperarm_l", Vector3(0.86, 0.9, 0.86))
	_set_bone_scale(skeleton, "upperarm_r", Vector3(0.86, 0.9, 0.86))
	_set_bone_scale(skeleton, "thigh_l", Vector3(0.94, 0.96, 0.94))
	_set_bone_scale(skeleton, "thigh_r", Vector3(0.94, 0.96, 0.94))


func _relax_quaternius_pose(skeleton: Skeleton3D) -> void:
	_set_bone_roll(skeleton, "upperarm_l", -90.0)
	_set_bone_roll(skeleton, "upperarm_r", -90.0)


func _cache_base_humanoid_rotations(skeleton: Skeleton3D) -> void:
	for bone_name in ["upperarm_l", "upperarm_r", "thigh_l", "thigh_r"]:
		var bone_index := skeleton.find_bone(bone_name)
		if bone_index != -1:
			_base_humanoid_rotations[bone_name] = skeleton.get_bone_pose_rotation(bone_index).get_euler()


func _install_humanoid_animation_previews(skeleton: Skeleton3D) -> void:
	var animation_player := get_node("AnimationPlayer") as AnimationPlayer
	var library := animation_player.get_animation_library("")
	if library == null:
		return
	var skeleton_path := get_path_to(skeleton)
	for animation_name in HUMANOID_ANIMATIONS:
		var source_animation := animation_player.get_animation(animation_name)
		if source_animation == null:
			continue
		var preview_name := "humanoid_%s" % animation_name
		if library.has_animation(preview_name):
			continue
		var animation := Animation.new()
		animation.resource_name = preview_name
		animation.length = source_animation.length
		for bone_name in HUMANOID_ANIMATIONS[animation_name]:
			var bone_index := skeleton.find_bone(bone_name)
			if bone_index == -1:
				continue
			var track_path := NodePath("%s:bones/%d/rotation" % [skeleton_path, bone_index])
			if _has_animation_track(animation, track_path):
				continue
			var track_index := animation.add_track(Animation.TYPE_VALUE)
			animation.track_set_path(track_index, track_path)
			animation.track_set_interpolation_type(track_index, Animation.INTERPOLATION_LINEAR)
			var base_rotation := skeleton.get_bone_pose_rotation(bone_index)
			var rest_rotation := skeleton.get_bone_rest(bone_index).basis.get_rotation_quaternion()
			for key in HUMANOID_ANIMATIONS[animation_name][bone_name]:
				animation.track_insert_key(
					track_index,
					key[0],
					_rotation_with_offset(base_rotation, rest_rotation, key[1])
				)
		library.add_animation(preview_name, animation)


func _retarget_active_state_to_humanoid() -> void:
	if _humanoid_skeleton == null:
		return
	var playback := _animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback
	if playback == null:
		return
	var state := playback.get_current_node()
	var phase := _motion_elapsed * (TAU / (0.8 if state == "Move" else 2.4))
	match state:
		"Move":
			var swing := sin(phase) * lerpf(24.0, 38.0, walk_run_blending)
			_set_humanoid_rotation("upperarm_l", _base_rotation_x("upperarm_l") + swing)
			_set_humanoid_rotation("upperarm_r", _base_rotation_x("upperarm_r") - swing)
			_set_humanoid_rotation("thigh_l", _base_rotation_x("thigh_l") + sin(phase) * lerpf(28.0, 38.0, walk_run_blending))
			_set_humanoid_rotation("thigh_r", _base_rotation_x("thigh_r") - sin(phase) * lerpf(28.0, 38.0, walk_run_blending))
		"Jump":
			_set_humanoid_rotation("upperarm_l", _base_rotation_x("upperarm_l") - 28.0)
			_set_humanoid_rotation("upperarm_r", _base_rotation_x("upperarm_r") - 28.0)
		"Fall":
			_set_humanoid_rotation("upperarm_l", _base_rotation_x("upperarm_l") - 18.0)
			_set_humanoid_rotation("upperarm_r", _base_rotation_x("upperarm_r") - 18.0)
		"Idle", "Start", _:
			var breath := sin(phase) * 2.0
			_set_humanoid_rotation("upperarm_l", _base_rotation_x("upperarm_l") + breath)
			_set_humanoid_rotation("upperarm_r", _base_rotation_x("upperarm_r") - breath)
			_set_humanoid_rotation("thigh_l", _base_rotation_x("thigh_l"))
			_set_humanoid_rotation("thigh_r", _base_rotation_x("thigh_r"))


func _base_rotation_x(bone_name: String) -> float:
	return rad_to_deg((_base_humanoid_rotations.get(bone_name, Vector3.ZERO) as Vector3).x)


func _set_humanoid_rotation(bone_name: String, x_degrees: float) -> void:
	var bone_index := _humanoid_skeleton.find_bone(bone_name)
	if bone_index == -1:
		return
	_humanoid_skeleton.set_bone_pose_rotation(
		bone_index,
		Quaternion.from_euler(Vector3(deg_to_rad(x_degrees), 0.0, 0.0))
	)


func _has_animation_track(animation: Animation, track_path: NodePath) -> bool:
	for track_index in animation.get_track_count():
		if animation.track_get_path(track_index) == track_path:
			return true
	return false


func _rotation_with_offset(base_rotation: Quaternion, rest_rotation: Quaternion, rotation_degrees: Vector3) -> Quaternion:
	var desired_rotation := base_rotation * Quaternion.from_euler(rotation_degrees * PI / 180.0)
	return rest_rotation.inverse() * desired_rotation


func _set_bone_scale(skeleton: Skeleton3D, bone_name: String, scale: Vector3) -> void:
	var bone_index := skeleton.find_bone(bone_name)
	if bone_index == -1:
		return
	skeleton.set_bone_pose_scale(bone_index, scale)


func _set_bone_roll(skeleton: Skeleton3D, bone_name: String, angle_degrees: float) -> void:
	var bone_index := skeleton.find_bone(bone_name)
	if bone_index == -1:
		return
	skeleton.set_bone_pose_rotation(
		bone_index,
		Quaternion.from_euler(Vector3(deg_to_rad(angle_degrees), 0.0, 0.0))
	)
