extends Area3D
class_name Blast
## Explosion left when a projectile destroys a solid obstacle. Damages the
## FILMER only (duck to survive) - the car is immune - and is filmable as
## spectacle.

@export var type_name: String = "blast"
@export var tier: int = 3
@export var value: float = 1.5
@export var life := 0.5

var _t := 0.0


func _ready() -> void:
	add_to_group("interest")
	add_to_group("damaging")
	add_to_group("filmer")
	_build()


func _build() -> void:
	var mesh := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 2.2
	ball.height = 4.4
	mesh.mesh = ball
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 1.0, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.9, 0.9)
	mesh.material_override = mat
	add_child(mesh)

	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 2.4
	cs.shape = sh
	add_child(cs)


func _physics_process(delta: float) -> void:
	_t += delta
	life -= delta
	scale = Vector3.ONE * (1.0 + _t * 2.5)
	if life <= 0.0:
		queue_free()
