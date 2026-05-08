## field.gd
## Adjunta este script a un Node3D vacío como escena raíz.
## Godot 4.x — construye la cancha completa de forma procedural.
## ─────────────────────────────────────────────────────────────

extends Node3D

# ══════════════════════════════════════════════
#  PARÁMETROS DE LA CANCHA  (ajusta a tu gusto)
# ══════════════════════════════════════════════
const FIELD_W      : float = 20.0   # ancho  (eje X)
const FIELD_D      : float = 12.0   # largo  (eje Z)
const FIELD_H      : float = 0.15   # grosor del suelo

const WALL_HEIGHT  : float = 0.8    # altura de las murallas
const WALL_THICK   : float = 0.3    # grosor de las murallas

const POST_RADIUS  : float = 0.06   # radio de los postes
const POST_HEIGHT  : float = 1.5    # altura de los postes
const GOAL_WIDTH   : float = 2.4    # ancho interior del arco
const NET_DEPTH    : float = 0.8    # profundidad de la red

const LINE_H       : float = 0.005  # altura de las líneas pintadas
const LINE_W       : float = 0.08   # grosor de las líneas

# Colores / materiales base
const COLOR_GRASS_A : Color = Color(0.18, 0.55, 0.18)   # franja A
const COLOR_GRASS_B : Color = Color(0.15, 0.47, 0.15)   # franja B
const COLOR_LINE    : Color = Color(1.0,  1.0,  1.0, 0.92)
const COLOR_WALL    : Color = Color(0.10, 0.30, 0.10)
const COLOR_POST    : Color = Color(0.95, 0.95, 0.95)
const COLOR_NET     : Color = Color(1.0,  1.0,  1.0, 0.30)
const COLOR_DIRT    : Color = Color(0.55, 0.38, 0.20)   # área de penalti (tierra)

# ══════════════════════════════════════════════
#  ENTRY POINT
# ══════════════════════════════════════════════
func _ready() -> void:
	_build_field()
	_build_walls()
	_build_field_lines()
	_build_goal(Vector3(-FIELD_W * 0.5, 0.0, 0.0), true)   # arco izquierdo
	_build_goal(Vector3( FIELD_W * 0.5, 0.0, 0.0), false)  # arco derecho
	_build_camera()
	_build_light()
	print("✅ Cancha construida correctamente.")


# ══════════════════════════════════════════════
#  SUELO / PASTO
# ══════════════════════════════════════════════
func _build_field() -> void:
	var field_node: Node3D = Node3D.new()
	field_node.name = "Field"
	add_child(field_node)

	# — Cuerpo físico del suelo —
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "FieldBody"
	field_node.add_child(body)

	var mesh_inst: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(FIELD_W, FIELD_H, FIELD_D)
	mesh_inst.mesh = box
	mesh_inst.material_override = _mat(COLOR_GRASS_A)
	body.add_child(mesh_inst)

	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(FIELD_W, FIELD_H, FIELD_D)
	col.shape = shape
	body.add_child(col)

	body.position.y = -FIELD_H * 0.5

	# — Franjas de césped (decorativas, sin física) —
	var stripe_count: int   = 10
	var stripe_w: float     = FIELD_W / stripe_count
	for i: int in range(stripe_count):
		if i % 2 == 0:
			continue                          # franja A ya es el fondo
		var stripe: MeshInstance3D = MeshInstance3D.new()
		var sm: BoxMesh = BoxMesh.new()
		sm.size = Vector3(stripe_w - 0.02, LINE_H, FIELD_D)
		stripe.mesh = sm
		stripe.material_override = _mat(COLOR_GRASS_B)
		stripe.position = Vector3(
			-FIELD_W * 0.5 + stripe_w * i + stripe_w * 0.5,
			LINE_H * 0.5,
			0.0
		)
		field_node.add_child(stripe)


# ══════════════════════════════════════════════
#  MURALLAS PERIMETRALES
# ══════════════════════════════════════════════
func _build_walls() -> void:
	var walls_node: Node3D = Node3D.new()
	walls_node.name = "Walls"
	add_child(walls_node)

	var half_w: float = FIELD_W * 0.5
	var half_d: float = FIELD_D * 0.5
	var wy: float     = WALL_HEIGHT * 0.5  # centro vertical de la muralla

	# Norte y Sur
	for sign_z: int in [-1, 1]:
		var wall: StaticBody3D = _make_wall_body(
			Vector3(FIELD_W + WALL_THICK * 2, WALL_HEIGHT, WALL_THICK),
			Vector3(0.0, wy, sign_z * (half_d + WALL_THICK * 0.5)),
			"Wall_NS_%d" % sign_z
		)
		walls_node.add_child(wall)

	# Este y Oeste  (con huecos para los arcos — solo visual, sin hueco real)
	for sign_x: int in [-1, 1]:
		var wall: StaticBody3D = _make_wall_body(
			Vector3(WALL_THICK, WALL_HEIGHT, FIELD_D),
			Vector3(sign_x * (half_w + WALL_THICK * 0.5), wy, 0.0),
			"Wall_EW_%d" % sign_x
		)
		walls_node.add_child(wall)


