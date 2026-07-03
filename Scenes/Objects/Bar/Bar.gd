class_name Bar
extends StaticBody3D

@export var rotation_sensibility: float = 0.006
@export var traslation_sensibility: float = 0.0025
@export var traslation_limit: float = 0.15
@export var team_bar_index: int = 1

var is_selected: bool = false
var _origin_x: float = 0.0

var angular_velocity: Vector3
var previous_rotation: Vector3

var skill: Skills

var _target_rotation: float = 0.0
var _target_translation: float = 0.0


func _ready() -> void:
	_origin_x = position.x


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if not is_selected:
		return

	rotate_x(_target_rotation)
	_target_rotation = 0.0

	var new_x: float = position.x + _target_translation
	var min_x: float = _origin_x - traslation_limit
	var max_x: float = _origin_x + traslation_limit
	position.x = clampf(new_x, min_x, max_x)
	_target_translation = 0.0


func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if not is_selected:
		return

	var mouse_event: InputEventMouseMotion = event as InputEventMouseMotion
	if mouse_event:
		if Game.get_current_player().id == Game.players[0].id:
			_target_rotation = -mouse_event.relative.x * rotation_sensibility
			_target_translation = -mouse_event.relative.y * traslation_sensibility
		elif Game.get_current_player().id == Game.players[1].id:
			_target_rotation = mouse_event.relative.x * rotation_sensibility
			_target_translation = mouse_event.relative.y * traslation_sensibility


func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return

	if event.is_action_pressed("bar_1"):
		is_selected = (team_bar_index == 1)
	elif event.is_action_pressed("bar_2"):
		is_selected = (team_bar_index == 2)
	elif event.is_action_pressed("bar_3"):
		is_selected = (team_bar_index == 3)
	elif event.is_action_pressed("bar_4"):
		is_selected = (team_bar_index == 4)


func set_skill(id: float) -> void:
	if is_multiplayer_authority():
		pass
	pass
