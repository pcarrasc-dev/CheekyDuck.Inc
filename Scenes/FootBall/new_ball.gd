extends Node3D
class_name kinetic_ball

@onready var foot_ball: RigidBody3D = $FootBall
@onready var ball_shape: CollisionShape3D = $FootBall/ball_shape
@onready var ball_area: Area3D = $FootBall/ball_area
@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer

var aceleration: int = 10
var speed: int = 10
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer_synchronizer.set_multiplayer_authority(Game.players[0].id)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	ball_area.area_entered.connect(move_ball)
		
	pass

func _physics_process(delta: float) -> void:
	ball_movement.rpc()
	pass

@rpc("reliable", "call_local", "authority")
func ball_movement() -> void:
	if foot_ball.sleeping:
			foot_ball.linear_velocity = Vector3(1,1,1)*speed

func move_ball(node : Node3D) -> void:
	var player: Bar = node as Bar
	if player:
		foot_ball.linear_velocity = player.global_position*speed
		pass
	pass

func ball_stop() -> void:
	foot_ball.linear_velocity = Vector3(0,0,0)
	foot_ball.inertia = Vector3(0,0,0)
