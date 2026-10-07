extends Area3D
class_name Fighter
## One participant in a side battle. Big, filmable, and fires Tracers at its
## opponent. Not dangerous to the player.
##   HOLD     - stays put and shoots
##   APPROACH - slowly advances on its opponent
## Filming the fight is good; filming the kill is the biggest payout (Explosion).

enum Behavior { HOLD, APPROACH }

@export var team := 0
@export var team_color := Color(0.3, 0.85, 1.0)
@export var hp := 5
@export var fire_interval := 0.7
@export var tracer_speed := 42.0
@export var type_name: String = "fighter"
@export var value: float = 1.4

@export var behavior: Behavior = Behavior.HOLD
@export var approach_speed := 4.0
@export var stop_distance := 7.0

var target: Fighter
var tier := 2
var _cool := 0.0


func _ready() -> void:
	add_to_group("interest")
	_build()
	_cool = randf_range(0.1, fire_interval)


func _build() -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(3.0, 3.0, 3.0)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = team_color
	mat.emission_enabled = true
	mat.emission = team_color * 0.18
	mesh.material_override = mat
	add_child(mesh)

	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(3.3, 3.3, 3.3)
	cs.shape = sh
	add_child(cs)


func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return

	if behavior == Behavior.APPROACH:
		var to := target.global_position - global_position
		var d := to.length()
		if d > stop_distance:
			global_position += to.normalized() * approach_speed * delta

	_cool -= delta
	if _cool <= 0.0:
		_cool = fire_interval
		_fire()


func _fire() -> void:
	var t := Tracer.new()
	get_parent().add_child(t)
	t.global_position = global_position
	t.target = target
	t.speed = tracer_speed
	t.team_color = team_color


func take_hit() -> void:
	hp -= 1
	if hp <= 2:
		tier = 3
		value = 3.0
	if hp <= 0:
		_spawn_explosion()
		queue_free()


## The kill: a big, brief, gold point of interest to capture.
func _spawn_explosion() -> void:
	var ex := Explosion.new()
	get_parent().add_child(ex)
	ex.global_position = global_position
