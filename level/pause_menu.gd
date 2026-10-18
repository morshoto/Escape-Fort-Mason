extends CanvasLayer

const PAUSE_ACTION := "pause"

@onready var _overlay: Control = $Overlay
@onready var _resume_button: Button = $Overlay/CenterContainer/Panel/MarginContainer/Content/ResumeButton

var _mouse_mode_before_pause: Input.MouseMode = Input.MOUSE_MODE_CAPTURED


func _ready() -> void:
	_overlay.hide()
	_resume_button.pressed.connect(resume_game)


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed(PAUSE_ACTION) or event.is_echo():
		return

	if get_tree().paused:
		resume_game()
	else:
		pause_game()
	get_viewport().set_input_as_handled()


func pause_game() -> void:
	if get_tree().paused:
		return

	_mouse_mode_before_pause = Input.mouse_mode
	get_tree().paused = true
	_overlay.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_resume_button.grab_focus()


func resume_game() -> void:
	if not get_tree().paused:
		return

	_overlay.hide()
	get_tree().paused = false
	Input.mouse_mode = _mouse_mode_before_pause
