extends SceneTree

const STAGE_PATH := "res://level/fort_mason.tscn"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := load(STAGE_PATH) as PackedScene
	_assert(scene != null, "Fort Mason should load for lighting checks")
	if scene == null:
		_finish()
		return
	var stage := scene.instantiate() as Node3D
	root.add_child(stage)
	await process_frame

	var environment := stage.get_node_or_null("WorldEnvironment") as WorldEnvironment
	_assert(environment != null and environment.environment != null, "Night environment should be configured")
	if environment != null and environment.environment != null:
		var ambient := environment.environment
		_assert(ambient.background_color.v < 0.2, "Background should retain a dark night sky")
		_assert(ambient.ambient_light_energy >= 0.55 and ambient.ambient_light_energy <= 0.85, "Ambient light should reveal characters without washing out night")
		_assert(ambient.ambient_light_source == Environment.AMBIENT_SOURCE_COLOR, "Night fill should use a lightweight ambient color")

	var moon := stage.get_node_or_null("MoonLight") as DirectionalLight3D
	_assert(moon != null, "Moonlight should be present")
	if moon != null:
		_assert(moon.light_energy >= 0.45 and moon.light_energy <= 0.8, "Moonlight should provide readable cool fill")
		_assert(moon.shadow_enabled, "Moonlight should preserve directional form")

	var entrance_fill := stage.get_node_or_null("OutdoorPlaza/EntranceFillLight") as OmniLight3D
	_assert(entrance_fill != null, "The warehouse entrance should have a warm guide light")
	if entrance_fill != null:
		_assert(entrance_fill.light_energy <= 2.5, "Entrance light energy should remain renderer friendly")
		_assert(entrance_fill.omni_range <= 10.0, "Entrance light range should remain bounded")
		_assert(not entrance_fill.shadow_enabled, "Entrance fill should avoid a costly dynamic shadow")

	var street_lights := stage.get_node("OutdoorPlaza/StreetLamps").find_children("*", "OmniLight3D", true, false)
	_assert(street_lights.size() == 4, "Four street lights should remain in the outdoor plaza")
	var interior_lights := stage.get_node("WarehouseInterior/InteriorLights").find_children("*", "OmniLight3D", true, false)
	_assert(interior_lights.size() == 3, "Three ceiling lights should remain in the warehouse")
	var omni_lights := stage.find_children("*", "OmniLight3D", true, false)
	_assert(omni_lights.size() <= 8, "The scene should stay within a small dynamic light budget")
	for node in omni_lights:
		var light := node as OmniLight3D
		_assert(light.light_energy <= 2.5, "%s energy should remain bounded" % light.name)
		_assert(light.omni_range <= 10.0, "%s range should remain bounded" % light.name)
		_assert(not light.shadow_enabled, "%s should avoid dynamic shadows" % light.name)

	stage.queue_free()
	await process_frame
	_finish()


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("Fort Mason lighting tests passed")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
