extends Node3D
## Blockout hover truck: an armoured bed with side cover, a low tailgate, and a
## turret ring at the front. The filmer stands in the bed; ducking sinks them
## behind the side armour. Pure primitives - replace with real art later.
##
## Forward is -Z (the chase camera sits behind at +Z, looking into the bed).

@export var body_color := Color(0.30, 0.33, 0.26)   # olive armour
@export var bed_width := 2.2
@export var bed_length := 2.8
@export var wall_height := 0.95
@export var hover_color := Color(0.2, 0.9, 1.0)


func _ready() -> void:
	var armor := _mat(body_color)
	var dark := _mat(Color(0.13, 0.14, 0.13))
	var glow := _mat(hover_color, true)

	# --- hover chassis ---
	_box(Vector3(2.9, 0.3, 4.6), dark, Vector3(0, 0.15, 0))          # skirt
	_box(Vector3(2.6, 0.55, 5.0), armor, Vector3(0, 0.5, 0))         # hull
	for sx in [-1.0, 1.0]:
		for sz in [-1.8, 1.8]:
			_cyl(0.5, 0.2, glow, Vector3(sx, 0.02, sz))              # hover pads

	# --- front (cab / hood) ---
	_box(Vector3(2.4, 0.75, 1.3), armor, Vector3(0, 0.7, -2.1))

	# --- truck bed ---
	var bed_y := 0.9
	_box(Vector3(bed_width, 0.12, bed_length), dark, Vector3(0, bed_y - 0.06, 0.5))     # floor
	for sx in [-(bed_width * 0.5 + 0.09), (bed_width * 0.5 + 0.09)]:
		_box(Vector3(0.18, wall_height, bed_length), armor, Vector3(sx, bed_y + wall_height * 0.4, 0.5))  # side cover
	_box(Vector3(bed_width + 0.2, wall_height, 0.2), armor, Vector3(0, bed_y + wall_height * 0.4, -0.9))  # bulkhead
	_box(Vector3(bed_width, 0.4, 0.18), armor, Vector3(0, bed_y + 0.2, 1.9))                              # low tailgate


func _mat(c: Color, emissive := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	if emissive:
		m.emission_enabled = true
		m.emission = c
	return m


func _box(size: Vector3, mat: StandardMaterial3D, pos: Vector3) -> void:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	m.mesh = b
	m.material_override = mat
	add_child(m)
	m.position = pos


func _cyl(radius: float, height: float, mat: StandardMaterial3D, pos: Vector3, rot := Vector3.ZERO) -> void:
	var m := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = radius
	c.bottom_radius = radius
	c.height = height
	m.mesh = c
	m.material_override = mat
	add_child(m)
	m.position = pos
	m.rotation = rot
