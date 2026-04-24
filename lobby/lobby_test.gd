extends Node

var player_index = 1

@onready var start_game_timer: Timer = $StartGameTimer

func _ready():
	for i in Game.test_players.size():
		var test_player = Game.test_players[i]
		var player = Statics.PlayerData.new(
			0,
			test_player.name,
			i,
			test_player.role
		)
		Game.players.push_back(player)
	
	if Game.players.size() > 0:
		Game.players[0].id = 1
	
	if is_multiplayer_authority():
		multiplayer.peer_connected.connect(_on_peer_connected)
	
	if not _try_host():
		_try_join()
	
	Game.multiplayer_test = false


func _try_host() -> bool:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(Statics.PORT, Statics.MAX_CLIENTS)
	if err == OK:
		multiplayer.multiplayer_peer = peer
		Debug.add_to_window_title("Server")
		Game.update_player_id()
		_update_window_placement(0)
	return err == OK


func _try_join() -> bool:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client("localhost", Statics.PORT)
	if err == OK:
		multiplayer.multiplayer_peer = peer
	return err == OK


func _on_peer_connected(id: int) -> void:
	if multiplayer.is_server():
		Game.players[player_index].id = id
		for i in Game.players.size():
			_send_player_data_id.rpc(i, Game.players[i].id)
		player_index += 1


@rpc("reliable")
func _send_player_data_id(index, id):
	Game.players[index].id = id
	if multiplayer.get_unique_id() == id:
		Debug.add_to_window_title("Client %d" % index)
		Debug.index = index
		_update_window_placement(index)
		# Cliente confirma al servidor que recibió sus datos
		_confirm_ready.rpc_id(1)


@rpc("any_peer", "reliable")
func _confirm_ready() -> void:
	if multiplayer.is_server():
		_start_game.rpc()


@rpc("reliable", "call_local")
func _start_game() -> void:
	get_tree().change_scene_to_packed(Game.main_scene)


func _update_window_placement(index: int) -> void:
	if not Game.fill_screen:
		return
	var columns: int = ceil(sqrt(Game.players.size()))
	var rows: int = ceil(1.0 * Game.players.size() / columns)
	var x = index % columns
	var y = index / columns
	
	var screen_rect = DisplayServer.screen_get_usable_rect()
	var window_size = screen_rect.size / Vector2i(columns, rows)
	var title_size = DisplayServer.window_get_title_size(get_window().title)
	var title_size_offset = Vector2i(0, title_size.y)
	
	get_window().position = Vector2i(x, y) * window_size + title_size_offset + screen_rect.position
	get_window().size = window_size - title_size_offset
