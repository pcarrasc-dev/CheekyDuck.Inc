extends Node3D

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
