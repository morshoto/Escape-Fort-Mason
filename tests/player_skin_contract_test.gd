extends SceneTree

const PLAYER_SCENE_PATH := "res://player/player.tscn"
const SKIN_SCENE_PATH := "res://player/sam/sam_skin.tscn"
const ROLLBACK_SCENE_PATH := "res://player/gdbot/gdbot_skin.tscn"
const ASSET_DOC_PATH := "res://docs/ASSETS.md"
const REQUIRED_ANIMATIONS := ["idle", "walk", "run", "jump", "fall", "attack"]
const REQUIRED_METHODS := ["idle", "move", "jump", "fall", "attack"]

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_scene_contract()
	_check_rollback_skin()
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

	for visual_name in ["Head", "Hair", "Hoodie", "Glasses"]:
		_require(skin.has_node("SamModel/%s" % visual_name), "skin has %s visual marker" % visual_name)

	skin.walk_run_blending = 0.75
	_require(is_equal_approx(skin.walk_run_blending, 0.75), "walk/run blend is writable")
	skin.idle()
	await process_frame
	skin.move()
	await process_frame
	var playback := animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback
	_require(playback != null, "skin has a state machine playback")
	_require(playback.get_current_node() == "Move", "move enters Move state")


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
	_require(asset_doc.contains("locally authored"), "asset provenance identifies local authorship")
	_require(asset_doc.contains("Godot primitive meshes"), "asset provenance identifies mesh source")
	_require(asset_doc.contains("No third-party"), "asset provenance rules out unknown third-party assets")


func _require(condition: bool, description: String) -> void:
	if condition:
		return
	_failed = true
	push_error("FAIL: %s" % description)
