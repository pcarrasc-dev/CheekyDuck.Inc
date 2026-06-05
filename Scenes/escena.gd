extends Node3D

# ── Referencias ───────────────────────────────────────────────────────────────
@onready var skill_app: Node3D     = $Skills/SkillApp
@onready var skill_timer: Timer    = $Skills/SkillTimer
@onready var hud: CanvasLayer      = $HUD
@onready var ball_node: Node3D     = $Ball
@onready var goal_area_a: Area3D   = $GoalAreaA   # gol para equipo B (arco de A)
@onready var goal_area_b: Area3D   = $GoalAreaB   # gol para equipo A (arco de B)
@onready var match_timer: Timer    = $MatchTimer

# ── Estado del partido ────────────────────────────────────────────────────────
const MATCH_DURATION: float  = 180.0   # 3 minutos
const GOALS_TO_WIN:   int    = 1

var score_a: int = 0   # equipo del jugador 0 (barras 1-4)
var score_b: int = 0   # equipo del jugador 1 (barras 5-8)
var match_running: bool = false
var ball_spawn: Vector3 = Vector3(0, 4.834766, 0)

# ── Spawn / formaciones ───────────────────────────────────────────────────────
@export var player_slot_spread: float = 0.8
const DEFAULT_FORMATION: Array[int] = [2, 5, 3]
var _player_scene_a: PackedScene = preload("res://Scenes/Player/player.tscn")
var _player_scene_b: PackedScene = preload("res://Scenes/Player/player_2.tscn")


func _ready() -> void:
	Debug.log("Players al cargar: %d" % Game.players.size())
	for p in Game.players:
		Debug.log("  id:%d index:%d" % [p.id, p.index])

	# Conectar áreas de gol
	goal_area_a.body_entered.connect(func(body): _on_goal(body, "A"))
	goal_area_b.body_entered.connect(func(body): _on_goal(body, "B"))

	if Game.players.size() >= 2:
		_setup_bars_authority()
	else:
		Game.players_updated.connect(_on_players_updated)

	# Arrancar partido (solo servidor gestiona el timer)
	if multiplayer.is_server():
		match_timer.wait_time = MATCH_DURATION
		match_timer.one_shot  = true
		match_timer.timeout.connect(_on_match_timeout)
		match_timer.start()
	match_running = true


func _on_players_updated() -> void:
	if Game.players.size() < 2:
		return
	Game.players_updated.disconnect(_on_players_updated)
	_setup_bars_authority()


var _timer_sync: float = 0.0

func _process(delta: float) -> void:
	if not match_running:
		return
	if multiplayer.is_server():
		hud.update_timer(match_timer.time_left)
		_timer_sync += delta
		if _timer_sync >= 1.0:  # sincroniza cada 1 segundo
			_timer_sync = 0.0
			_sync_timer.rpc(match_timer.time_left)

@rpc("authority", "unreliable")
func _sync_timer(time_left: float) -> void:
	hud.update_timer(time_left)


# ── Gol ───────────────────────────────────────────────────────────────────────

# La pelota entró al área de gol del equipo "side" → anota el equipo contrario
func _on_goal(body: Node3D, side: String) -> void:
	if not multiplayer.is_server():
		return
	# Sólo la pelota marca gol
	if not (body is RigidBody3D):
		return
	if not match_running:
		return

	if side == "A":
		score_b += 1
	else:
		score_a += 1

	Debug.log("¡GOL! Score A:%d  B:%d" % [score_a, score_b])
	_sync_score.rpc(score_a, score_b)
	_reset_ball.rpc()

	if score_a >= GOALS_TO_WIN or score_b >= GOALS_TO_WIN:
		_end_match.rpc(score_a, score_b)


@rpc("authority", "reliable", "call_local")
func _sync_score(a: int, b: int) -> void:
	score_a = a
	score_b = b
	hud.update_score(score_a, score_b)


@rpc("authority", "reliable", "call_local")
func _reset_ball() -> void:
	var football: RigidBody3D = $Ball/FootBall
	football.linear_velocity  = Vector3.ZERO
	football.angular_velocity = Vector3.ZERO
	football.global_position  = ball_spawn


# ── Fin de partido ────────────────────────────────────────────────────────────

func _on_match_timeout() -> void:
	if not multiplayer.is_server():
		return
	_end_match.rpc(score_a, score_b)


@rpc("authority", "reliable", "call_local")
func _end_match(final_a: int, final_b: int) -> void:
	match_running = false
	match_timer.stop()
	var winner: String
	if final_a > final_b:
		winner = Game.players[0].name
	elif final_b > final_a:
		winner = Game.players[1].name
	else:
		winner = "Empate"
	hud.show_end_screen(winner, final_a, final_b)


# ── Skill (placeholder) ───────────────────────────────────────────────────────

@rpc("any_peer", "reliable")
func skill() -> void:
	if not skill_timer.is_stopped():
		return
	skill_timer.start()
	Debug.log("Skill")


# ── Barras / spawn ────────────────────────────────────────────────────────────

func _setup_bars_authority() -> void:
	Game.sort_players()
	$Ball/FootBall.set_multiplayer_authority(1)
	$FieldV2/Bar.set_multiplayer_authority(Game.players[0].id)
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


func _spawn_players() -> void:
	pass   # formaciones comentadas igual que antes


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
