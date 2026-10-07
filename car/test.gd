extends Node3D

@onready var path_3d: Path3D = $Path3D
@onready var path_follow_3d: PathFollow3D = $Path3D/PathFollow3D

func get_path_direction (pos: Vector3) -> Vector3:
	var offset = path_3d.curve.get_closest_offset(pos)
	path_follow_3d.h_offset = offset
	return -path_follow_3d.global_transform.basis.z
