class_name FortMasonStage
extends Node3D

const LEVEL_COLLISION_LAYER := 2

const NIGHT_SKY := Color("#050b1c")
const MOONLIGHT := Color("#a9bfed")
const OUTDOOR_GROUND := Color("#374a62")
const INDOOR_FLOOR := Color("#4c5665")
const WAREHOUSE_WALL := Color("#637388")
const WAREHOUSE_TRIM := Color("#c56d43")
const METAL := Color("#303d50")
const WATER := Color("#102d4d")
const BRIDGE := Color("#26354a")
const LAMP_COLOR := Color("#ffd89a")

var _materials: Dictionary = {}


func _ready() -> void:
	_configure_night_environment()
	_build_outdoor_plaza()
	_build_warehouse()
	_build_bay_backdrop()
	_build_lighting()
	_configure_spawn()


func _configure_night_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = NIGHT_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#40577d")
	environment.ambient_light_energy = 0.68
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	$WorldEnvironment.environment = environment

	var moon := $MoonLight as DirectionalLight3D
	moon.light_color = MOONLIGHT
	moon.light_energy = 0.55
	moon.shadow_enabled = true
	moon.rotation_degrees = Vector3(-48.0, -28.0, 0.0)


func _build_outdoor_plaza() -> void:
	var outdoor := $OutdoorPlaza as Node3D
	_add_box(outdoor, "Ground", Vector3(30.0, 0.4, 28.0), Vector3(0.0, -0.2, 11.5), _material("outdoor_ground", OUTDOOR_GROUND))
	_add_box(outdoor, "NorthSeawall", Vector3(30.0, 1.2, 0.4), Vector3(0.0, 0.6, 25.3), _material("seawall", METAL))
	_add_box(outdoor, "WestBoundary", Vector3(0.4, 2.0, 28.0), Vector3(-15.0, 1.0, 11.5), _material("boundary", METAL))
	_add_box(outdoor, "EastBoundary", Vector3(0.4, 2.0, 28.0), Vector3(15.0, 1.0, 11.5), _material("boundary", METAL))

	var arch := Node3D.new()
	arch.name = "WarehouseEntryArch"
	outdoor.add_child(arch)
	_add_box(arch, "LeftPillar", Vector3(0.8, 3.6, 0.8), Vector3(-3.0, 1.8, -3.7), _material("trim", WAREHOUSE_TRIM), false)
	_add_box(arch, "RightPillar", Vector3(0.8, 3.6, 0.8), Vector3(3.0, 1.8, -3.7), _material("trim", WAREHOUSE_TRIM), false)
	_add_box(arch, "Lintel", Vector3(6.8, 0.6, 0.8), Vector3(0.0, 3.9, -3.7), _material("trim", WAREHOUSE_TRIM), false)

	var lamps := Node3D.new()
	lamps.name = "StreetLamps"
	outdoor.add_child(lamps)
	for lamp_data in [
		["LampWest", Vector3(-6.5, 0.0, 10.5)],
		["LampEast", Vector3(6.5, 0.0, 10.5)],
		["LampPierWest", Vector3(-10.0, 0.0, 21.0)],
		["LampPierEast", Vector3(10.0, 0.0, 21.0)],
	]:
		_add_street_lamp(lamps, lamp_data[0], lamp_data[1])

	var sign := Label3D.new()
	sign.name = "FestivalPavilionSign"
	sign.text = "FORT MASON\nFESTIVAL PAVILION"
	sign.position = Vector3(0.0, 3.0, -3.1)
	sign.modulate = Color("#f2c58b")
	sign.outline_modulate = Color("#161d2b")
	sign.outline_size = 8
	sign.font_size = 32
	sign.pixel_size = 0.004
	outdoor.add_child(sign)


