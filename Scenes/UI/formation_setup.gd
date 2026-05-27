class_name FormationSetup
extends CanvasLayer

## Emitida cuando este jugador confirma su formación y ambos están listos.
## El servidor la usa para hacer la transición a la escena de juego.
signal all_players_ready

# ── Constantes ───────────────────────────────────────────────────────────────

## Número total de personajes distribuibles (sin contar el portero)
const OUTFIELD_PLAYERS: int = 10
## Número de barras de campo (sin contar la del portero)
const FIELD_BARS: int = 3
## Mínimo de personajes por barra de campo
const MIN_PER_BAR: int = 1
## Máximo de personajes por barra de campo
const MAX_PER_BAR: int = 5

# ── Estado interno ────────────────────────────────────────────────────────────

## Cantidad de personajes asignados a cada barra de campo (índices 0, 1, 2 → barras 2, 3, 4)
var _bar_counts: Array[int] = [3, 4, 3]

## Flags de "listo" por peer id: { peer_id: bool }
var _ready_flags: Dictionary = {}

# ── Referencias a nodos UI ────────────────────────────────────────────────────

@onready var _bar2_label: Label        = %Bar2CountLabel
@onready var _bar3_label: Label        = %Bar3CountLabel
@onready var _bar4_label: Label        = %Bar4CountLabel
@onready var _remaining_label: Label   = %RemainingLabel
@onready var _ready_button: Button     = %ReadyButton
@onready var _status_label: Label      = %StatusLabel

@onready var _bar2_minus: Button = %Bar2Minus
@onready var _bar2_plus:  Button = %Bar2Plus
@onready var _bar3_minus: Button = %Bar3Minus
@onready var _bar3_plus:  Button = %Bar3Plus
@onready var _bar4_minus: Button = %Bar4Minus
@onready var _bar4_plus:  Button = %Bar4Plus

# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_connect_buttons()
	_refresh_ui()
	_ready_button.pressed.connect(_on_ready_pressed)
	all_players_ready.connect(_on_all_players_ready)


# Conecta todos los botones +/- de las tres barras de campo
func _connect_buttons() -> void:
	_bar2_minus.pressed.connect(func() -> void: _change_count(0, -1))
	_bar2_plus.pressed.connect(func()  -> void: _change_count(0,  1))
	_bar3_minus.pressed.connect(func() -> void: _change_count(1, -1))
	_bar3_plus.pressed.connect(func()  -> void: _change_count(1,  1))
	_bar4_minus.pressed.connect(func() -> void: _change_count(2, -1))
	_bar4_plus.pressed.connect(func()  -> void: _change_count(2,  1))


# Intenta modificar el conteo de la barra `bar_idx` en `delta` (+1 / -1).
# Respeta los límites mínimo/máximo y el total disponible.
func _change_count(bar_idx: int, delta: int) -> void:
	var new_val: int = _bar_counts[bar_idx] + delta
	if new_val < MIN_PER_BAR or new_val > MAX_PER_BAR:
		return
	var new_total: int = _get_total() + delta
	if new_total > OUTFIELD_PLAYERS:
		return
	_bar_counts[bar_idx] = new_val
	_refresh_ui()


# Actualiza todos los labels y el estado del botón Listo
func _refresh_ui() -> void:
	_bar2_label.text = str(_bar_counts[0])
	_bar3_label.text = str(_bar_counts[1])
	_bar4_label.text = str(_bar_counts[2])

	var remaining: int = OUTFIELD_PLAYERS - _get_total()
	_remaining_label.text = "Restantes: %d" % remaining
	_ready_button.disabled = (remaining != 0)

	# Habilitar/deshabilitar botones según límites
	_bar2_minus.disabled = (_bar_counts[0] <= MIN_PER_BAR)
	_bar2_plus.disabled  = (_bar_counts[0] >= MAX_PER_BAR or remaining == 0)
	_bar3_minus.disabled = (_bar_counts[1] <= MIN_PER_BAR)
	_bar3_plus.disabled  = (_bar_counts[1] >= MAX_PER_BAR or remaining == 0)
	_bar4_minus.disabled = (_bar_counts[2] <= MIN_PER_BAR)
	_bar4_plus.disabled  = (_bar_counts[2] >= MAX_PER_BAR or remaining == 0)


func _get_total() -> int:
	var total: int = 0
	for count: int in _bar_counts:
		total += count
	return total


# ── Lógica de red ─────────────────────────────────────────────────────────────

# Llamado cuando el jugador local presiona "Listo"
func _on_ready_pressed() -> void:
	_ready_button.disabled = true
	_status_label.text = "Esperando al otro jugador..."

	# Envía la formación al servidor
	var formation: Array[int] = _bar_counts.duplicate()
	_send_formation.rpc_id(1, formation)


# RPC al servidor: recibe la formación de un peer y guarda el flag
@rpc("any_peer", "reliable")
func _send_formation(formation: Array[int]) -> void:
	if not multiplayer.is_server():
		return

	var sender_id: int = multiplayer.get_remote_sender_id()
	Game.set_player_formation(sender_id, formation)
	_ready_flags[sender_id] = true

	Debug.log("Formación recibida de peer %d: %s" % [sender_id, str(formation)])

	if _ready_flags.size() >= 2:
		_notify_all_ready.rpc()


# RPC del servidor a todos: ambos jugadores confirmaron, se puede pasar al juego
@rpc("authority", "reliable")
func _notify_all_ready() -> void:
	all_players_ready.emit()


# ── API pública ───────────────────────────────────────────────────────────────

## Devuelve las posiciones locales predefinidas para `count` personajes en una barra.
## Las posiciones están distribuidas uniformemente a lo largo del eje Z local de la barra,
## dentro del rango [-half_spread, +half_spread].
static func get_slot_positions(count: int, half_spread: float = 0.8) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	if count <= 0:
		return positions
	if count == 1:
		positions.append(Vector3.ZERO)
		return positions
	var step: float = (half_spread * 2.0) / float(count - 1)
	for i: int in range(count):
		var z: float = -half_spread + step * float(i)
		positions.append(Vector3(0.0, 0.0, z))
	return positions
	
func _on_all_players_ready() -> void:
	get_tree().change_scene_to_file("res://Scenes/Escena.tscn")
	
