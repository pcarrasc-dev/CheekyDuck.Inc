extends Area3D
class_name SkillBox

@onready var skill_get: AnimationPlayer = $SkillGet

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	body_entered.connect(_on_body_entered)
	pass

func _on_body_entered(body: Node3D) -> void:
	var ball: Ball = body as Ball
	if ball:
		skill_get.play("getSkill")
		await skill_get.animation_finished
		queue_free()
