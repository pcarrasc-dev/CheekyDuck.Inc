class_name ImpactResolver

const USE_MANUAL_IMPULSE_ASSIST: bool = false
const ASSIST_MULTIPLIER: float = 0.2

const MIN_HIT_STRENGTH: float = 4.0
const MAX_HIT_STRENGTH: float = 18.0
const DIR_THRESHOLD: float = 0.05


static func calculate_impact(
	bar: Bar,
	contact_global_pos: Vector3
) -> Dictionary:
	if not USE_MANUAL_IMPULSE_ASSIST:
		return {"impulse": Vector3.ZERO}

	var parent: Node3D = bar.get_parent()
	var basis_inv: Basis = parent.global_transform.basis.inverse()

	var bar_vel_local: Vector3 = basis_inv * bar.linear_velocity
	var bar_ang_vel: float = bar.angular_velocity.length()

	var contact_parent: Vector3 = parent.to_local(contact_global_pos)
	var r: Vector3 = contact_parent - bar.position

	var omega: Vector3 = Vector3(1, 0, 0) * bar_ang_vel
	var point_vel: Vector3 = bar_vel_local + omega.cross(r)

	var speed: float = point_vel.length()
	if speed < DIR_THRESHOLD:
		return {"impulse": Vector3.ZERO}

	var world_vel: Vector3 = parent.global_transform.basis * point_vel
	var hit_dir: Vector3 = world_vel.normalized()
	hit_dir.y = 0.0
	hit_dir = hit_dir.normalized()

	var forward_dir: Vector3 = -parent.global_transform.basis.z.normalized()
	forward_dir.y = 0.0
	forward_dir = forward_dir.normalized()

	var forward_contribution: float = clampf(1.0 - speed / 1.0, 0.0, 0.5)
	hit_dir = hit_dir.slerp(forward_dir, forward_contribution)

	var total_speed: float = clampf(speed * 0.1, MIN_HIT_STRENGTH, MAX_HIT_STRENGTH) * ASSIST_MULTIPLIER

	return {"impulse": hit_dir * total_speed}
