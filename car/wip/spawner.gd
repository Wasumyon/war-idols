extends Node3D

@export var mob : PackedScene

@onready var timer: Timer = $Timer

func _ready() -> void:
	timer.start()

func _on_timer_timeout() -> void:
	var newMob = mob.instantiate()
	add_child(newMob)
	newMob.position = Vector3(position.x + randf_range(-10.0, 10.0), position.y + randf_range(0.05, 3.0), position.z)
