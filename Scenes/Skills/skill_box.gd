extends Area3D
class_name SkillBox

@onready var skill_texture: TextureRect = $MarginContainer/Skill/SkillTexture
@export var shield: PackedScene = preload("res://Scenes/Skills/shield_skill.tscn")
@export var double: PackedScene = preload("res://Scenes/Skills/skill_double.tscn")
@export var fast_ball: PackedScene = preload("res://Scenes/Skills/fast_ball.tscn")
@onready var skill_get: AnimationPlayer = $SkillGet
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var losing_weights: Array[float] = [2, 0.5, 1]
var winning_weights: Array[float] = [0.5, 2, 1]
static var radius: float = 10
var available_skillset: Array[PackedScene] = [shield, double, fast_ball]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not is_multiplayer_authority():
		return
	body_entered.connect(_on_body_entered)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	pass

func _on_body_entered(body: Node3D) -> void:
	give_ball.rpc(body)

@rpc("call_local")
func give_ball(body: Node3D) -> void:
	Debug.log(body)
	var ball: kinetic_ball = body as kinetic_ball
	if ball:
		ball.player_ball.connect(_player_connect)
		Debug.log(ball)

func _player_connect(player: Player) -> void:
	var bar: Bar = player.get_parent()
	if bar:
		bar.skill = available_skillset[rng.rand_weighted(winning_weights)]
		Debug.log(bar.skill)
		skill_get.play("getSkill")
		await skill_get.animation_finished
		queue_free()
	pass
