extends Node3D

# ── Referencias ───────────────────────────────────────────────────────────────
@onready var skill_app: Node3D            = $Skills/SkillApp
@onready var skill_timer: Timer           = $Skills/SkillTimer
@onready var hud_2: HUD_2                 = $HUD2
@onready var hud: HUD                     = $HUD
@onready var goal_area_a: Area3D          = $GoalAreaA   # gol para equipo B (arco de A)
@onready var goal_area_b: Area3D          = $GoalAreaB   # gol para equipo A (arco de B)
@onready var match_timer: Timer           = $MatchTimer
@onready var play_area: Area3D            = $PlayArea
@onready var camera_3d: Camera3D          = $Camera3D
@onready var camera_3d_2: Camera3D        = $Camera3D2
@onready var balls: Node3D                = $Balls
@onready var spawner: Spawner = $"Skills/Skill SpawnPoint/Spawner"
@onready var spawner_2: Spawner = $"Skills/Skill SpawnPoint/Spawner2"
@onready var spawner_3: Spawner = $"Skills/Skill SpawnPoint/Spawner3"
@onready var spawner_4: Spawner = $"Skills/Skill SpawnPoint/Spawner4"
var spawner_array: Array[Spawner] = [spawner, spawner_2, spawner_3, spawner_4]
@onready var shield_spawn_1: Marker3D = $Skills/ShieldsSpawn/ShieldSpawn1
@onready var shield_spawn_2: Marker3D = $Skills/ShieldsSpawn/ShieldSpawn2
@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var ball_spawner: MultiplayerSpawner = $Balls/Ball_Spawner
@onready var shield_spawner: MultiplayerSpawner = $Skills/SkillApp/ShieldSpawner

var skill_box = preload("uid://du651h2fd1qqu")
var shield_scene: PackedScene = preload("res://Scenes/Skills/shield_skill.tscn")
var fast_ball_scene: PackedScene = preload("res://Scenes/Skills/fast_ball.tscn")
var double_ball_scene: PackedScene = preload("res://Scenes/Skills/skill_double.tscn")

var skills_array: Array[PackedScene] = [skill_box, skill_box]

# ── Estado del partido ────────────────────────────────────────────────────────
const MATCH_DURATION: float  = 180.0   # 3 minutos
const GOALS_TO_WIN:   int    = 3

var _last_minute_triggered: bool = false

var score_a: int = 0   # equipo del jugador 0 (barras 1-4)
var score_b: int = 0   # equipo del jugador 1 (barras 5-8)
var match_running: bool = false
var ball_spawn: Vector3 = Vector3(-0.158, 0.2, 0.145)

var _goal_processed: Dictionary = {}
var _goal_poll_tick: int = 0

# ── Spawn / formaciones ───────────────────────────────────────────────────────
@export_range(0.1, 10.0, 0.05) var player_slot_spread: float = 4
const DEFAULT_FORMATION: Array[int] = [2, 5, 3]
var _player_scene_a: PackedScene = preload("res://Scenes/Player/player.tscn")
var _player_scene_b: PackedScene = preload("res://Scenes/Player/player_2.tscn")


func _ready() -> void:
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CAPTURED)
	Debug.log("Players al cargar: %d" % Game.players.size())
	for p in Game.players:
		Debug.log("  id:%d index:%d" % [p.id, p.index])

	# Conectar áreas de gol
	goal_area_a.body_entered.connect(func(body): _on_goal(body, "A"))
	goal_area_b.body_entered.connect(func(body): _on_goal(body, "B"))
	
	spawner.skill_received.connect(_on_skill_received)
	spawner_2.skill_received.connect(_on_skill_received)
	spawner_3.skill_received.connect(_on_skill_received)
	spawner_4.skill_received.connect(_on_skill_received)

	if Game.players.size() >= 2:
		_setup_bars_authority()
		
		if Game.get_current_player().id == Game.players[0].id:
			camera_3d_2.set_multiplayer_authority(Game.players[0].id)
			camera_3d_2.make_current()
			hud.set_multiplayer_authority(Game.players[0].id)
			hud_2.hide()
		elif Game.get_current_player().id == Game.players[1].id:
			camera_3d.set_multiplayer_authority(Game.players[1].id)
			camera_3d.make_current()
			hud_2.set_multiplayer_authority(Game.players[1].id)
			hud.hide()
	else:
		Game.players_updated.connect(_on_players_updated)

	# Arrancar partido (solo servidor gestiona el timer)
	if multiplayer.is_server():
		match_timer.wait_time = MATCH_DURATION
		match_timer.one_shot  = true
		match_timer.timeout.connect(_on_match_timeout)
		match_timer.start()
	match_running = true
	play_area.body_exited.connect(ball_reset)
	BackgroundMusic.start_match()
	

