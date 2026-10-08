extends Area3D
class_name Laser
## Filmer-targeting beam (neon green). Spans the road at streamer height and
## travels toward the player. The CAR is immune - only the standing streamer is
## hit, and ducking drops them below the beam. Duck to survive.

@export var speed := 42.0

var _runner: Node3D


func _ready() -> void:
	add_to_group("damaging")
	add_to_group("filmer")
	_build()
	_runner = get_tree().get_first_node_in_group("runner")


func _build() -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(28.0, 0.35, 1.4)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 1.0, 0.55)
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.9, 0.35)
	mesh.material_override = mat
	add_child(mesh)

	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(28.0, 0.5, 1.6)
	cs.shape = sh
	add_child(cs)


func _physics_process(delta: float) -> void:
	position.z += speed * delta
	if _runner != null and global_position.z > _runner.global_position.z + 25.0:
		queue_free()
