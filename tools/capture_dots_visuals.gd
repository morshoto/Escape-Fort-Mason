extends SceneTree

const CAPTURE_SIZE := Vector2i(640, 640)
const CAPTURE_DIR := "res://docs/dots-screenshots"

var _viewport: SubViewport
var _camera: Camera3D


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	_viewport = SubViewport.new()
	_viewport.size = CAPTURE_SIZE
	_viewport.own_world_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)
	_setup_studio()
	var dots_scene := load("res://player/dots/dots.tscn") as PackedScene
	var dots := dots_scene.instantiate() as Node3D
	_viewport.add_child(dots)
	await _wait_for_render()

	for view in [
		["alfred-front", Vector3(0.0, 1.0, 4.4)],
		["alfred-45", Vector3(3.2, 1.0, 3.2)],
		["alfred-side", Vector3(4.4, 1.0, 0.0)],
		["alfred-back", Vector3(0.0, 1.0, -4.4)],
	]:
		_camera.position = view[1]
		_camera.look_at(Vector3(0.0, 0.82, 0.0))
		await _wait_for_render()
		_save_view(view[0])

	dots.queue_free()
	await process_frame
	_capture_gameplay()
	await _wait_for_render()
	_save_view("dots-with-sam")
	quit(0)


func _setup_studio() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#18243a")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#b9c7dc")
	environment.ambient_light_energy = 0.85
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	_viewport.add_child(world_environment)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-38.0, -28.0, 0.0)
	light.light_energy = 2.0
	light.shadow_enabled = false
	_viewport.add_child(light)

	var floor := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(12.0, 12.0)
	floor.mesh = floor_mesh
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("#5b6678")
	floor_material.roughness = 0.95
	floor.material_override = floor_material
	floor.position.y = -0.05
	_viewport.add_child(floor)

	_camera = Camera3D.new()
	_camera.fov = 42.0
	_camera.current = true
	_viewport.add_child(_camera)


func _capture_gameplay() -> void:
	var fort_scene := load("res://level/fort_mason.tscn") as PackedScene
	var fort := fort_scene.instantiate() as Node3D
	_viewport.add_child(fort)
	_camera.position = Vector3(-5.0, 4.0, 20.0)
	_camera.look_at(Vector3(0.0, 1.35, 12.0))


func _wait_for_render() -> void:
	await process_frame
	await process_frame
	await process_frame


func _save_view(name: String) -> void:
	var image: Image = _viewport.get_texture().get_image()
	image.save_png("%s/%s.png" % [CAPTURE_DIR, name])
