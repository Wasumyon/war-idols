extends Node3D
class_name Tracer
## A cheap visual projectile for side battles. Flies to its Fighter target and
## applies damage. NOT filmable and NOT dangerous to the player.

var target: Fighter
var speed := 40.0
var team_color := Color(1, 1, 1)
var _life := 3.0


func _ready() -> void:
	var mesh := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.25
	ball.height = 0.5
	mesh.mesh = ball
	var mat := StandardMaterial3D.new()
	mat.albedo_color = team_color
	mat.emission_enabled = true
	mat.emission = team_color
	mesh.material_override = mat
	add_child(mesh)


func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		queue_free()
		return
	var to := target.global_position - global_position
	if to.length() < 0.7:
		target.take_hit()
		queue_free()
		return
	global_position += to.normalized() * speed * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()
