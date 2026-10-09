extends Node3D
## Draws the lane divider lines from Game's lane geometry, so the road markings
## can never drift from where the car drives and obstacles spawn.

func _ready() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.22, 0.24)
	var lw: float = Game.lane_width
	for i in range(1, Game.lane_count):
		var x: float = Game.lane_x(i) - lw * 0.5
		var m := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.12, 0.02, 8000.0)
		m.mesh = box
		m.material_override = mat
		add_child(m)
		m.position = Vector3(x, 0.02, -3600.0)
