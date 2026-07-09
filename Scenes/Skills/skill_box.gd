extends Area3D
class_name SkillBox

signal skill

@onready var skill_texture: TextureRect = $MarginContainer/Skill/SkillTexture
@export var shield: PackedScene = preload("res://Scenes/Skills/shield_skill.tscn")
@export var double: PackedScene = preload("res://Scenes/Skills/skill_double.tscn")
@export var fast_ball: PackedScene = preload("res://Scenes/Skills/fast_ball.tscn")
@onready var skill_get: AnimationPlayer = $SkillGet
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var weights: Array[float] = [1, 1, 1]
static var radius: float = 10
var available_skillset: Array[PackedScene] = [shield, double, fast_ball]
@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not is_multiplayer_authority():
		return
	body_entered.connect(_on_body_entered)
	multiplayer_synchronizer.set_multiplayer_authority(Game.players[0].id)
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
		ball.player_ball.connect(_player_received)
		Debug.log(ball)

@rpc("call_local")
func _player_connect(player: Player) -> void:
	var bar: Bar = player.get_parent()
	if bar:
		skill.emit(available_skillset[rng.rand_weighted(weights)], bar)
		skill_get.play("getSkill")
		await skill_get.animation_finished
		queue_free()
	pass

func _player_received(player: Player) -> void:
	_player_connect.rpc(player)
