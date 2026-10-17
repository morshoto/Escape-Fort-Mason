extends SceneTree

const PLAYER_SCENE_PATH := "res://player/player.tscn"
const SKIN_SCENE_PATH := "res://player/sam/sam_skin.tscn"
const ROLLBACK_SCENE_PATH := "res://player/gdbot/gdbot_skin.tscn"
const ASSET_DOC_PATH := "res://docs/ASSETS.md"
const REFERENCE_DOC_PATH := "res://docs/sam-reference.md"
const QUATERNIUS_MODEL_PATH := "res://player/sam/quaternius/Superhero_Male_FullBody.gltf"
const QUATERNIUS_HAIR_PATH := "res://player/sam/quaternius/Hair_SimpleParted.gltf"
const REQUIRED_ANIMATIONS := ["idle", "walk", "run", "jump", "fall", "attack"]
const REQUIRED_METHODS := ["idle", "move", "jump", "fall", "attack"]
const REQUIRED_HUMANOID_BONES := ["Head", "clavicle_l", "clavicle_r", "upperarm_l", "upperarm_r", "thigh_l", "thigh_r"]

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _check_scene_contract()
	await _check_rollback_skin()
	_check_player_wiring()
	_check_asset_provenance()
	if _failed:
		quit(1)
		return
	print("player skin contract: PASS")
	quit()


func _check_scene_contract() -> void:
	var packed_skin := load(SKIN_SCENE_PATH) as PackedScene
	_require(packed_skin != null, "Sam skin scene is loadable")
	if packed_skin == null:
		return

	var skin := packed_skin.instantiate()
	root.add_child(skin)
	await process_frame

	for method_name in REQUIRED_METHODS:
		_require(skin.has_method(method_name), "skin exposes %s()" % method_name)

	_require(skin.has_node("AnimationTree"), "skin has an AnimationTree")
	var animation_tree := skin.get_node("AnimationTree") as AnimationTree
	_require(animation_tree.active, "skin AnimationTree is active")
	for animation_name in REQUIRED_ANIMATIONS:
		_require(animation_tree.get_animation(animation_name) != null, "skin has %s animation" % animation_name)

	var skeleton := skin.find_child("Skeleton3D", true, false) as Skeleton3D
	_require(skeleton != null, "skin has the imported Humanoid Skeleton3D")
	if skeleton == null:
		return
	for bone_name in REQUIRED_HUMANOID_BONES:
		_require(skeleton.find_bone(bone_name) != -1, "skin has %s Humanoid bone" % bone_name)
	_require(skeleton.get_bone_pose_scale(skeleton.find_bone("Head")).x > 1.0, "natural proportions enlarge the head")
	_require(skeleton.get_bone_pose_scale(skeleton.find_bone("clavicle_l")).x < 1.0, "natural proportions narrow the shoulders")
	var animation_player := skin.get_node("AnimationPlayer") as AnimationPlayer
	_require(_animation_targets_skeleton(animation_player.get_animation("humanoid_walk")), "walk retarget preview targets the imported Skeleton3D")
	_require(_animation_targets_skeleton(animation_player.get_animation("humanoid_run")), "run retarget preview targets the imported Skeleton3D")

	for visual_name in ["Face", "Hair", "Top", "Jacket", "QuaterniusModel"]:
		_require(skin.has_node("SamModel/%s" % visual_name), "skin has %s visual marker" % visual_name)
	for garment_name in ["Jacket/JacketShell", "Jacket/JacketFrontPanel"]:
		var garment := skin.get_node("SamModel/%s" % garment_name) as MeshInstance3D
		_require(garment != null and garment.mesh != null, "skin has fitted %s garment mesh" % garment_name)

	skin.walk_run_blending = 0.75
	_require(is_equal_approx(skin.walk_run_blending, 0.75), "walk/run blend is writable")
	skin.idle()
	await process_frame
	skin.move()
	for _frame in range(8):
		await process_frame
	var playback := animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback
	_require(playback != null, "skin has a state machine playback")
	_require(playback.get_current_node() == "Move", "move enters Move state")
	var arm_bone := skeleton.find_bone("upperarm_l")
	var arm_pose_before := skeleton.get_bone_pose_rotation(arm_bone)
	for _frame in range(12):
		await process_frame
	var arm_pose_after := skeleton.get_bone_pose_rotation(arm_bone)
	_require(not arm_pose_before.is_equal_approx(arm_pose_after), "Move animates the visible Humanoid arm")


func _check_player_wiring() -> void:
	var player_text := FileAccess.get_file_as_string(PLAYER_SCENE_PATH)
	_require(player_text.contains("res://player/sam/sam_skin.tscn"), "player uses Sam skin scene")
	_require(not player_text.contains("res://player/gdbot/gdbot_skin.tscn"), "player no longer uses GDbot skin")


func _check_rollback_skin() -> void:
	var packed_skin := load(ROLLBACK_SCENE_PATH) as PackedScene
	_require(packed_skin != null, "original GDbot skin remains loadable")
	if packed_skin == null:
		return
	var skin := packed_skin.instantiate()
	root.add_child(skin)
	await process_frame
	_require(skin.has_method("idle"), "original GDbot skin keeps CharacterSkin contract")
	_require(skin.has_node("AnimationTree"), "original GDbot skin keeps AnimationTree")


func _check_asset_provenance() -> void:
	var asset_doc := FileAccess.get_file_as_string(ASSET_DOC_PATH)
	var reference_doc := FileAccess.get_file_as_string(REFERENCE_DOC_PATH)
	_require(FileAccess.file_exists(QUATERNIUS_MODEL_PATH), "Quaternius male model is included")
	_require(FileAccess.file_exists(QUATERNIUS_HAIR_PATH), "Quaternius parted hair is included")
	_require(asset_doc.contains("Quaternius Universal Base Characters"), "asset provenance names Quaternius")
	_require(asset_doc.contains("CC0"), "asset provenance records the CC0 license")
	_require(asset_doc.contains("Sam Altman"), "asset provenance records the visual brief")
	_require(reference_doc.to_lower().contains("short-to-medium dark hair"), "reference brief records the hair cue")
	_require(asset_doc.contains("muted blue"), "asset provenance records the clothing cue")
	_require(asset_doc.to_lower().contains("no reference photos"), "asset provenance excludes reference photos")
	_require(reference_doc.contains("forum.openai.com"), "reference brief includes the Forum source")
	_require(reference_doc.contains("youtube.com/watch?v=Wpxv-8nG8ec"), "reference brief includes Town Hall")
	_require(reference_doc.contains("youtube.com/watch?v=hS1YqcewH0c"), "reference brief includes DevDay")
	_require(reference_doc.contains("openai.com/index/sam-altman-un-security-council-remarks"), "reference brief includes UN remarks")


func _require(condition: bool, description: String) -> void:
	if condition:
		return
	_failed = true
	push_error("FAIL: %s" % description)


func _animation_targets_skeleton(animation: Animation) -> bool:
	for track_index in animation.get_track_count():
		if str(animation.track_get_path(track_index)).contains("Skeleton3D:bones/"):
			return true
	return false
