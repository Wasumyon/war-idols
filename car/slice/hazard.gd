extends Area3D
class_name Hazard
## A pellet. Fast, filmable (tier 3 -> RED reticle), damages on contact.
## `life` lets a shot expire early (used for "lands in the ground in front").

@export var type_name: String = "pellet"
@export var tier: int = 3
@export var value: float = 1.2

var velocity := Vector3(0, 0, 50.0)
var life := 8.0
var _runner: Node3D


func _ready() -> void:
	add_to_group("interest")
	add_to_group("damaging")
	add_to_group("hazard")
	_build()
	_runner = get_tree().get_first_node_in_group("runner")


func _build() -> void:
	var mesh := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.8
	ball.height = 1.6
	mesh.mesh = ball
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.6, 0.1)
	mesh.material_override = mat
	add_child(mesh)

	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 0.9
	cs.shape = sh
	add_child(cs)


func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	if _runner != null and global_position.z > _runner.global_position.z + 25.0:
		queue_free()
