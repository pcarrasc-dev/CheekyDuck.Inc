class_name Player
extends Node3D

var item: Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	var mouse_event = event as InputEventMouseMotion
	if mouse_event:
		Debug.log(mouse_event.relative)
		
		
