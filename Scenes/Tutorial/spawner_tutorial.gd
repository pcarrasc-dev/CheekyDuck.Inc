class_name Spawner_Tutorial
extends Marker3D

@onready var multiplayer_spawner: Node3D = $MultiplayerSpawner
@onready var timer: Timer = $Timer
@export var skill_scene: PackedScene = preload("res://Scenes/Tutorial/skill_box_tutorial.tscn")
@export var amount: int = 1
@export var rate: float = 1

var skill_count = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer.start(1 / rate)
	timer.timeout.connect(_on_timeout)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func try_spawn() -> void:
	if skill_count >= amount:
		return
	var check_radius: float = SkillBox_Tutorial.radius
	
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var params: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = 4
	var t: Transform3D = Transform3D.IDENTITY
	t.origin = global_position
	params.transform = t
	var square_shape: BoxShape3D = BoxShape3D.new()
	square_shape.size = Vector3.ONE * check_radius
	params.shape = square_shape
	var results: Array[Dictionary] = space_state.intersect_shape(params)
	for result: Dictionary in results:
		Debug.log(result.collider.name)
	if results.size() > 0:
		return
	spawn(global_position)

func spawn(pos: Vector3) -> void:
	var skill_inst: SkillBox_Tutorial = skill_scene.instantiate()
	skill_inst.global_position = pos
	multiplayer_spawner.add_child(skill_inst, true)
	skill_count += 1
	skill_inst.tree_exited.connect(func() -> void: skill_count -= 1)

func _on_timeout() -> void:
	try_spawn()
	pass
