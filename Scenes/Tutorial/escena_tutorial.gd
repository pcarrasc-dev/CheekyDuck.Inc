extends Node3D

# ── Referencias ───────────────────────────────────────────────────────────────
@onready var skill_node: Node3D            = $Skills
@onready var hud: CanvasLayer             = $HUD
@onready var goal_area_a: Area3D          = $GoalAreaA   # gol para equipo B (arco de A)
@onready var goal_area_b: Area3D          = $GoalAreaB   # gol para equipo A (arco de B)
@onready var play_area: Area3D            = $PlayArea
@onready var camera_3d: Camera3D          = $Camera3D
@onready var balls: Node3D                = $Balls
@onready var skill_timer: Timer           = $Skills/SkillTimer
@onready var check_move: Area3D           = $CheckMove
@onready var field_v_2_tutorial: fieldTutorial   = $FieldV2_tutorial
@export var skill_spawner: PackedScene = preload("res://Scenes/Tutorial/spawner_tutorial.tscn")
@onready var skill_app: Node3D = $Skills/SkillApp
@onready var shield_spawn_2: Marker3D = $Skills/ShieldsSpawn/ShieldSpawn2

# ── Estado del partido ────────────────────────────────────────────────────────
var score_a: int = 0   # equipo del jugador 0 (barras 1-4)
var score_b: int = 0   # equipo del jugador 1 (barras 5-8)
var match_running: bool = false
var ball_spawn: Vector3 = Vector3(-0.158, 7.181, 0.145)
var dialogue_3_4: bool = false
var dialogue_5: bool = false
var tutorial_finished: bool = false

# ── Spawn / formaciones ───────────────────────────────────────────────────────
@export var player_slot_spread: float = 0.8
const DEFAULT_FORMATION: Array[int] = [2, 5, 3]

var _player_scene_a: PackedScene = preload("res://Scenes/Player/player.tscn")

var skill_box: PackedScene = preload("res://Scenes/Tutorial/skill_box_tutorial.tscn")

var skills_array: PackedScene = skill_box

func _ready() -> void:
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CAPTURED)
	start_dialogue("res://Dialogue/gameplay tutorial 1.dtl")
	# Conectar áreas de gol
	goal_area_a.body_entered.connect(func(body): _on_goal(body, "A"))
	goal_area_b.body_entered.connect(func(body): _on_goal(body, "B"))

	play_area.body_exited.connect(ball_reset)
	
	check_move.body_entered.connect(_ball_start)

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
	if dialogue_3_4 and event.is_action_pressed("skill"):
		update_skill_scene()
	if event.is_action_pressed("exit_tutorial"):
		DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://ui/main_menu.tscn")

var _timer_sync: float = 0.0


# ── Gol ───────────────────────────────────────────────────────────────────────

# La pelota entró al área de gol del equipo "side" → anota el equipo contrario
func _on_goal(body: Node3D, side: String) -> void:
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
	ball_reset(body)
	start_dialogue_3_4()

func _sync_score(a: int, b: int) -> void:
	score_a = a
	score_b = b
	hud.update_score(score_a, score_b)

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
	if ball:
		ball.linear_velocity = Vector3.ZERO
		ball.angular_velocity = Vector3.ZERO
		ball.global_position = Vector3(-0.158, 7.181, 0.145)
		start_dialogue_3_4()

func move_ball(body: Node3D) -> void:
	var ball: kinetic_ball_tutorial = body as kinetic_ball_tutorial
	if ball:
		ball.apply_force(Vector3(10,10,10))

func start_dialogue(dialogue: String) -> void:
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
	var bar_5: Bar_tutorial                   = field_v_2_tutorial.get_node("Bar5")
	var bar_6: Bar_tutorial                   = field_v_2_tutorial.get_node("Bar6")
	var bar_7: Bar_tutorial                   = field_v_2_tutorial.get_node("Bar7")
	var bar_8: Bar_tutorial                   = field_v_2_tutorial.get_node("Bar8")
	var bars: Array[Bar_tutorial]             = [bar_5, bar_6, bar_7, bar_8]
	set_process_unhandled_input(false)
	for bar: Bar_tutorial in bars:
		bar.stop_input(false)
	Dialogic.start(dialogue)
	if dialogue == "res://Dialogue/gameplay tutorial 4.dtl":
		var spawner_inst: Spawner_Tutorial = skill_spawner.instantiate()
		spawner_inst.global_position = Vector3(-0.33, 1.612, 0.526)
		skill_node.add_child(spawner_inst, true)
		spawner_inst.skill_received.connect(_on_skill_received)
	await Dialogic.timeline_ended
	for bar: Bar_tutorial in bars:
		bar.stop_input(true)
	set_process_unhandled_input(true)
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CAPTURED)
		
func _ball_start(body : Node3D) -> void:
	Debug.log(body)
	var player: Bar_tutorial = body as Bar_tutorial
	if player:
		start_dialogue("res://Dialogue/gameplay tutorial 2.dtl")
		check_move.queue_free()
		await Dialogic.timeline_ended
		var ball: kinetic_ball_tutorial = preload("res://Scenes/Tutorial/ball_tutorial.tscn").instantiate()
		balls.add_child(ball, true)

func start_dialogue_3_4() -> void:
	if not dialogue_3_4:
		start_dialogue("res://Dialogue/gameplay tutorial 3.dtl")
		await Dialogic.timeline_ended
		start_dialogue("res://Dialogue/gameplay tutorial 4.dtl")
		dialogue_3_4 = true
		
# ── skills ────────────────────────────────────────────────────────────

func update_skill_scene() -> void:
	hud.update_skill(false, skill_box)
	if skills_array.instantiate() is Shield:
		_shield(shield_spawn_2)
	elif skills_array.instantiate() is Double_Ball_Tutorial:
		_double_ball(skills_array.instantiate())
	elif skills_array.instantiate() is Fast_Ball:
		_fast_ball(skills_array.instantiate())
	if not tutorial_finished:
		tutorial_finished = true
		await get_tree().create_timer(5).timeout 
		start_dialogue("res://Dialogue/gameplay tutorial 6.dtl")
		

func _shield(spawn: Marker3D) -> void:
	var shield: Shield = skills_array.instantiate()
	shield.global_scale(Vector3.ONE*1000)
	shield.global_position = spawn.global_position
	skill_app.add_child(shield)
	skills_array = skill_box

func _double_ball(double_ball: Double_Ball_Tutorial) -> void:
	double_ball.global_position = balls.global_position
	balls.add_child(double_ball)
	skills_array = skill_box

func _fast_ball(fast_ball: Fast_Ball) -> void:
	skill_app.add_child(fast_ball)
	for ball in balls.get_children(true):
		if ball is kinetic_ball_tutorial:
			ball.set_particles(true)
			ball.MAX_SPEED *= 2
	skills_array = skill_box
	await get_tree().create_timer(10).timeout
	for ball in balls.get_children(true):
		if ball is kinetic_ball_tutorial:
			ball.set_particles(false)
			ball.MAX_SPEED /= 2
	fast_ball.queue_free()

func _on_skill_received(scene: PackedScene) -> void:
	Debug.log("on_skill_received")
	if skills_array.instantiate() is not SkillBox_Tutorial:
		return
	skills_array = scene
	hud.update_skill(true, scene)
	if not dialogue_5:
		start_dialogue("res://Dialogue/gameplay tutorial 5.dtl")
		dialogue_5 = true
	
