extends SceneTree

const CAPTURE_SIZE := Vector2i(1280, 720)
const STAGE_PATH := "res://level/fort_mason.tscn"
const OUTPUT_PATH := "res://docs/screenshots/gameplay-polish/native/north-seawall-containment.png"


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	root.size = CAPTURE_SIZE
	var stage := (load(STAGE_PATH) as PackedScene).instantiate() as Node3D
	root.add_child(stage)
	var sam := stage.get_node("Sam") as CharacterBody3D
	for _frame in range(60):
		await physics_frame
	sam.global_position = Vector3(-8.0, 0.0, 22.0)
	var camera := Camera3D.new()
	camera.fov = 50.0
	camera.position = Vector3(-8.0, 5.0, 13.0)
	stage.add_child(camera)
	camera.look_at(Vector3(-8.0, 1.0, 25.3), Vector3.UP)
	camera.current = true
	for _frame in range(10):
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_PATH.get_base_dir()))
	var image := root.get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	if error != OK:
		push_error("Failed to save north seawall capture: %s" % error)
	stage.queue_free()
	await process_frame
	quit(0 if error == OK else 1)
