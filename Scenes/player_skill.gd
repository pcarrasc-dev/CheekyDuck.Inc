extends HBoxContainer
class_name PlayerSkill

@onready var skill_sprite: Sprite2D = $SkillSprite
var shield_texture = preload("res://Scenes/Skills/Shield.png")
var other_texture = preload("res://Scenes/Objects/icon.svg")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_skill_data(skill: String) -> void:
	if skill == "Shield":
		skill_sprite.texture = shield_texture
	elif skill == "Other":
		skill_sprite.texture = other_texture