#revisar
func _unhandled_input(event: InputEvent) -> void:
	var alt: InputEventKey = event as InputEventKey
	if alt:
		if alt.is_action_pressed("mouse en pantalla"):
			DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
		if alt.is_action_released("mouse en pantalla"):
			DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CAPTURED)
	if event.is_action_pressed("skill"):
		update_skill_scene.rpc()
		

var _timer_sync: float = 0.0

func _process(delta: float) -> void:
	if not match_running:
		return
	if multiplayer.is_server():
		hud.update_timer(match_timer.time_left)
		hud_2.update_timer(match_timer.time_left)
		_timer_sync += delta
		if _timer_sync >= 1.0:
			_timer_sync = 0.0
			_sync_timer.rpc(match_timer.time_left)
		_check_last_minute_music(match_timer.time_left)
		_goal_poll()
	
		
		
	

@rpc("authority", "unreliable")
func _sync_timer(time_left: float) -> void:
	hud.update_timer(time_left)
	hud_2.update_timer(time_left)
	_check_last_minute_music(time_left)

func _check_last_minute_music(time_left: float) -> void:
	if _last_minute_triggered:
		return
	if time_left <= 60.0:
		_last_minute_triggered = true
		BackgroundMusic.trigger_last_minute()

func _goal_poll() -> void:
	if not match_running:
		return
	for body in goal_area_a.get_overlapping_bodies():
		if body is kinetic_ball and not _goal_processed.has(body.get_instance_id()):
			_on_goal(body, "A")
	for body in goal_area_b.get_overlapping_bodies():
		if body is kinetic_ball and not _goal_processed.has(body.get_instance_id()):
			_on_goal(body, "B")
		
# ── Gol ───────────────────────────────────────────────────────────────────────

# La pelota entró al área de gol del equipo "side" → anota el equipo contrario
func _on_goal(body: Node3D, side: String) -> void:
	if not multiplayer.is_server():
		return
	if not (body is kinetic_ball):
		return
	if not match_running:
		return
	var id := body.get_instance_id()
	if _goal_processed.has(id):
		return
	_goal_processed[id] = true

	if side == "A":
		score_b += 1
	else:
		score_a += 1

	Debug.log("¡GOL! Score A:%d  B:%d" % [score_a, score_b])
	_sync_score.rpc(score_a, score_b)
	var concede_dir: float = 1.0 if side == "A" else -1.0
	ball_reset.rpc(body, concede_dir)

	if score_a >= GOALS_TO_WIN or score_b >= GOALS_TO_WIN:
		_end_match.rpc(score_a, score_b)


@rpc("authority", "reliable", "call_local")
func _sync_score(a: int, b: int) -> void:
	score_a = a
	score_b = b
	hud.update_score(score_a, score_b)
	hud_2.update_score(score_b, score_a)


# ── Fin de partido ────────────────────────────────────────────────────────────

func _on_match_timeout() -> void:
	if not multiplayer.is_server():
		return
	_end_match.rpc(score_a, score_b)


@rpc("authority", "reliable", "call_local")
func _end_match(final_a: int, final_b: int) -> void:
	match_running = false
	match_timer.stop()
	BackgroundMusic.play_final_whistle()
	await get_tree().create_timer(2.0).timeout
	BackgroundMusic.end_match()
	var winner: String
	if final_a > final_b:
		winner = Game.players[0].name
	elif final_b > final_a:
		winner = Game.players[1].name
	else:
		winner = "Empate"
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
	hud.show_end_screen(winner, final_a, final_b)
	hud_2.show_end_screen(winner, final_b,  final_a)


# ── Barras / spawn ────────────────────────────────────────────────────────────

func _setup_bars_authority() -> void:
	Game.sort_players()
	$Balls/Ball.set_multiplayer_authority(1)
	$FieldV2/Bar.set_multiplayer_authority(Game.players[0].id)
	$FieldV2/Bar2.set_multiplayer_authority(Game.players[0].id)
	$FieldV2/Bar3.set_multiplayer_authority(Game.players[0].id)
	$FieldV2/Bar4.set_multiplayer_authority(Game.players[0].id)
	$FieldV2/Bar5.set_multiplayer_authority(Game.players[1].id)
	$FieldV2/Bar6.set_multiplayer_authority(Game.players[1].id)
	$FieldV2/Bar7.set_multiplayer_authority(Game.players[1].id)
	$FieldV2/Bar8.set_multiplayer_authority(Game.players[1].id)
	Debug.log("Bar0 autoridad: %d | Bar1 autoridad: %d" % [
		Game.players[0].id, Game.players[1].id
	])
	_spawn_players()

func _on_players_updated() -> void:
	if Game.players.size() < 2:
		return
	Game.players_updated.disconnect(_on_players_updated)
	_setup_bars_authority()

