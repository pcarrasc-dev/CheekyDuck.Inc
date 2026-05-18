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
	
@rpc("any_peer", "reliable")
func skill() -> void:
	if not skill_timer.is_stopped():
		return
	skill_timer.start()
	#skill_app.add_child(skill_box, true)
	Debug.log("Skill")
