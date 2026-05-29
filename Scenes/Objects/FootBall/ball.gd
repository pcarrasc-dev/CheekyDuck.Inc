extends Node3D
class_name Ball

@export var speed: int = 200
@export var acceleration: float = 4
@onready var ball_area: Area3D = $BallArea

var player_id

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ball_area.body_entered.connect(_on_body_entered)
	if not is_multiplayer_authority():
		set_physics_process(false)

func _physics_process(delta: float) -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	pass

func _on_body_entered(body: Node3D) -> void:
	var player: Player = body as Player
	if player:
		player_id = player.name
	pass
