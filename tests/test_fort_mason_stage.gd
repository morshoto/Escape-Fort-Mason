extends SceneTree

const STAGE_PATH := "res://level/fort_mason.tscn"
const LEVEL_COLLISION_MASK := 2

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage_scene: PackedScene = load(STAGE_PATH)
	_check(stage_scene is PackedScene, "Fort Mason scene is loadable")
	if not stage_scene is PackedScene:
		_finish()
		return

	var stage: Node3D = stage_scene.instantiate()
	root.add_child(stage)
	await process_frame
	await process_frame

	_check(stage.name == "FortMason", "Fort Mason scene has a stable root name")
	_check(stage.get_node_or_null("OutdoorPlaza") is Node3D, "Outdoor plaza exists")
	_check(stage.get_node_or_null("WarehouseInterior") is Node3D, "Warehouse interior exists")
	var outdoor := stage.get_node_or_null("OutdoorPlaza") as Node3D
	var plaza_ground := outdoor.get_node_or_null("Ground/Visual") as MeshInstance3D if outdoor != null else null
	if plaza_ground != null and plaza_ground.mesh is BoxMesh:
		var plaza_size := (plaza_ground.mesh as BoxMesh).size
		_check(plaza_size.x <= 32.0 and plaza_size.z <= 30.0, "Outdoor plaza blockout stays near human scale")
	else:
		_check(false, "Outdoor plaza has measurable ground geometry")
	var entrance_arch := outdoor.get_node_or_null("WarehouseEntryArch") as Node3D if outdoor != null else null
	var left_pillar := entrance_arch.get_node_or_null("LeftPillar") as Node3D if entrance_arch != null else null
	var right_pillar := entrance_arch.get_node_or_null("RightPillar") as Node3D if entrance_arch != null else null
	var lintel := entrance_arch.get_node_or_null("Lintel") as Node3D if entrance_arch != null else null
	if left_pillar != null and right_pillar != null:
		var left_mesh := (left_pillar.get_node("Visual") as MeshInstance3D).mesh as BoxMesh
		var right_mesh := (right_pillar.get_node("Visual") as MeshInstance3D).mesh as BoxMesh
		var clear_width := right_pillar.position.x - right_mesh.size.x * 0.5 - left_pillar.position.x - left_mesh.size.x * 0.5
		_check(clear_width >= 4.5 and clear_width <= 6.5, "Warehouse entrance is a believable human-scale width")
	else:
		_check(false, "Warehouse entrance exposes both pillars")
	if lintel != null:
		var lintel_mesh := (lintel.get_node("Visual") as MeshInstance3D).mesh as BoxMesh
		var clear_height := lintel.position.y - lintel_mesh.size.y * 0.5
		_check(clear_height >= 3.0 and clear_height <= 4.0, "Warehouse entrance has a believable loading-door height")
	else:
		_check(false, "Warehouse entrance exposes a lintel")
	var warehouse := stage.get_node_or_null("WarehouseInterior") as Node3D
	var roof_panel := warehouse.get_node_or_null("RoofPanel") as Node3D if warehouse != null else null
	_check(roof_panel != null, "Warehouse has a roof panel")
	if roof_panel != null:
		var roof_visual := roof_panel.get_node_or_null("Visual") as MeshInstance3D
		_check(
			roof_visual != null and roof_visual.mesh is BoxMesh,
			"Roof panel uses lightweight box geometry",
		)
		_check(
			roof_panel is StaticBody3D and roof_panel.get_node_or_null("CollisionShape3D") is CollisionShape3D,
			"Roof panel participates in camera collision",
		)
		if roof_panel is StaticBody3D:
			_check(
				(roof_panel.collision_layer & LEVEL_COLLISION_MASK) != 0,
				"Roof panel uses the level collision layer",
			)
		if roof_visual != null and roof_visual.mesh is BoxMesh:
			var roof_mesh := roof_visual.mesh as BoxMesh
			_check(
				roof_mesh.size.x >= 20.0 and roof_mesh.size.z >= 15.0 and roof_mesh.size.y < 0.5,
				"Roof panel covers the warehouse footprint",
			)
	_check(stage.get_node_or_null("SamSpawn") is Marker3D, "Sam spawn marker exists")
	_check(stage.get_node_or_null("Sam") is CharacterBody3D, "Player is exposed as Sam")
	var spawn := stage.get_node_or_null("SamSpawn") as Marker3D
	if spawn != null:
		_check(abs(spawn.rotation.y - PI) < 0.01, "Sam spawn faces the warehouse entrance")
	_check(
		stage.get_node_or_null("OutdoorPlaza/StreetLamps").get_child_count() == 4,
		"Outdoor plaza has four street lamps",
	)
	_check(
		stage.get_node_or_null("OutdoorPlaza/BayWater") is MeshInstance3D,
		"Bay water is represented",
	)
	_check(
		stage.get_node_or_null("OutdoorPlaza/BayBridge") is Node3D,
		"Bay bridge silhouette is represented",
	)

	var environment := stage.get_node_or_null("WorldEnvironment") as WorldEnvironment
	_check(environment != null and environment.environment != null, "Night environment exists")
	if environment != null and environment.environment != null:
		_check(
			environment.environment.background_mode == Environment.BG_COLOR,
			"Night environment uses a lightweight color background",
		)
		_check(
			environment.environment.background_color.v < 0.2,
			"Night environment background is dark",
		)

	var static_bodies: Array[Node] = stage.find_children("*", "StaticBody3D", true, false)
	_check(static_bodies.size() >= 12, "Stage has floor and wall collision bodies")
	var collision_shapes: Array[Node] = stage.find_children("*", "CollisionShape3D", true, false)
	_check(collision_shapes.size() >= 12, "Stage collision bodies have shapes")

	var sam := stage.get_node_or_null("Sam") as CharacterBody3D
	if sam != null:
		var camera_controller := sam.get_node_or_null("CameraController")
		_check(
			camera_controller != null and abs(float(camera_controller.get("_euler_rotation").y) - PI) < 0.01,
			"Third-person camera starts toward the warehouse",
		)
		var camera_spring_arm := sam.get_node_or_null("CameraController/CameraSpringArm") as SpringArm3D
		_check(
			camera_spring_arm != null and (camera_spring_arm.collision_mask & LEVEL_COLLISION_MASK) != 0,
			"Third-person camera detects level collisions",
		)
		_check(
			sam.test_move(sam.global_transform, Vector3.DOWN * 2.0),
			"Sam has ground collision at the outdoor spawn",
		)
		var doorway_support_transform := Transform3D(Basis.IDENTITY, Vector3(0.0, 1.0, -3.25))
		_check(
			sam.test_move(doorway_support_transform, Vector3.DOWN * 2.0),
			"Sam has continuous ground support through the warehouse doorway",
		)
		var entrance_transform := Transform3D(Basis.IDENTITY, Vector3(0.0, 1.0, 4.0))
		_check(
			not sam.test_move(entrance_transform, Vector3(0.0, 0.0, -7.0)),
			"Warehouse entrance remains traversable",
		)
		var indoor_transform := Transform3D(Basis.IDENTITY, Vector3(0.0, 1.0, -12.0))
		_check(
			sam.test_move(indoor_transform, Vector3.DOWN * 2.0),
			"Sam has ground collision inside the warehouse",
		)
		var wall_test_transform := Transform3D(Basis.IDENTITY, Vector3(0.0, 1.0, -12.0))
		_check(
			sam.test_move(wall_test_transform, Vector3.LEFT * 20.0),
			"Warehouse side wall blocks traversal",
		)

	var provenance_path := "res://docs/fort-mason-assets.md"
	_check(FileAccess.file_exists(provenance_path), "Asset provenance document exists")
	if FileAccess.file_exists(provenance_path):
		var provenance := FileAccess.get_file_as_string(provenance_path)
		_check(provenance.contains("No external assets"), "Asset provenance records the blockout source")
		_check(provenance.contains("not selected"), "Asset provenance records rejected assets")

	_check(
		ProjectSettings.get_setting("application/run/main_scene") == STAGE_PATH,
		"Fort Mason is the configured main scene",
	)

	_finish()


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		_failures.append(description)
		printerr("FAIL: ", description)


func _finish() -> void:
	if _failures.is_empty():
		print("Fort Mason stage tests passed")
		quit(0)
	else:
		printerr("Fort Mason stage tests failed: ", _failures.size())
		quit(1)
