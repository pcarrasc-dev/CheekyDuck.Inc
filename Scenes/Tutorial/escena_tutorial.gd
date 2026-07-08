extends Node3D

# ── Referencias ───────────────────────────────────────────────────────────────
@onready var skill_app: Node3D            = $Skills/SkillApp
@onready var skill_spawn_list: Array[int] = [0,0,0,0]
@onready var sp_0: Marker3D               = $"Skills/Skill SpawnPoint/SP0"
@onready var sp_1: Marker3D               = $"Skills/Skill SpawnPoint/SP1"
@onready var sp_2: Marker3D               = $"Skills/Skill SpawnPoint/SP2"
@onready var sp_3: Marker3D               = $"Skills/Skill SpawnPoint/SP3"
var sp_list: Array[Marker3D]              = [sp_0, sp_1, sp_2, sp_3]
@onready var hud: CanvasLayer             = $HUD
@onready var goal_area_a: Area3D          = $GoalAreaA   # gol para equipo B (arco de A)
@onready var goal_area_b: Area3D          = $GoalAreaB   # gol para equipo A (arco de B)
@onready var play_area: Area3D            = $PlayArea
@onready var camera_3d: Camera3D          = $Camera3D
@onready var balls: Node3D                = $Balls
@onready var skill_timer: Timer           = $Skills/SkillTimer
@onready var check_move: Area3D           = $CheckMove
@onready var field_v_2_tutorial: fieldTutorial   = $FieldV2_tutorial


# ── Estado del partido ────────────────────────────────────────────────────────
var score_a: int = 0   # equipo del jugador 0 (barras 1-4)
var score_b: int = 0   # equipo del jugador 1 (barras 5-8)
var match_running: bool = false
var ball_spawn: Vector3 = Vector3(-0.158, 7.181, 0.145)

# ── Spawn / formaciones ───────────────────────────────────────────────────────
@export var player_slot_spread: float = 0.8
const DEFAULT_FORMATION: Array[int] = [2, 5, 3]
var _player_scene_a: PackedScene = preload("res://Scenes/Player/player.tscn")


func _ready() -> void:
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CAPTURED)
	start_dialogue("res://Dialogue/gameplay tutorial 1.dtl")
	# Conectar áreas de gol
	goal_area_a.body_entered.connect(func(body): _on_goal(body, "A"))
	goal_area_b.body_entered.connect(func(body): _on_goal(body, "B"))

	

	camera_3d.make_current()

	match_running = true

#revisar
func _unhandled_input(event: InputEvent) -> void:
	var alt: InputEventKey = event as InputEventKey
	if alt:
		if alt.is_action_pressed("mouse en pantalla"):
			DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
		if alt.is_action_released("mouse en pantalla"):
			DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CAPTURED)

var _timer_sync: float = 0.0

func _process(delta: float) -> void:
	if not match_running:
		return
	play_area.body_exited.connect(ball_reset)
	
	check_move.body_entered.connect(_ball_start)
	
	
	

# ── Gol ───────────────────────────────────────────────────────────────────────

# La pelota entró al área de gol del equipo "side" → anota el equipo contrario
func _on_goal(body: Node3D, side: String) -> void:
	if not multiplayer.is_server():
		return
	# Sólo la pelota marca gol
	if not (body is kinetic_ball_tutorial):
		return
	if not match_running:
		return

	if side == "A":
		score_b += 1
	else:
		score_a += 1

	Debug.log("¡GOL! Score A:%d  B:%d" % [score_a, score_b])
	_sync_score(score_a, score_b)
	_reset_ball()

func _sync_score(a: int, b: int) -> void:
	score_a = a
	score_b = b
	hud.update_score(score_a, score_b)

func _reset_ball() -> void:
	var football: kinetic_ball_tutorial = $Balls/Ball
	football.linear_velocity  = Vector3.ZERO
	football.angular_velocity = Vector3.ZERO
	football.global_position  = ball_spawn

