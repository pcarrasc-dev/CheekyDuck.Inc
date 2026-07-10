extends Node3D
class_name Shield

@onready var shield_appearance: AnimationPlayer = $"Shield Appearance"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global_scale(Vector3.ONE* 5)
	shield_appearance.play("Appearance")
	await shield_appearance.animation_finished
	queue_free()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
