extends Area3D
class_name HazardEmitter
## Tall orange tower. Sits IN a lane, is filmable (tier 2 -> orange reticle),
## and fires a single yellow pellet straight down its lane at car height.

@export var type_name: String = "emitter"
@export var tier: int = 2
@export var value: float = 2.0
@export var fire_interval: float = 1.4
@export var projectile_speed: float = 52.0
@export var max_active_pellets: int = 14   # global cap; firing stops while at cap

var _cooldown := 0.0
var _runner: Node3D


func _ready() -> void:
	add_to_group("interest")
	add_to_group("damaging")
	_build()
	_runner = get_tree().get_first_node_in_group("runner")
	_cooldown = randf_range(0.3, fire_interval)


func _build() -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(3.2, 7.0, 3.2)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.55, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(0.6, 0.3, 0.03)
	mesh.material_override = mat
	add_child(mesh)

	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 3.0
	cs.shape = sh
	add_child(cs)


func _process(delta: float) -> void:
	if _runner == null:
		return
	if global_position.z > _runner.global_position.z + 8.0:
		return   # already behind the player: stop firing
	_cooldown -= delta
	if _cooldown <= 0.0:
		_cooldown = fire_interval
		_fire()


func _fire() -> void:
	if get_tree().get_nodes_in_group("hazard").size() >= max_active_pellets:
		return   # too many pellets in the air already
	var h := Hazard.new()
	get_parent().add_child(h)
	h.global_position = Vector3(global_position.x, 0.8, global_position.z + 3.5)
	h.velocity = Vector3(0, 0, projectile_speed)
