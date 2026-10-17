extends SceneTree

const REQUIRED_INPUT_ACTIONS := [
	"move_up",
	"move_down",
	"move_left",
	"move_right",
	"jump",
	"attack",
	"aim",
	"swap_weapons",
	"pause",
]

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_check(
		ProjectSettings.get_setting("application/run/main_scene") == "res://level/fort_mason.tscn",
		"Fort Mason is the configured main scene",
	)
	_check(
		ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility",
		"project uses the Compatibility renderer",
	)
	_check(
		ProjectSettings.get_setting("physics/3d/physics_engine") == "Jolt Physics",
		"project uses the Jolt 3D physics engine",
	)
	for action_name in REQUIRED_INPUT_ACTIONS:
		_check(InputMap.has_action(action_name), "input action exists: %s" % action_name)

	if _failures.is_empty():
		print("Project contract tests passed")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
