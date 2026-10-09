extends Node3D

var speed: float

func _ready() -> void:
	speed = randf_range(5.0, 20.0)

func _process(delta: float) -> void:
	position.z += speed * delta