func _spawn_players() -> void:
	var bars_a: Array[RigidBody3D] = [
		$FieldV2/Bar,
		$FieldV2/Bar2,
		$FieldV2/Bar3,
		$FieldV2/Bar4,
	]
	var bars_b: Array[RigidBody3D] = [
		$FieldV2/Bar5,
		$FieldV2/Bar6,
		$FieldV2/Bar7,
		$FieldV2/Bar8,
	]

	var formation_a: Array[int] = Game.get_player_formation(Game.players[0].id)
	var formation_b: Array[int] = Game.get_player_formation(Game.players[1].id)

	_spawn_team(bars_a, formation_a, _player_scene_a)
	_spawn_team(bars_b, formation_b, _player_scene_b)



func _spawn_team(bars: Array[RigidBody3D], formation: Array[int], scene: PackedScene) -> void:
	_spawn_in_bar(bars[0], 1, scene, -1)
	for i: int in range(3):
		_spawn_in_bar(bars[i + 1], formation[i], scene, i)


func _spawn_in_bar(bar: RigidBody3D, count: int, scene: PackedScene, bar_field_index: int = -1) -> void:
	var existing_players: int = 0
	for child: Node in bar.get_children():
		if child is Player:
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
		instance.position = pos
		bar.add_child(instance)
	var bar_node: Bar = bar as Bar
	if bar_node:
		bar_node.refresh_collisions()

func ball_reset(body: Node3D, dir: float = 0.0) -> void:
	var ball:kinetic_ball = body as kinetic_ball
	if ball:
		_goal_processed.erase(ball.get_instance_id())
		ball.linear_velocity = Vector3.ZERO
		ball.angular_velocity = Vector3.ZERO
		ball.global_position = ball_spawn
		if dir != 0.0:
			ball.linear_velocity = Vector3(dir * 6.0, 0.0, 0.0)

# ── skills ────────────────────────────────────────────────────────────

@rpc("call_local")
func update_skill_scene() -> void:
	if Game.get_current_player().id == Game.players[0].id:
		hud.update_skill(false, skill_box)
		if skills_array[0].instantiate() is Shield:
			_shield.rpc(skills_array[0].instantiate(), shield_spawn_1, 0)
		elif skills_array[0].instantiate() is Double_Ball:
			_double_ball.rpc(skills_array[0].instantiate(), 0)
		elif skills_array[0].instantiate() is Fast_Ball:
			_fast_ball.rpc(skills_array[0].instantiate(), 0)
	elif Game.get_current_player().id == Game.players[1].id:
		hud_2.update_skill(false, skill_box)
		if skills_array[1].instantiate() is Shield:
			_shield.rpc(skills_array[1].instantiate(), shield_spawn_2, 1)
		elif skills_array[1].instantiate() is Double_Ball:
			_double_ball.rpc(skills_array[1].instantiate(), 1)
		elif skills_array[1].instantiate() is Fast_Ball:
			_fast_ball.rpc(skills_array[1].instantiate(), 1)
		
@rpc("call_local")
func _shield(shield: Shield, spawn: Marker3D, num: int) -> void:
	shield.global_position = spawn.global_position
	shield_spawner.add_child(shield)
	skills_array[num] = skill_box
	
@rpc("call_local")
func _double_ball(double_ball: Double_Ball, num: int) -> void:
	double_ball.global_position = balls.global_position
	double_ball.set_multiplayer_authority(Game.players[0].id)
	ball_spawner.add_child(double_ball)
	skills_array[num] = skill_box
	
@rpc("call_local")
func _fast_ball(fast_ball: Fast_Ball, num: int) -> void:
	shield_spawner.add_child(fast_ball)
	for ball in balls.get_children(true):
		if ball is kinetic_ball:
			ball.MAX_SPEED *= 2
			ball.set_particles(true)
	skills_array[num] = skill_box
	await get_tree().create_timer(10).timeout
	for ball in balls.get_children(true):
		if ball is kinetic_ball:
			ball.MAX_SPEED /= 2
			ball.set_particles(false)

func _on_skill_received(scene: PackedScene, bar: Bar) -> void:
	Debug.log("on_skill_received")
	var idx := _skill_index(scene)
	if idx < 0:
		return
	_skill_hud_update.rpc(bar.get_multiplayer_authority(), idx)

func _skill_index(scene: PackedScene) -> int:
	var inst := scene.instantiate()
	if inst is Shield: return 0
	if inst is Fast_Ball: return 1
	if inst is Double_Ball: return 2
	return -1

@rpc("authority", "reliable", "call_local")
func _skill_hud_update(bar_authority: int, skill_index: int) -> void:
	var scene: PackedScene
	match skill_index:
		0: scene = shield_scene
		1: scene = fast_ball_scene
		2: scene = double_ball_scene
		_: return
	
	if bar_authority == Game.players[0].id:
		if skills_array[0].instantiate() is not SkillBox:
			return
		skills_array[0] = scene
		hud.update_skill(true, scene)
	elif bar_authority == Game.players[1].id:
		if skills_array[1].instantiate() is not SkillBox:
			return
		skills_array[1] = scene
		hud_2.update_skill(true, scene)