# ── Fin de partido ────────────────────────────────────────────────────────────

func _on_match_timeout() -> void:
	if not multiplayer.is_server():
		return
	_end_match.rpc(score_a, score_b)

func _end_match(final_a: int, final_b: int) -> void:
	match_running = false
	var winner: String
	if final_a > final_b:
		winner = "?"
	elif final_b > final_a:
		winner = "Tú"
	else:
		winner = "Empate"
	hud.show_end_screen(winner, final_a, final_b)


# ── Skill (placeholder) ───────────────────────────────────────────────────────
func skill() -> void:
	if not skill_timer.is_stopped():
		return
	skill_timer.start()
	var new_skill: SkillBox = preload("res://Scenes/Skills/skill_box.tscn").instantiate()
	for i in range(0, 4):
		if skill_spawn_list[i] == 0:
			new_skill.global_position = sp_list[i].global_position
			skill_spawn_list[i] = 1
			skill_app.add_child(new_skill)


# ── Barras / spawn ────────────────────────────────────────────────────────────

func _spawn_team(bars: Array[StaticBody3D], formation: Array[int], scene: PackedScene) -> void:
	_spawn_in_bar(bars[0], 1, scene, -1)
	for i: int in range(3):
		_spawn_in_bar(bars[i + 1], formation[i], scene, i)


func _spawn_in_bar(bar: StaticBody3D, count: int, scene: PackedScene, bar_field_index: int = -1) -> void:
	var existing_players: int = 0
	for child: Node in bar.get_children():
		if child is Node3D:
			existing_players += 1
	if existing_players > 0:
		return
	var final_count: int = count
	if final_count <= 0:
		if bar_field_index >= 0 and bar_field_index < DEFAULT_FORMATION.size():
			final_count = DEFAULT_FORMATION[bar_field_index]
		else:
			final_count = 1
	var positions: Array[Vector3] = FormationSetup.get_slot_positions(final_count, player_slot_spread)
	for pos: Vector3 in positions:
		var instance: Node3D = scene.instantiate() as Node3D
		bar.add_child(instance)
		instance.position = pos

func ball_reset(body: Node3D) -> void:
	var ball: kinetic_ball_tutorial = body as kinetic_ball_tutorial
	#Debug.log("body exited")
	if ball:
		#Debug.log("ball exited")
		ball.linear_velocity = Vector3.ZERO
		ball.angular_velocity = Vector3.ZERO
		ball.global_position = Vector3(-0.158, 7.181, 0.145)

func move_ball(body: Node3D) -> void:
	var ball: kinetic_ball_tutorial = body as kinetic_ball_tutorial
	#Debug.log("body exited")
	if ball:
		#Debug.log("ball exited")
		ball.apply_force(Vector3(10,10,10))

func start_dialogue(dialogue: String) -> void:
	var bar_5: Bar_tutorial                   = field_v_2_tutorial.get_node("Bar5")
	var bar_6: Bar_tutorial                   = field_v_2_tutorial.get_node("Bar6")
	var bar_7: Bar_tutorial                   = field_v_2_tutorial.get_node("Bar7")
	var bar_8: Bar_tutorial                   = field_v_2_tutorial.get_node("Bar8")
	var bars: Array[Bar_tutorial]             = [bar_5, bar_6, bar_7, bar_8]
	for bar in bars:
		bar.stop_input(false)
	Dialogic.start(dialogue)
	await Dialogic.timeline_ended
	for bar in bars:
		bar.stop_input(true)
		
func _ball_start(body : Node3D) -> void:
	Debug.log(body)
	var player: Player = body as Player
	if player:
		await get_tree().create_timer(1).timeout
		start_dialogue("res://Dialogue/gameplay tutorial 2.dtl")
		check_move.queue_free()
		var ball: kinetic_ball_tutorial = preload("res://Scenes/Tutorial/ball_tutorial.tscn").instantiate()
		balls.add_child(ball, true)
