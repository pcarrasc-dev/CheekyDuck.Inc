extends CanvasLayer

@export var player_skills_scene: PackedScene

@onready var skills_hud_container: VBoxContainer = $MarginContainer/SkillsHudContainer
@onready var score_label: Label   = %ScoreLabel
@onready var timer_label: Label   = %TimerLabel
@onready var end_panel: Panel     = %EndPanel
@onready var winner_label: Label  = %WinnerLabel
@onready var final_score_label: Label = %FinalScoreLabel
@onready var back_button: Button  = %BackButton


func _ready() -> void:
	end_panel.hide()
	update_score(0, 0)
	update_timer(180.0)
	back_button.pressed.connect(_on_back_pressed)


func update_score(a: int, b: int) -> void:
	score_label.text = "%d  —  %d" % [a, b]


func update_timer(seconds_left: float) -> void:
	var s := int(seconds_left)
	timer_label.text = "%d:%02d" % [s / 60, s % 60]


func show_end_screen(winner: String, final_a: int, final_b: int) -> void:
	end_panel.show()
	if winner == "Empate":
		winner_label.text = "¡Empate!"
	else:
		winner_label.text = "¡Ganó %s!" % winner
	final_score_label.text = "%d  —  %d" % [final_a, final_b]


func _on_back_pressed() -> void:
	if multiplayer.is_server():
		Lobby.go_to_lobby()
	else:
		Lobby.go_to_join()
