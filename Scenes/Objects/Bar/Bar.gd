class_name Bar
extends StaticBody3D

@export var sensibility = 0.03
@export var bar_index: int = 0

var is_mine: bool = false

func _enter_tree() -> void:
	if bar_index == 0:
		is_mine = multiplayer.is_server()
		$MultiplayerSynchronizer.set_multiplayer_authority(1)
	else:
		is_mine = not multiplayer.is_server()
		for p in Game.players:
			if p.id != 1 and p.id != 0:
				$MultiplayerSynchronizer.set_multiplayer_authority(p.id)
				break

func _ready() -> void:
	Debug.log("Bar %d — is_mine: %s | autoridad: %d" % [
		bar_index, str(is_mine),
		$MultiplayerSynchronizer.get_multiplayer_authority()
	])

func _input(event: InputEvent) -> void:
	if not is_mine:
		return
	var mouse_event = event as InputEventMouseMotion
	if mouse_event:
		rotate_x(mouse_event.relative.x * sensibility)
