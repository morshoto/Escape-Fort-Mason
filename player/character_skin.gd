class_name CharacterSkin
extends Node3D

## Shared animation contract for replaceable third-person character skins.
signal stepped

## Blends the walk and run clips used by the Move state.
@export_range(0.0, 1.0, 0.01) var walk_run_blending := 0.0:
	set = set_walk_run_blending

@onready var _animation_tree: AnimationTree = %AnimationTree
@onready var _main_state_machine: AnimationNodeStateMachinePlayback = _animation_tree.get(
	"parameters/StateMachine/playback"
)
@onready var _walk_run_blend_amount := "parameters/StateMachine/Move/WalkRunBlending/blend_amount"
@onready var _step_time_scale := "parameters/StateMachine/Move/StepTimeScale/scale"
@onready var _walk_run_ratio := _animation_tree.get_animation("walk").length / _animation_tree.get_animation("run").length
@onready var _attack_one_shot := "parameters/AttackOneShot/request"


func _ready() -> void:
	walk_run_blending = walk_run_blending


func set_walk_run_blending(value: float) -> void:
	walk_run_blending = clampf(value, 0.0, 1.0)
	if not is_node_ready():
		return
	_animation_tree.set(_walk_run_blend_amount, walk_run_blending)
	_animation_tree.set(_step_time_scale, lerpf(1.0, _walk_run_ratio, walk_run_blending))


## Sets the model to a neutral, action-free state.
func idle() -> void:
	_main_state_machine.travel("Idle")


## Sets the model to a walking or running animation.
func move() -> void:
	_main_state_machine.travel("Move")


## Sets the model to an upward-leaping animation.
func jump() -> void:
	_main_state_machine.travel("Jump")


## Sets the model to a downward animation.
func fall() -> void:
	_main_state_machine.travel("Fall")


func attack() -> void:
	_animation_tree.set(_attack_one_shot, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func emit_step() -> void:
	stepped.emit()
