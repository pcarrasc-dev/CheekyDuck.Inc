class_name Bar
extends StaticBody3D

@export var sensibility = 0.03
@export var bar_index: int = 0  # 0 = host (izquierda), 1 = cliente (derecha)

var is_mine: bool = false

func _ready() -> void:
	var current_player = Game.get_current_player()
	if current_player != null:
		is_mine = (current_player.index == bar_index)
	else:
		is_mine = (bar_index == 0)
	Debug.log("Bar %d — is_mine: %s" % [bar_index, str(is_mine)])

func _input(event: InputEvent) -> void:
	if not is_mine:
		return
	var mouse_event = event as InputEventMouseMotion
	if mouse_event:
		rotate_x(mouse_event.relative.x * sensibility)
