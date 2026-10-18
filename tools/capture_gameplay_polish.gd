extends SceneTree

const CAPTURE_SIZE := Vector2i(1280, 720)
const STAGE_PATH := "res://level/fort_mason.tscn"

var _viewport: Viewport
var _stage: Node3D
var _sam: CharacterBody3D
var _dots: Node3D
var _output_dir := ""


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	root.size = CAPTURE_SIZE
	var phase := "before"
	var arguments := OS.get_cmdline_user_args()
	if not arguments.is_empty() and arguments[0] in ["before", "after"]:
		phase = arguments[0]
	_output_dir = "res://docs/screenshots/gameplay-polish/%s" % phase
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

	_viewport = root

	var scene := load(STAGE_PATH) as PackedScene
	if scene == null:
		push_error("Unable to load Fort Mason for gameplay-polish capture")
		quit(1)
		return
	_stage = scene.instantiate() as Node3D
	root.add_child(_stage)
	_sam = _stage.get_node("Sam") as CharacterBody3D
	_dots = _stage.get_node("Dots") as Node3D

	await _wait_for_render()
	_save_view("interaction-prompt")
	_save_view("outdoor")
	_save_view("sam-and-dots")

	_sam.global_position = Vector3(0.0, 1.0, 4.0)
	await _wait_for_render()
	_save_view("warehouse-entrance")

	_sam.global_position = Vector3(0.0, 1.0, -12.0)
	await _wait_for_render()
	_save_view("warehouse-interior")
	_dots.show_message("調査を始めよう。")
	await _wait_for_render()
	_save_view("dialogue")

	print("Gameplay-polish captures saved to %s" % _output_dir)
	_stage.queue_free()
	await process_frame
	quit(0)


func _wait_for_render() -> void:
	for _frame in range(30):
		await process_frame
	await RenderingServer.frame_post_draw


func _save_view(name: String) -> void:
	var image := _viewport.get_texture().get_image()
	var path := "%s/%s.png" % [_output_dir, name]
	var error := image.save_png(path)
	if error != OK:
		push_error("Failed to save gameplay-polish capture %s: %s" % [path, error])
