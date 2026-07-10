extends Area3D
class_name SkillBox_Tutorial

signal skill

@onready var skill_texture: TextureRect = $MarginContainer/Skill/SkillTexture
@export var shield: PackedScene = preload("res://Scenes/Skills/shield_skill.tscn")
@export var double: PackedScene = preload("res://Scenes/Tutorial/skill_double_tutorial.tscn")
@export var fast_ball: PackedScene = preload("res://Scenes/Skills/fast_ball.tscn")
@onready var skill_get: AnimationPlayer = $SkillGet
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var weights: Array[float] = [1, 1, 1]
static var radius: float = 10
var available_skillset: Array[PackedScene] = [shield, double, fast_ball]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	pass # Replace with function body.


func _on_body_entered(body: Node3D) -> void:
	give_ball(body)
	
func give_ball(body: Node3D) -> void:
	Debug.log(body)
	var ball: kinetic_ball_tutorial = body as kinetic_ball_tutorial
	if ball:
		ball.player_ball.connect(_player_connect)
		Debug.log(ball)

func _player_connect(player: Player) -> void:
	var bar: Bar_tutorial = player.get_parent()
	if bar:
		skill.emit(available_skillset[rng.rand_weighted(weights)])
		skill_get.play("getSkill")
		await skill_get.animation_finished
		queue_free()
	pass
