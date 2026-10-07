extends Area3D
class_name Explosion
## The moment a fighter is destroyed. tier 4 (gold) - the highest payout per
## second. BIG and brief. Not dangerous to the player (side battles are
## spectacle, not threat).

@export var type_name: String = "kill"
@export var tier: int = 4
@export var value: float = 6.0
@export var life := 1.3
@export var growth := 1.4

var _t := 0.0


func _ready() -> void:
	add_to_group("interest")
	_build()


func _build() -> void:
	var mesh := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 5.0
	ball.height = 10.0
	mesh.mesh = ball
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.4)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.65, 0.15)
	mesh.material_override = mat
	add_child(mesh)

	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 5.5
	cs.shape = sh
	add_child(cs)


func _physics_process(delta: float) -> void:
	_t += delta
	life -= delta
	var s := 1.0 + _t * growth
	scale = Vector3(s, s, s)
	if life <= 0.0:
		queue_free()
