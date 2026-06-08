extends Area3D
class_name SkillBox

@onready var skill_texture: TextureRect = $MarginContainer/Skill/SkillTexture
@onready var shield: Skills = preload("res://Scenes/Skills/shield_skill.tscn").instantiate()
@onready var skill_get: AnimationPlayer = $SkillGet
var available_skillset: Array[Skills] = [shield]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	body_entered.connect(_on_body_entered)
	pass

func _on_body_entered(body: Node3D) -> void:
	var ball: kinetic_ball = body as kinetic_ball
	if ball:
		var bar: Bar = ball.get_player()
		bar.skill = shield
		skill_get.play("getSkill")
		await skill_get.animation_finished
		queue_free()
