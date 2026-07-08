extends Node3D

@export var ball: PackedScene = preload("uid://pbsomgi086yu")
var ball_spawn: Vector3 = Vector3(-0.158, 7.181, 0.145)
var ball_amount: int = 1
var ball_maximum: int = 2
@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var timer: Timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_spawn()
	timer.start(20)
	timer.timeout.connect(_on_timeout)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _spawn() -> void:
	while ball_amount < ball_maximum:
		var ball_inst: kinetic_ball = ball.instantiate()
		ball_inst.global_position = ball_spawn
		multiplayer_spawner.add_child(ball_inst, true)
		ball_amount += 1
		ball_inst.tree_exited.connect(func() -> void: ball_amount -= 1)

func _on_timeout() -> void:
	while ball_amount > 1:
		var this_ball: kinetic_ball = multiplayer_spawner.get_child(0)
		this_ball.queue_free()
