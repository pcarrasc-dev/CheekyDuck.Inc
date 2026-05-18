extends CanvasLayer

@export var player_skills_scene: PackedScene
@onready var skills_hud_container: VBoxContainer = $MarginContainer/SkillsHudContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for player_data: Statics.PlayerData: Game.players:
		var player_skills_inst: PlayerSkill = player_skills_scene.instantiate()
		skills_hud_container.add_child(player_skills_inst)
		player_skills_inst
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
