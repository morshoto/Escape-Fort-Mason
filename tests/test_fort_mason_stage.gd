extends SceneTree

const STAGE_PATH := "res://level/fort_mason.tscn"

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
	_check(stage.get_node_or_null("SamSpawn") is Marker3D, "Sam spawn marker exists")
	_check(stage.get_node_or_null("Sam") is CharacterBody3D, "Player is exposed as Sam")
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
		_check(
			sam.test_move(sam.global_transform, Vector3.DOWN * 2.0),
			"Sam has ground collision at the outdoor spawn",
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
