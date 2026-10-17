@tool
extends CharacterSkin

## Quaternius-based, stylized Sam Altman character skin.

const BODY_SHADER := preload("res://player/sam/sam_body_shader.gdshader")
const BODY_TEXTURE := preload("res://player/sam/quaternius/T_Superhero_Male_Dark.png")

func _ready() -> void:
	super._ready()
	_apply_stylized_materials()
	_relax_quaternius_pose()


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


func _relax_quaternius_pose() -> void:
	var model := get_node("SamModel/QuaterniusModel")
	var skeleton := model.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton == null:
		return

	_set_bone_roll(skeleton, "upperarm_l", -90.0)
	_set_bone_roll(skeleton, "upperarm_r", -90.0)


func _set_bone_roll(skeleton: Skeleton3D, bone_name: String, angle_degrees: float) -> void:
	var bone_index := skeleton.find_bone(bone_name)
	if bone_index == -1:
		return
	skeleton.set_bone_pose_rotation(
		bone_index,
		Quaternion.from_euler(Vector3(deg_to_rad(angle_degrees), 0.0, 0.0))
	)
