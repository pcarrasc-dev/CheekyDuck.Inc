class_name Spawner
extends Marker3D

signal skill_received

@onready var timer: Timer = $Timer
@export var skill_scene: PackedScene = preload("res://Scenes/Skills/skill_box.tscn")
@export var amount: int = 1
@export var rate: float = 0.1

var skill_count = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if multiplayer.is_server():
		timer.start(1 / rate)
		timer.timeout.connect(_on_timeout)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func try_spawn() -> void:
	if skill_count >= amount:
		return
	spawn.rpc(global_position)

@rpc("call_local", "authority")
func spawn(pos: Vector3) -> void:
	var skill_inst: SkillBox = skill_scene.instantiate()
	add_child(skill_inst)
	skill_inst.global_scale(Vector3.ONE * 1.5)
	skill_inst.global_position = pos
	Debug.log("spawn")
	Debug.log(skill_inst.global_position)
	skill_count += 1
	skill_inst.skill.connect(func (scene: PackedScene, bar: Bar) -> void: skill_received.emit(scene, bar))
	skill_inst.tree_exited.connect(func() -> void: skill_count -= 1)

func _on_timeout() -> void:
	try_spawn()
	pass