func _make_wall_body(size: Vector3, pos: Vector3, n: String) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = n
	body.position = pos

	var mi: MeshInstance3D = MeshInstance3D.new()
	var bm: BoxMesh = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(COLOR_WALL)
	body.add_child(mi)

	var col: CollisionShape3D = CollisionShape3D.new()
	var sh: BoxShape3D = BoxShape3D.new()
	sh.size = size
	col.shape = sh
	body.add_child(col)

	return body


# ══════════════════════════════════════════════
#  LÍNEAS DEL CAMPO
# ══════════════════════════════════════════════
func _build_field_lines() -> void:
	var lines_node: Node3D = Node3D.new()
	lines_node.name = "FieldLines"
	add_child(lines_node)

	var y: float = LINE_H                     # altura sobre el pasto

	# — Borde perimetral —
	_add_line(lines_node, Vector3(FIELD_W, LINE_H, LINE_W),
		Vector3(0, y, -FIELD_D*0.5))    # Norte
	_add_line(lines_node, Vector3(FIELD_W, LINE_H, LINE_W),
		Vector3(0, y,  FIELD_D*0.5))    # Sur
	_add_line(lines_node, Vector3(LINE_W, LINE_H, FIELD_D),
		Vector3(-FIELD_W*0.5, y, 0))   # Oeste
	_add_line(lines_node, Vector3(LINE_W, LINE_H, FIELD_D),
		Vector3( FIELD_W*0.5, y, 0))   # Este

	# — Línea central —
	_add_line(lines_node, Vector3(LINE_W, LINE_H, FIELD_D),
		Vector3(0, y, 0))

	# — Círculo central —
	_add_circle_line(lines_node, Vector3(0, y, 0), 1.8, 64)

	# — Punto central —
	_add_dot(lines_node, Vector3(0, y, 0), 0.08)

	# — Áreas grandes (penalty box) —
	var pb_w: float = 3.2    # profundidad del área
	var pb_h: float = 5.0    # ancho del área
	for sx: int in [-1, 1]:
		var cx: float = sx * (FIELD_W * 0.5 - pb_w * 0.5)
		_add_line(lines_node, Vector3(pb_w, LINE_H, LINE_W),
			Vector3(cx, y, -pb_h * 0.5))
		_add_line(lines_node, Vector3(pb_w, LINE_H, LINE_W),
			Vector3(cx, y,  pb_h * 0.5))
		_add_line(lines_node, Vector3(LINE_W, LINE_H, pb_h),
			Vector3(sx * (FIELD_W * 0.5 - pb_w), y, 0))

	# — Áreas pequeñas (goal box) —
	var gb_w: float = 1.2
	var gb_h: float = 2.8
	for sx: int in [-1, 1]:
		var cx: float = sx * (FIELD_W * 0.5 - gb_w * 0.5)
		_add_line(lines_node, Vector3(gb_w, LINE_H, LINE_W),
			Vector3(cx, y, -gb_h * 0.5))
		_add_line(lines_node, Vector3(gb_w, LINE_H, LINE_W),
			Vector3(cx, y,  gb_h * 0.5))
		_add_line(lines_node, Vector3(LINE_W, LINE_H, gb_h),
			Vector3(sx * (FIELD_W * 0.5 - gb_w), y, 0))

	# — Puntos de penalti —
	var pen_x: float = FIELD_W * 0.5 - 2.8
	_add_dot(lines_node, Vector3(-pen_x, y, 0), 0.08)
	_add_dot(lines_node, Vector3( pen_x, y, 0), 0.08)

	# — Arcos de esquina —
	_add_corner_arc(lines_node, Vector3(-FIELD_W*0.5, y, -FIELD_D*0.5),  45.0)
	_add_corner_arc(lines_node, Vector3( FIELD_W*0.5, y, -FIELD_D*0.5), 135.0)
	_add_corner_arc(lines_node, Vector3(-FIELD_W*0.5, y,  FIELD_D*0.5), -45.0)
	_add_corner_arc(lines_node, Vector3( FIELD_W*0.5, y,  FIELD_D*0.5),-135.0)


func _add_line(parent: Node3D, size: Vector3, pos: Vector3) -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var bm: BoxMesh = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(COLOR_LINE)
	mi.position = pos
	parent.add_child(mi)


func _add_dot(parent: Node3D, pos: Vector3, radius: float) -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius    = radius
	cyl.bottom_radius = radius
	cyl.height        = LINE_H * 2
	cyl.radial_segments = 16
	mi.mesh = cyl
	mi.material_override = _mat(COLOR_LINE)
	mi.position = pos
	parent.add_child(mi)


