extends RigidBody3D
class_name kinetic_ball_tutorial

@onready var ball_shape: CollisionShape3D = $ball_shape
@onready var ball_area: Area3D = $ball_area

signal player_ball

var MAX_SPEED: float = 24.0
const SOFT_CLAMP_FACTOR: float = 0.15
const HARD_CLAMP_THRESHOLD: float = 36.0
const IMPACT_COOLDOWN: float = 0.1
const STUCK_SPEED_THRESHOLD: float = 0.3
const STUCK_TIME_THRESHOLD: float = 0.5
const ESCAPE_IMPULSE: float = 1.5

var _impact_cooldown: float = 0.0
var _stuck_timer: float = 0.0

func _physics_process(delta: float) -> void:

	if _impact_cooldown > 0.0:
		_impact_cooldown -= delta

	var spd_: float = linear_velocity.length()

	if spd_ < STUCK_SPEED_THRESHOLD and global_position.y < 2.0:
		_stuck_timer += delta
	else:
		_stuck_timer = 0.0

	if _stuck_timer >= STUCK_TIME_THRESHOLD:
		var to_center := (Vector3(0.0, global_position.y, 0.0) - global_position).normalized()
		var escape_dir := to_center
		if abs(global_position.x) > 2.0:
			escape_dir.x = -sign(global_position.x)
			escape_dir = escape_dir.normalized()
		apply_central_impulse(escape_dir * ESCAPE_IMPULSE)
		_stuck_timer = 0.0

	if spd_ > MAX_SPEED:
		if spd_ > HARD_CLAMP_THRESHOLD:
			linear_velocity = linear_velocity.normalized() * MAX_SPEED
		else:
			linear_velocity = linear_velocity.lerp(
				linear_velocity.normalized() * MAX_SPEED,
				SOFT_CLAMP_FACTOR
			)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:

	if _impact_cooldown > 0.0:
		return

	for i in range(state.get_contact_count()):
		var collider := state.get_contact_collider_object(i)
		var player := collider as Player
		if not player:
			var bar := collider as Bar_tutorial
			if bar:
				player = _first_player_in_bar(bar)
		if player:
			Debug.log(player)
			player_ball.emit(player)
			_impact_cooldown = IMPACT_COOLDOWN
			break


func _first_player_in_bar(bar: Bar_tutorial) -> Player:
	for child in bar.get_children():
		var player := child as Player
		if player:
			return player
	return null
