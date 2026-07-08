extends Node3D

@onready var ball := get_parent() as RigidBody3D
const BALL_RADIUS: float = 0.97


func _process(delta: float) -> void:
	var v := ball.linear_velocity
	var speed := v.length()
	if speed < 0.01:
		return

	var move_dir := Vector3(v.x, 0.0, v.z).normalized()
	var roll_axis := Vector3.UP.cross(move_dir).normalized()

	var angle := (speed / BALL_RADIUS) * delta
	rotate(roll_axis, angle)
