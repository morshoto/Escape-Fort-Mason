extends CharacterSkin

@onready var _face: Node2D = %GDbotFace


## Changes the model's facial expression based on the provided input string values.
## Possible expressions include "default" (for default blinking),
## "happy" (for a joyful expression), "dizzy" (for spiraling eyes),
## and "sleepy" (for a drowsy countenance).
## [br][b]Note:[/b] To add new expressions, you can edit gdbot_face.tscn, which is a 2D scene
## utilized by a viewport node to display on Gdbot's face.
func set_face(face_name: String) -> void:
	_face._set_face(face_name)