func _add_circle_line(parent: Node3D, center: Vector3,
		radius: float, segments: int) -> void:
	for i: int in range(segments):
		var a0: float   = TAU * i       / segments
		var a1: float   = TAU * (i + 1) / segments
		var p0: Vector3 = Vector3(cos(a0) * radius, 0.0, sin(a0) * radius)
		var p1: Vector3 = Vector3(cos(a1) * radius, 0.0, sin(a1) * radius)
		var mid: Vector3  = (p0 + p1) * 0.5
		var diff: Vector3 = p1 - p0
		var seg_len: float = diff.length()

		var mi: MeshInstance3D = MeshInstance3D.new()
		var bm: BoxMesh = BoxMesh.new()
		bm.size = Vector3(LINE_W, LINE_H, seg_len)
		mi.mesh = bm
		mi.material_override = _mat(COLOR_LINE)
		mi.position = center + mid
		mi.look_at(center + mid + Vector3(diff.z, 0, -diff.x).normalized(), Vector3.UP)
		parent.add_child(mi)


func _add_corner_arc(parent: Node3D, corner: Vector3, start_deg: float) -> void:
	var r: float        = 0.35
	var segments: int   = 10
	var span: float     = TAU / 4.0
	for i: int in range(segments):
		var a0: float   = deg_to_rad(start_deg) + span * i       / segments
		var a1: float   = deg_to_rad(start_deg) + span * (i + 1) / segments
		var p0: Vector3 = Vector3(cos(a0) * r, 0.0, sin(a0) * r)
		var p1: Vector3 = Vector3(cos(a1) * r, 0.0, sin(a1) * r)
		var mid: Vector3  = (p0 + p1) * 0.5
		var diff: Vector3 = p1 - p0
		var mi: MeshInstance3D = MeshInstance3D.new()
		var bm: BoxMesh = BoxMesh.new()
		bm.size = Vector3(LINE_W, LINE_H, diff.length())
		mi.mesh = bm
		mi.material_override = _mat(COLOR_LINE)
		mi.position = corner + mid
		mi.look_at(corner + mid + Vector3(diff.z, 0, -diff.x).normalized(), Vector3.UP)
		parent.add_child(mi)


# ══════════════════════════════════════════════
#  ARCOS
# ══════════════════════════════════════════════
func _build_goal(center: Vector3, is_left: bool) -> void:
	var goal_node: Node3D = Node3D.new()
	goal_node.name = "Goal_Left" if is_left else "Goal_Right"
	goal_node.position = center
	add_child(goal_node)

	var half_g: float              = GOAL_WIDTH * 0.5
	var mat_post: StandardMaterial3D = _mat(COLOR_POST)
	var mat_net: StandardMaterial3D  = _mat(COLOR_NET)

	# — Postes verticales —
	for sz: float in [-half_g, half_g]:
		var post: MeshInstance3D = _make_cylinder(POST_RADIUS, POST_HEIGHT, mat_post)
		post.position = Vector3(0.0, POST_HEIGHT * 0.5, sz)
		goal_node.add_child(post)

	# — Travesaño horizontal —
	var crossbar: MeshInstance3D = _make_cylinder(POST_RADIUS, GOAL_WIDTH + POST_RADIUS * 2, mat_post)
	crossbar.rotation_degrees.x = 90.0
	crossbar.position = Vector3(0.0, POST_HEIGHT, 0.0)
	goal_node.add_child(crossbar)

	# — Postes traseros (anclan la red) —
	var back_x: float = NET_DEPTH * (1.0 if is_left else -1.0)
	for sz: float in [-half_g, half_g]:
		var bp: MeshInstance3D = _make_cylinder(POST_RADIUS * 0.7, POST_HEIGHT, mat_post)
		bp.position = Vector3(back_x, POST_HEIGHT * 0.5, sz)
		goal_node.add_child(bp)

	# — Barra superior trasera —
	var top_back: MeshInstance3D = _make_cylinder(POST_RADIUS * 0.7, GOAL_WIDTH + POST_RADIUS * 2, mat_post)
	top_back.rotation_degrees.x = 90.0
	top_back.position = Vector3(back_x, POST_HEIGHT, 0.0)
	goal_node.add_child(top_back)

	# — Red (3 paneles: techo, fondo, suelo) —
	# techo
	var net_top: MeshInstance3D = MeshInstance3D.new()
	var nm_top: BoxMesh = BoxMesh.new()
	nm_top.size = Vector3(NET_DEPTH, LINE_H * 3, GOAL_WIDTH)
	net_top.mesh = nm_top
	net_top.material_override = mat_net
	net_top.position = Vector3(back_x * 0.5, POST_HEIGHT, 0.0)
	goal_node.add_child(net_top)

	# fondo
	var net_back: MeshInstance3D = MeshInstance3D.new()
	var nm_back: BoxMesh = BoxMesh.new()
	nm_back.size = Vector3(LINE_H * 3, POST_HEIGHT, GOAL_WIDTH)
	net_back.mesh = nm_back
	net_back.material_override = mat_net
	net_back.position = Vector3(back_x, POST_HEIGHT * 0.5, 0.0)
	goal_node.add_child(net_back)

	# suelo de la red
	var net_floor: MeshInstance3D = MeshInstance3D.new()
	var nm_floor: BoxMesh = BoxMesh.new()
	nm_floor.size = Vector3(NET_DEPTH, LINE_H * 3, GOAL_WIDTH)
	net_floor.mesh = nm_floor
	net_floor.material_override = mat_net
	net_floor.position = Vector3(back_x * 0.5, 0.0, 0.0)
	goal_node.add_child(net_floor)

	# — Área de gol (suelo interior del arco) —
	var goal_floor: MeshInstance3D = MeshInstance3D.new()
	var gfm: BoxMesh = BoxMesh.new()
	gfm.size = Vector3(NET_DEPTH, FIELD_H, GOAL_WIDTH)
	goal_floor.mesh = gfm
	goal_floor.material_override = _mat(COLOR_DIRT)
	goal_floor.position = Vector3(back_x * 0.5, -FIELD_H * 0.5, 0.0)
	goal_node.add_child(goal_floor)

	# — Física del arco (StaticBody en postes) —
	for sz: float in [-half_g, half_g]:
		var sb: StaticBody3D = StaticBody3D.new()
		var cs: CollisionShape3D = CollisionShape3D.new()
		var cy: CapsuleShape3D = CapsuleShape3D.new()
		cy.radius = POST_RADIUS
		cy.height = POST_HEIGHT
		cs.shape = cy
		sb.position = Vector3(0.0, POST_HEIGHT * 0.5, sz)
		sb.add_child(cs)
		goal_node.add_child(sb)


