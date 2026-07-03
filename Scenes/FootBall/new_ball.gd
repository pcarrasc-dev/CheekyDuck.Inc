extends RigidBody3D
class_name kinetic_ball

@onready var ball_shape: CollisionShape3D = $ball_shape
@onready var ball_area: Area3D = $ball_area
@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer

var last_player_obj: StaticBody3D
var last_mouse_speed: Vector2 = Vector2.ZERO
var mouse_speed: Vector2 = Vector2.ZERO

const IMPULSE_MULTIPLIER: float = 0.008
const MIN_IMPULSE: float = 0.1
const MAX_SPEED: float = 8.0

var _was_colliding: bool = false


func _ready() -> void:
	if not is_multiplayer_authority():
		set_physics_process(false)
		return
	multiplayer_synchronizer.set_multiplayer_authority(Game.players[0].id)


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return

	var collision_list: Array[Node3D] = get_colliding_bodies()
	var is_colliding: bool = false

	for body in collision_list:
		var player := body as Player
		if player:
			is_colliding = true
			last_player_obj = player
			if not _was_colliding:
				var impulse := Vector3(mouse_speed.x, 0.0, mouse_speed.y) * IMPULSE_MULTIPLIER
				if impulse.length() > MIN_IMPULSE:
					apply_central_impulse(impulse)
					last_mouse_speed = mouse_speed
					mouse_speed = Vector2.ZERO
			break

	_was_colliding = is_colliding

	if linear_velocity.length() > MAX_SPEED:
		linear_velocity = linear_velocity.limit_length(MAX_SPEED)


func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	var mouse_event := event as InputEventMouseMotion
	if mouse_event:
		mouse_speed = mouse_event.velocity


func get_player() -> StaticBody3D:
	return last_player_obj
