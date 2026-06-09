extends RigidBody3D
class_name kinetic_ball

@onready var ball_shape: CollisionShape3D = $ball_shape
@onready var ball_area: Area3D = $ball_area
@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var ball: kinetic_ball = $"."

var last_player_obj: StaticBody3D
var last_mouse_speed: Vector2 = Vector2(0,0)
var mouse_speed: Vector2 = Vector2(0,0)
var mouse_acc: Vector2 = Vector2(0,0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not is_multiplayer_authority():
		ball.set_physics_process(false)
		return
	multiplayer_synchronizer.set_multiplayer_authority(Game.players[0].id)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if sleeping:
		linear_velocity= Vector3(1,1,1)
	var collide = ball.move_and_collide(linear_velocity*delta)
	var collision_list:Array[Node3D] = ball.get_colliding_bodies()
	if collision_list:
		Debug.log("collide")
		var bar = collision_list[0] as StaticBody3D
		if bar:
			last_player_obj = bar
			Debug.log(last_player_obj)
			if collide:
				ball.apply_force(Vector3(mouse_acc[0], 0, mouse_acc[1])*0.0005)
				last_mouse_speed = mouse_speed

func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	var mouse_event = event as InputEventMouseMotion
	if mouse_event:
		mouse_speed = mouse_event.velocity
		mouse_acc = (mouse_speed-last_mouse_speed)/get_physics_process_delta_time()
	
func get_player() -> StaticBody3D:
	return last_player_obj
