extends Node3D

const DOTS_SCENE := preload("res://player/dots/dots.tscn")
const Dots = preload("res://player/dots/dots.gd")

const ENTRIES := [
	["Blue", Dots.VisualVariant.BLUE, Vector3(-4.5, 0.0, 0.0)],
	["Green", Dots.VisualVariant.GREEN, Vector3(-1.5, 0.0, 0.0)],
	["Alfred", Dots.VisualVariant.ALFRED, Vector3(1.5, 0.0, 0.0)],
	["Pink", Dots.VisualVariant.PINK, Vector3(4.5, 0.0, 0.0)],
]


func _ready() -> void:
	var camera := get_node("GalleryCamera") as Camera3D
	camera.look_at_from_position(Vector3(0.0, 2.1, 14.5), Vector3(0.0, 0.85, 0.0))
	for entry in ENTRIES:
		var dots := DOTS_SCENE.instantiate() as Dots
		dots.name = "Dots%s" % entry[0]
		dots.visual_variant = entry[1]
		dots.position = entry[2]
		add_child(dots)
		_add_label(entry[0], entry[2])


func _add_label(label_text: String, dots_position: Vector3) -> void:
	var label := Label3D.new()
	label.name = "%sLabel" % label_text
	label.text = label_text
	label.position = dots_position + Vector3(0.0, 2.0, 0.0)
	label.font_size = 32
	label.modulate = Color("#f5f7fb")
	label.outline_size = 8
	label.outline_modulate = Color("#172033")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