func _make_cylinder(radius: float, height: float,
		mat: StandardMaterial3D) -> MeshInstance3D:
	var mi: MeshInstance3D  = MeshInstance3D.new()
	var cyl: CylinderMesh   = CylinderMesh.new()
	cyl.top_radius      = radius
	cyl.bottom_radius   = radius
	cyl.height          = height
	cyl.radial_segments = 16
	mi.mesh = cyl
	mi.material_override = mat
	return mi


# ══════════════════════════════════════════════
#  CÁMARA
# ══════════════════════════════════════════════
func _build_camera() -> void:
	var cam: Camera3D = Camera3D.new()
	cam.name = "MainCamera"

	# Posición con leve inclinación (recomendada para empezar)
	# Cambia a la cenital descomentando las líneas de abajo
	cam.position         = Vector3(0.0, 16.0, 8.0)
	cam.rotation_degrees = Vector3(-62.0, 0.0, 0.0)

	# ── Cenital ──
	# cam.position        = Vector3(0.0, 20.0, 0.0)
	# cam.rotation_degrees = Vector3(-90.0, 0.0, 0.0)

	add_child(cam)


# ══════════════════════════════════════════════
#  LUZ
# ══════════════════════════════════════════════
func _build_light() -> void:
	# Luz ambiental global
	var env: WorldEnvironment = WorldEnvironment.new()
	var environment: Environment = Environment.new()
	environment.ambient_light_color  = Color(0.6, 0.8, 0.6)
	environment.ambient_light_energy = 0.5
	env.environment = environment
	add_child(env)

	# Luz direccional (sol de estadio)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name             = "SunLight"
	sun.light_energy     = 1.2
	sun.shadow_enabled   = true
	sun.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
	add_child(sun)

	# Focos de estadio (OmniLight en las 4 esquinas)
	var corners: Array[Vector3] = [
		Vector3(-FIELD_W * 0.5, 8.0, -FIELD_D * 0.5),
		Vector3( FIELD_W * 0.5, 8.0, -FIELD_D * 0.5),
		Vector3(-FIELD_W * 0.5, 8.0,  FIELD_D * 0.5),
		Vector3( FIELD_W * 0.5, 8.0,  FIELD_D * 0.5),
	]
	for pos: Vector3 in corners:
		var omni: OmniLight3D = OmniLight3D.new()
		omni.light_energy = 0.8
		omni.omni_range   = 20.0
		omni.light_color  = Color(1.0, 0.98, 0.90)
		omni.position     = pos
		add_child(omni)


# ══════════════════════════════════════════════
#  UTILIDAD: material sólido
# ══════════════════════════════════════════════
func _mat(color: Color) -> StandardMaterial3D:
	var m : StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = color
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m
