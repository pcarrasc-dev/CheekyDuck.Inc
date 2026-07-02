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

func update_score(a: int, b: int) -> void:
	score_label.text = "%d  —  %d" % [a, b]