func _build_warehouse() -> void:
	var warehouse := $WarehouseInterior as Node3D
	var floor_material := _material("indoor_floor", INDOOR_FLOOR)
	var wall_material := _material("warehouse_wall", WAREHOUSE_WALL)
	var trim_material := _material("warehouse_trim", WAREHOUSE_TRIM)

	_add_box(warehouse, "Floor", Vector3(21.0, 0.4, 17.5), Vector3(0.0, -0.2, -11.25), floor_material)
	_add_box(warehouse, "WestWall", Vector3(0.5, 5.0, 16.0), Vector3(-10.5, 2.5, -12.0), wall_material)
	_add_box(warehouse, "EastWall", Vector3(0.5, 5.0, 16.0), Vector3(10.5, 2.5, -12.0), wall_material)
	_add_box(warehouse, "BackWall", Vector3(21.0, 5.0, 0.5), Vector3(0.0, 2.5, -19.75), wall_material)
	_add_box(warehouse, "WestFrontWing", Vector3(8.0, 5.0, 0.5), Vector3(-6.5, 2.5, -4.25), wall_material)
	_add_box(warehouse, "EastFrontWing", Vector3(8.0, 5.0, 0.5), Vector3(6.5, 2.5, -4.25), wall_material)
	_add_box(warehouse, "RoofPanel", Vector3(21.0, 0.18, 16.0), Vector3(0.0, 5.15, -12.0), _material("roof", METAL))

	var roof_frame := Node3D.new()
	roof_frame.name = "RoofFrame"
	warehouse.add_child(roof_frame)
	for x in [-9.0, -3.0, 3.0, 9.0]:
		_add_box(roof_frame, "Beam%s" % str(x), Vector3(0.35, 0.35, 15.5), Vector3(x, 5.0, -12.0), trim_material, false)
	_add_box(roof_frame, "FrontBeam", Vector3(21.0, 0.35, 0.35), Vector3(0.0, 5.0, -4.25), trim_material, false)

	var interior_props := Node3D.new()
	interior_props.name = "InteriorProps"
	warehouse.add_child(interior_props)
	_add_box(interior_props, "CargoCrateWest", Vector3(2.5, 2.0, 2.5), Vector3(-6.5, 1.0, -14.0), _material("cargo", METAL))
	_add_box(interior_props, "CargoCrateEast", Vector3(2.5, 1.5, 2.5), Vector3(6.5, 0.75, -9.0), _material("cargo_alt", WAREHOUSE_TRIM))
	_add_box(interior_props, "LoadingDock", Vector3(6.0, 0.5, 2.0), Vector3(0.0, 0.25, -18.2), trim_material)

	var interior_sign := Label3D.new()
	interior_sign.name = "LoadingSign"
	interior_sign.text = "LOADING BAY 01"
	interior_sign.position = Vector3(0.0, 3.1, -19.35)
	interior_sign.modulate = Color("#f2c58b")
	interior_sign.outline_modulate = Color("#161d2b")
	interior_sign.outline_size = 6
	interior_sign.font_size = 28
	interior_sign.pixel_size = 0.004
	warehouse.add_child(interior_sign)


func _build_bay_backdrop() -> void:
	var outdoor := $OutdoorPlaza as Node3D
	var water := MeshInstance3D.new()
	water.name = "BayWater"
	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(34.0, 12.0)
	water_mesh.material = _material("bay_water", WATER)
	water.mesh = water_mesh
	water.position = Vector3(0.0, -0.05, 33.0)
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	outdoor.add_child(water)

	var bridge := Node3D.new()
	bridge.name = "BayBridge"
	outdoor.add_child(bridge)
	_add_box(bridge, "BridgeDeck", Vector3(28.0, 0.65, 0.8), Vector3(0.0, 2.6, 31.0), _material("bridge", BRIDGE), false)
	_add_box(bridge, "BridgeTowerWest", Vector3(0.9, 6.0, 0.9), Vector3(-8.0, 3.0, 31.0), _material("bridge_tower", BRIDGE), false)
	_add_box(bridge, "BridgeTowerEast", Vector3(0.9, 6.0, 0.9), Vector3(8.0, 3.0, 31.0), _material("bridge_tower", BRIDGE), false)
	_add_box(bridge, "BridgeCable", Vector3(16.0, 0.18, 0.18), Vector3(0.0, 5.0, 31.0), _material("bridge_cable", WAREHOUSE_TRIM), false)


