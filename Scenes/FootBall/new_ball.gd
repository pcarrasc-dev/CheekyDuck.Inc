extends RigidBody3D
class_name kinetic_ball

@onready var ball_shape: CollisionShape3D = $ball_shape
@onready var ball_area: Area3D = $ball_area
@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer

var last_player_obj: StaticBody3D
var last_mouse_speed: Vector2 = Vector2.ZERO
var mouse_speed: Vector2 = Vector2.ZERO
var mouse_acc: Vector2 = Vector2.ZERO


func _ready() -> void:
	sleeping = false
	body_entered.connect(_on_body_entered)
	if not is_multiplayer_authority():
		set_physics_process(false)
		return
	multiplayer_synchronizer.set_multiplayer_authority(Game.players[0].id)


func _on_body_entered(body: Node) -> void:
	if not is_multiplayer_authority():
		return
	var player := body as Player
	if not player:
		return
	last_player_obj = player
	var force := Vector3(mouse_acc.x, 0.0, mouse_acc.y) * 0.0005
	if force.length() > 0.01:
		apply_force(force)
		last_mouse_speed = mouse_speed


func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	var mouse_event := event as InputEventMouseMotion
	if mouse_event:
		mouse_speed = mouse_event.velocity
		mouse_acc = (mouse_speed - last_mouse_speed) / get_physics_process_delta_time()


func get_player() -> StaticBody3D:
	return last_player_obj
