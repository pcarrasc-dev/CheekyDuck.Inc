extends CanvasLayer
class_name HUD_Tutorial

@export var player_skills_scene: PackedScene

@onready var score_label: Label   = %ScoreLabel
@onready var timer_label: Label   = %TimerLabel
@onready var end_panel: Panel     = %EndPanel
@onready var winner_label: Label  = %WinnerLabel
@onready var final_score_label: Label = %FinalScoreLabel
@onready var back_button: Button  = %BackButton
@onready var background: TextureRect = $MarginContainer/Background
@onready var escudo: TextureRect = $MarginContainer/EscudoContainer/Escudo
@onready var fast_ball: TextureRect = $MarginContainer/BallContainer/FastBall
@onready var double_ball: TextureRect = $MarginContainer/DoubleContainer/DoubleBall


func _ready() -> void:
	end_panel.hide()
	background.hide()
	double_ball.hide()
	fast_ball.hide()
	escudo.hide()
	update_score(0, 0)
	update_timer(180.0)
	back_button.pressed.connect(_on_back_pressed)


func update_score(a: int, b: int) -> void:
	score_label.text = "%d  —  %d" % [a, b]


func update_timer(seconds_left: float) -> void:
	var s := int(seconds_left)
	timer_label.text = "%d:%02d" % [s / 60, s % 60]

func update_skill(a: bool, scene: PackedScene) -> void:
	if a:
		background.show()
		if scene.instantiate() is Shield:
			escudo.show()
		elif scene.instantiate() is Fast_Ball:
			fast_ball.show()
		elif scene.instantiate() is Double_Ball_Tutorial:
			double_ball.show()
	else:
		background.hide()
		escudo.hide()
		fast_ball.hide()
		double_ball.hide()
			

func show_end_screen(winner: String, final_a: int, final_b: int) -> void:
	end_panel.show()
	if winner == "Empate":
		winner_label.text = "¡Empate!"
	else:
		winner_label.text = "¡Ganó %s!" % winner
	final_score_label.text = "%d  —  %d" % [final_a, final_b]


func _on_back_pressed() -> void:
	Lobby.go_to_menu()
