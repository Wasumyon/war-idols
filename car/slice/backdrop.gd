extends Node3D
## Parallax backdrop rig.
##
## The rig follows the runner on Z only. That keeps the layers ahead of you
## forever, leaves the horizon steady when you jump, and gives you real 3D
## parallax from strafing for free. Each child layer sinks at its own rate
## (see backdrop_layer.gd).
##
## To use: assign your painted PNGs to each layer's material Albedo Texture
## (Sky / Far / Mid / Near). No other setup needed.

var _runner: Node3D
var _start_z := 0.0


func _ready() -> void:
	_runner = get_tree().get_first_node_in_group("runner")
	if _runner != null:
		_start_z = _runner.global_position.z


func _process(_delta: float) -> void:
	if _runner == null:
		_runner = get_tree().get_first_node_in_group("runner")
		return
	# Follow forward travel only; leave X and Y anchored.
	global_position.z = _runner.global_position.z
	var travel: float = _start_z - _runner.global_position.z
	for child in get_children():
		if child.has_method("apply_parallax"):
			child.apply_parallax(travel)
