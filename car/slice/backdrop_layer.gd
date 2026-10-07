extends MeshInstance3D
## One parallax backdrop layer.
##
## Assign a painted PNG to this mesh's material (Albedo Texture). The mesh is
## sized generously so small scroll offsets never reveal an edge; the road plane
## hides everything below the horizon.
##
## forward_factor = how fast this layer sinks as you advance. Nearer layers
## should use a larger value; the sky should be almost 0.

@export var forward_factor := 0.02

var _base_y := 0.0


func _ready() -> void:
	_base_y = position.y


func apply_parallax(travel: float) -> void:
	position.y = _base_y - travel * forward_factor
