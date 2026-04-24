extends Node3D

@export var ball_scene: PackedScene
@onready var ball: Node3D = $Ball
@onready var ball_spawn_point: Marker3D = $BallSpawnPoint

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