func _build_lighting() -> void:
	var outdoor := $OutdoorPlaza as Node3D
	var entrance_light := OmniLight3D.new()
	entrance_light.name = "EntranceFillLight"
	entrance_light.position = Vector3(0.0, 3.1, -1.0)
	entrance_light.light_color = LAMP_COLOR
	entrance_light.light_energy = 2.1
	entrance_light.omni_range = 9.0
	entrance_light.shadow_enabled = false
	outdoor.add_child(entrance_light)

	var warehouse := $WarehouseInterior as Node3D
	var interior_lights := Node3D.new()
	interior_lights.name = "InteriorLights"
	warehouse.add_child(interior_lights)
	for index in range(3):
		var light := OmniLight3D.new()
		light.name = "CeilingLight%s" % str(index + 1)
		light.position = Vector3(-6.0 + index * 6.0, 4.2, -12.0)
		light.light_color = LAMP_COLOR
		light.light_energy = 1.6
		light.omni_range = 9.0
		light.shadow_enabled = false
		interior_lights.add_child(light)


func _configure_spawn() -> void:
	var sam := get_node_or_null("Sam") as Node3D
	var spawn := $SamSpawn as Marker3D
	if sam != null:
		sam.global_transform = spawn.global_transform
		var camera_controller := sam.get_node_or_null("CameraController")
		if camera_controller != null:
			camera_controller.set("_euler_rotation", Vector3(0.0, PI, 0.0))
		var camera_spring_arm := sam.get_node_or_null("CameraController/CameraSpringArm") as SpringArm3D
		if camera_spring_arm != null:
			camera_spring_arm.collision_mask = 1 | LEVEL_COLLISION_LAYER


func _add_street_lamp(parent: Node3D, lamp_name: String, position: Vector3) -> void:
	var lamp := Node3D.new()
	lamp.name = lamp_name
	lamp.position = position
	parent.add_child(lamp)
	_add_box(lamp, "Pole", Vector3(0.18, 3.4, 0.18), Vector3(0.0, 1.7, 0.0), _material("lamp_metal", METAL), false)
	_add_box(lamp, "Fixture", Vector3(0.8, 0.18, 0.8), Vector3(0.0, 3.35, 0.0), _material("lamp_fixture", LAMP_COLOR), false)
	var light := OmniLight3D.new()
	light.name = "Light"
	light.position = Vector3(0.0, 3.1, 0.0)
	light.light_color = LAMP_COLOR
	light.light_energy = 2.0
	light.omni_range = 8.0
	light.shadow_enabled = false
	lamp.add_child(light)


func _add_box(
	parent: Node3D,
	node_name: String,
	size: Vector3,
	position: Vector3,
	material: Material,
	collision := true,
) -> Node3D:
	var container: Node3D
	if collision:
		var body := StaticBody3D.new()
		body.collision_layer = LEVEL_COLLISION_LAYER
		body.collision_mask = 1
		container = body
	else:
		container = Node3D.new()
	container.set_meta("decorative_only", true)
	parent.add_child(container)
	container.name = node_name
	container.position = position

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Visual"
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	mesh_instance.mesh = mesh
	container.add_child(mesh_instance)

	if collision:
		var collision_shape := CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		collision_shape.shape = box_shape
		container.add_child(collision_shape)

	return container


func _material(material_name: String, color: Color) -> StandardMaterial3D:
	if _materials.has(material_name):
		return _materials[material_name]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	_materials[material_name] = material
	return material
