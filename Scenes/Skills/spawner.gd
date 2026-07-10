class_name Spawner
extends Marker3D

signal skill_received

@onready var timer: Timer = $Timer
@export var skill_scene: PackedScene = preload("res://Scenes/Skills/skill_box.tscn")
@export var amount: int = 1
@export var rate: float = 0.1

var skill_count = 0


func _ready() -> void:
	if multiplayer.is_server():
		timer.start(1 / rate)
		timer.timeout.connect(_on_timeout)


func _process(delta: float) -> void:
	pass


func try_spawn() -> void:
	if not multiplayer.is_server():
		return
	if skill_count >= amount:
		return
	spawn_box.rpc()


@rpc("call_local")
func spawn_box() -> void:
	var skill_inst: SkillBox = skill_scene.instantiate()
	get_tree().current_scene.add_child(skill_inst)
	skill_inst.global_position = global_position
	skill_count += 1
	skill_inst.skill.connect(func (scene: PackedScene, bar: Bar) -> void: skill_received.emit(scene, bar))
	skill_inst.tree_exited.connect(func() -> void: skill_count -= 1)


func _on_timeout() -> void:
	try_spawn()
