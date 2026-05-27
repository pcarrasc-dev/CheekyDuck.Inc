extends Node3D

@onready var skill_app: Node3D = $Skills/SkillApp
@onready var sp_0: Marker3D = $"Skills/Skill SpawnPoint/SP0"
@onready var sp_1: Marker3D = $"Skills/Skill SpawnPoint/SP1"
@onready var sp_2: Marker3D = $"Skills/Skill SpawnPoint/SP2"
@onready var sp_3: Marker3D = $"Skills/Skill SpawnPoint/SP3"
@onready var skill_timer: Timer = $Skills/SkillTimer
@onready var skill_box: SkillBox = %SkillBox
@onready var skill_box_area: Area3D = $SkillBoxArea

var Skill_Marker: Array[Marker3D] = [sp_0, sp_1, sp_2, sp_3]
var Skill_Array: Array[int]

func _ready() -> void:
	Debug.log("Players al cargar: %d" % Game.players.size())
	for p in Game.players:
		Debug.log("  id:%d index:%d" % [p.id, p.index])
	
	if Game.players.size() >= 2:
		_setup_bars_authority()
	else:
		Game.players_updated.connect(_on_players_updated)

func _on_players_updated() -> void:
	if Game.players.size() < 2:
		return
	Game.players_updated.disconnect(_on_players_updated)
	_setup_bars_authority()

func _process(delta: float) -> void:
	skill.rpc_id(1)
	pass

func _setup_bars_authority() -> void:
	Game.sort_players()
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
	
@rpc("any_peer", "reliable")
func skill() -> void:
	if not skill_timer.is_stopped():
		return
	skill_timer.start()
	#skill_app.add_child(skill_box, true)
	Debug.log("Skill")

# 
@export var player_slot_spread: float = 0.8
const DEFAULT_FORMATION: Array[int] = [2, 5, 3]
var _player_scene_a: PackedScene = preload("res://Scenes/Player/player.tscn")
var _player_scene_b: PackedScene = preload("res://Scenes/Player/player_2.tscn")

func _spawn_players() -> void:
	var bars_a: Array[StaticBody3D] = [
		$FieldV2/Bar,
		$FieldV2/Bar2,
		$FieldV2/Bar3,
		$FieldV2/Bar4,
	]
	var bars_b: Array[StaticBody3D] = [
		$FieldV2/Bar5,
		$FieldV2/Bar6,
		$FieldV2/Bar7,
		$FieldV2/Bar8,
	]
	var formation_a: Array[int] = Game.get_player_formation(Game.players[0].id)
	var formation_b: Array[int] = Game.get_player_formation(Game.players[1].id)
	_spawn_team(bars_a, formation_a, _player_scene_a)
	_spawn_team(bars_b, formation_b, _player_scene_b)
	Debug.log("Spawn completado — equipo A: %s | equipo B: %s" % [str(formation_a), str(formation_b)])
	
func _spawn_team(bars: Array[StaticBody3D], formation: Array[int], scene: PackedScene) -> void:
	_spawn_in_bar(bars[0], 1, scene, -1)
	for i: int in range(3):
		_spawn_in_bar(bars[i + 1], formation[i], scene, i)

func _spawn_in_bar(bar: StaticBody3D, count: int, scene: PackedScene, bar_field_index: int = -1) ->void:
	var existing_players: int = 0
	for child: Node in bar.get_children():
		if child is Node3D:
			existing_players += 1
	if existing_players > 0:
		Debug.log("Barra '%s' ya tiene %d personajes, se omite el spawn." % [bar.name, existing_players])
		return
	var final_count: int = count
	if final_count <= 0:
		if bar_field_index >= 0 and bar_field_index < DEFAULT_FORMATION.size():
			final_count = DEFAULT_FORMATION[bar_field_index]
			Debug.log("Barra '%s': count inválido, usando fallback %d." % [bar.name, final_count])
		else:
			final_count = 1
			Debug.log("Barra '%s': count inválido sin índice de fallback, usando 1." % bar.name)
			
	var positions: Array[Vector3] = FormationSetup.get_slot_positions(
		final_count, player_slot_spread
	)
	for pos: Vector3 in positions:
		var instance: Node3D = scene.instantiate() as Node3D
		bar.add_child(instance)
		instance.position = pos
