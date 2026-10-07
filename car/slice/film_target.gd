extends Area3D
class_name FilmTarget
## A filmable ground obstacle. Two shapes:
##   flat = false -> a block you must dodge
##   flat = true  -> a low slab you can JUMP over
## tier 1 -> yellow reticle.

@export var type_name: String = "debris"
@export var tier: int = 1
@export var value: float = 1.0
@export var flat: bool = false


func _ready() -> void:
	add_to_group("interest")
	add_to_group("damaging")
	if get_child_count() == 0:
		_build()


func _build() -> void:
	var size: Vector3 = Vector3(3.6, 0.5, 3.6) if flat else Vector3(2.5, 2.5, 2.5)

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.22, 0.15)
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.08, 0.04)
	mesh.material_override = mat
	add_child(mesh)

	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	add_child(cs)
