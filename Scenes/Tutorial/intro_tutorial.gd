extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Dialogic.start("res://Dialogue/tutorial.dtl")
	await Dialogic.timeline_ended
	get_tree().change_scene_to_file("res://Scenes/Tutorial/Escena_tutorial.tscn")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
