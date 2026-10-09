extends Area3D
class_name FilmTarget
## A filmable ground obstacle.
##   flat = false -> a solid block you must dodge; can be shot apart (hp)
##   flat = true  -> a low slab you can JUMP over (not solid)
## tier 1 -> yellow reticle.

@export var type_name: String = "debris"
@export var tier: int = 1
@export var value: float = 1.0
@export var flat: bool = false
@export var hp: int = 3

var _mat: StandardMaterial3D
var _base_emission := Color(0.5, 0.08, 0.04)


func _ready() -> void:
	add_to_group("interest")
	add_to_group("damaging")
	add_to_group("obstacle")
	if get_child_count() == 0:
		_build()


func _build() -> void:
	var size: Vector3 = Vector3(3.6, 0.5, 3.6) if flat else Vector3(2.5, 2.5, 2.5)

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.9, 0.22, 0.15)
	_mat.emission_enabled = true
	_mat.emission = _base_emission
	mesh.material_override = _mat
	add_child(mesh)

	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	add_child(cs)


## Reduce HP and flash. Returns true when it should be destroyed.
func take_hit() -> bool:
	hp -= 1
	if _mat != null:
		_mat.emission = Color(1, 1, 1)
		var tw := create_tween()
		tw.tween_property(_mat, "emission", _base_emission, 0.15)
	return hp <= 0
