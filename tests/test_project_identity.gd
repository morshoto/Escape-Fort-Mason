extends SceneTree


func _init() -> void:
	var project_name := str(ProjectSettings.get_setting("application/config/name", ""))
	if project_name != "Escape Fort Mason":
		push_error("The exported game should be named Escape Fort Mason (got '%s')" % project_name)
		quit(1)
		return

	print("Project identity test passed")
	quit(0)
