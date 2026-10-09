extends Area3D
class_name Hazard
## A drone projectile. Three flavours, distinguished by colour + shape:
##   ORANGE pellet - aimed at your old position; sails overhead (near miss)
##   YELLOW pellet - led shot that hits the CAR
##   CYAN bolt     - cylinder, led shot at the FILMER; duck to avoid; car immune
##
## `filmer` marks the cyan kind (handled by the streamer hitbox, not the car).

@export var type_name: String = "pellet"
@export var tier: int = 3
@export var value: float = 1.2
@export var filmer: bool = false
@export var bolt: bool = false
@export var body_color := Color(1.0, 0.85, 0.2)

var velocity := Vector3(0, 0, 50.0)
var life := 8.0
var _runner: Node3D


func _ready() -> void:
	add_to_group("interest")
	add_to_group("damaging")
	if filmer:
		add_to_group("filmer")
	else:
		add_to_group("hazard")
	_build()
	_runner = get_tree().get_first_node_in_group("runner")


func _build() -> void:
	var mesh := MeshInstance3D.new()
	if bolt:
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.28
		cyl.bottom_radius = 0.28
		cyl.height = 3.0
		mesh.mesh = cyl
		mesh.rotation = Vector3(-PI / 2.0, 0, 0)   # long axis along travel
	else:
		var ball := SphereMesh.new()
		ball.radius = 0.8
		ball.height = 1.6
		mesh.mesh = ball
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.emission_enabled = true
	mat.emission = body_color
	mesh.material_override = mat
	add_child(mesh)

	var cs := CollisionShape3D.new()
	if bolt:
		var bs := BoxShape3D.new()
		bs.size = Vector3(0.6, 0.6, 3.2)
		cs.shape = bs
	else:
		var sh := SphereShape3D.new()
		sh.radius = 0.9
		cs.shape = sh
	add_child(cs)


func _physics_process(delta: float) -> void:
	if bolt and velocity.length() > 0.01:
		look_at(global_position + velocity.normalized(), Vector3.UP)
	global_position += velocity * delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return

	# Pellets smash solid (tall) obstacles on contact, leaving a blast.
	if not filmer:
		for o in get_tree().get_nodes_in_group("obstacle"):
			if o.flat:
				continue   # low slabs are jumpable, not solid
			if global_position.distance_to(o.global_position) < 2.6:
				var at: Vector3 = o.global_position
				o.queue_free()
				var b := Blast.new()
				get_parent().add_child(b)
				b.global_position = at
				queue_free()
				return

	if _runner != null and global_position.z > _runner.global_position.z + 25.0:
		queue_free()
