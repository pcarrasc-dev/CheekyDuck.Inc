extends Node3D
class_name kinetic_ball

@onready var foot_ball: RigidBody3D = $FootBall
@onready var ball_shape: CollisionShape3D = $FootBall/ball_shape
@onready var ball_area: Area3D = $ball_area
@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer

var last_player_obj: StaticBody3D
var last_mouse_speed: Vector2 = Vector2(0,0)
var mouse_speed: Vector2 = Vector2(0,0)
var mouse_acc: Vector2 = Vector2(0,0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not is_multiplayer_authority():
		set_physics_process(false)
		return
	multiplayer_synchronizer.set_multiplayer_authority(Game.players[0].id)
	pass # Replace with function body.

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if foot_ball.sleeping:
		foot_ball.linear_velocity= Vector3(1,1,1)
	var collide = foot_ball.move_and_collide(foot_ball.linear_velocity*delta)
	var collision_list:Array[Node3D] = foot_ball.get_colliding_bodies()
	if collision_list:
		var bar = collision_list[0] as StaticBody3D
		if bar:
			last_player_obj = bar
			Debug.log(last_player_obj)
			if collide:
				foot_ball.apply_force(Vector3(mouse_acc[0], 0, mouse_acc[1])*0.0005)
				last_mouse_speed = mouse_speed
	pass

func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	var mouse_event = event as InputEventMouseMotion
	if mouse_event:
		mouse_speed = mouse_event.velocity
		mouse_acc = (mouse_speed-last_mouse_speed)/get_physics_process_delta_time()
	pass

#func ball_stop() -> void:
	#foot_ball.linear_velocity = Vector3(0,0,0)
	#foot_ball.inertia = Vector3(0,0,0)
	#foot_ball.angular_velocity = Vector3(0,0,0)
	
func get_player() -> StaticBody3D:
	return last_player_obj
