class_name Bar
extends StaticBody3D

@export var rotation_sensibility: float = 0.03
@export var traslation_sensibility: float = 0.005
@export var traslation_limit: float = 0.3
@export var team_bar_index: int = 1

var is_selected: bool = false
var _origin_x: float = 0.0




func _ready() -> void:
	_origin_x = position.x
	Debug.log("Bar (team_idx:%d) — autoridad: %d" % [
		team_bar_index,
		$MultiplayerSynchronizer.get_multiplayer_authority()
	])
 
 
func _input(event: InputEvent) -> void:
	# Solo el dueño de la barra la controla
	if not is_multiplayer_authority():
		return
	# Solo responde si esta barra está seleccionada
	if not is_selected:
		return
 
	var mouse_event: InputEventMouseMotion = event as InputEventMouseMotion
	if mouse_event:
		_apply_rotation(mouse_event.relative.x)
		_apply_translation(mouse_event.relative.y)
 
 
func _unhandled_input(event: InputEvent) -> void:
	# Solo el dueño gestiona la selección de barra
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
 
 
# Rota la barra sobre su eje X local según el movimiento horizontal del mouse
func _apply_rotation(mouse_x: float) -> void:
	rotate_x(mouse_x * rotation_sensibility)
 
 
# Desplaza la barra en su eje Z local según el movimiento vertical del mouse,
# respetando los límites definidos por translation_limit
func _apply_translation(mouse_y: float) -> void:
	var new_x: float = position.x - mouse_y * traslation_sensibility
	var min_x: float = _origin_x -traslation_limit
	var max_x: float = _origin_x + traslation_limit
	position.x = clampf(new_x, min_x, max_x)
