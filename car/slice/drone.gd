extends Area3D
class_name Drone
## Flying enemy, OFF the lane grid. Two modes:
##   CROSS - sweeps laterally across the view (hard, brief) -> tier 3 (red)
##   HOVER - flies in and hangs there menacing you for a while -> tier 2 (orange)
##
## Fires bursts. Aimed shots vary:
##   current (40%) - at where you ARE, so it sails past if you keep moving
##   lead    (35%) - predicted ahead of you: a real peril
##   short   (25%) - into the ground in front of you (a near miss)

enum Mode { CROSS, HOVER }
enum Shot { ORANGE, YELLOW, CYAN, BEAM }

@export var mode: Mode = Mode.CROSS
@export var shot: Shot = Shot.YELLOW
@export var type_name: String = "drone"
@export var tier: int = 3
@export var value: float = 2.5

@export var lateral_speed: float = 22.0
@export var approach_speed: float = 8.0
@export var hover_distance: float = 40.0
@export var hover_time: float = 4.0
@export var exit_speed: float = 60.0

@export var fire_interval: float = 2.0
@export var burst_count: int = 3
@export var burst_gap: float = 0.12
@export var projectile_speed: float = 48.0
@export var lead_time: float = 0.45
@export var short_ahead: float = 16.0
@export var lane_count: int = 5
@export var lane_width: float = 4.0
@export var max_active_pellets: int = 14
@export var min_range: float = 16.0   # deadzone: holds fire when this close
@export var charge_time: float = 1.5
@export var beam_width: float = 8.0
@export var tell_time: float = 0.6  # red-cross tell before a pellet burst

var _runner: Node3D
var _cool := 0.0
var _burst_left := 0
var _burst_timer := 0.0
var _phase := 0.0
var _t := 0.0
var _hover_t := 0.0
var _leaving := false
var _inited := false
var _base_x := 0.0
var _base_y := 0.0
var _have_prev := false
var _prev_pos := Vector3.ZERO
var _runner_vel := Vector3.ZERO
var _charging := false
var _charge_t := 0.0
var _telling := false
var _tell_t := 0.0
var _mat: StandardMaterial3D
var _tell: Node3D
var _base_emission := Color(0.35, 0.08, 0.5)
var _base_albedo := Color(0.75, 0.25, 0.9)


func _ready() -> void:
	add_to_group("interest")
	add_to_group("damaging")
	if mode == Mode.HOVER:
		add_to_group("hover_drone")
	else:
		add_to_group("cross_drone")
	_build()
	_runner = get_tree().get_first_node_in_group("runner")
	_cool = randf_range(0.5, fire_interval)
	_phase = randf() * TAU


func _build() -> void:
	var mesh := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 1.6
	ball.height = 2.4
	mesh.mesh = ball
	var mat := StandardMaterial3D.new()
	var base := _shot_color()
	_base_albedo = base
	_base_emission = base * 0.55
	mat.albedo_color = _base_albedo
	mat.emission_enabled = true
	mat.emission = _base_emission
	mesh.material_override = mat
	_mat = mat
	add_child(mesh)

	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 2.0
	cs.shape = sh
	add_child(cs)

	# Red cross "about to fire" tell, shown in front of the drone.
	_tell = Node3D.new()
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(1.0, 0.1, 0.1)
	cmat.emission_enabled = true
	cmat.emission = Color(1.0, 0.05, 0.05)
	cmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var hbar := MeshInstance3D.new()
	var hb := BoxMesh.new()
	hb.size = Vector3(2.8, 0.4, 0.4)
	hbar.mesh = hb
	hbar.material_override = cmat
	_tell.add_child(hbar)
	var vbar := MeshInstance3D.new()
	var vb := BoxMesh.new()
	vb.size = Vector3(0.4, 2.8, 0.4)
	vbar.mesh = vb
	vbar.material_override = cmat
	_tell.add_child(vbar)
	_tell.position = Vector3(0, 0, 2.0)
	_tell.visible = false
	add_child(_tell)


func _physics_process(delta: float) -> void:
	if _runner == null:
		return
	if not _inited:
		_base_x = global_position.x
		_base_y = global_position.y
		_inited = true

	# Track the runner's velocity so we can lead our shots.
	var rp := _runner.global_position
	if _have_prev:
		var dt: float = max(delta, 0.0001)
		_runner_vel = (rp - _prev_pos) / dt
	_prev_pos = rp
	_have_prev = true

	_t += delta
	match mode:
		Mode.CROSS:
			_cross(delta)
		Mode.HOVER:
			_hover(delta)
	_tick_fire(delta)


func _cross(delta: float) -> void:
	position.x += lateral_speed * delta
	position.z += approach_speed * delta
	position.y = _base_y + sin(_t * 2.0) * 1.5
	if abs(position.x) > 42.0 or global_position.z > _runner.global_position.z + 15.0:
		queue_free()


func _hover(delta: float) -> void:
	if _leaving:
		position.z += exit_speed * delta
		if global_position.z > _runner.global_position.z + 15.0:
			queue_free()
		return
	var target_z: float = _runner.global_position.z - hover_distance
	position.z = lerp(position.z, target_z, clamp(4.0 * delta, 0.0, 1.0))
	position.x = _base_x + sin(_t * 1.3 + _phase) * 7.0
	position.y = _base_y + sin(_t * 2.0) * 1.5
	_hover_t += delta
	if _hover_t >= hover_time:
		_leaving = true


func _tick_fire(delta: float) -> void:
	if mode == Mode.HOVER and _leaving:
		return
	if _charging:
		_charge_t += delta
		# Three white flashes across charge_time, then fire.
		_set_flash(int(_charge_t / 0.25) % 2 == 0)
		if _charge_t >= charge_time:
			_charging = false
			_set_flash(false)
			_fire_beam()
		return
	if _telling:
		# Red cross sparks TWICE, then the burst.
		_tell_t += delta
		if _tell_t >= tell_time:
			_telling = false
			_tell.visible = false
			_burst_left = burst_count
			_burst_timer = 0.0
		else:
			_tell.visible = int(_tell_t / 0.15) % 2 == 0
		return
	if _burst_left > 0:
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			_fire()
			_burst_left -= 1
			_burst_timer = burst_gap
	else:
		_cool -= delta
		if _cool <= 0.0:
			_cool = fire_interval
			if shot == Shot.BEAM:
				_charging = true
				_charge_t = 0.0
			else:
				_telling = true
				_tell_t = 0.0
				_tell.visible = true


func _set_flash(on: bool) -> void:
	if _mat == null:
		return
	_mat.emission = Color(1, 1, 1) if on else _base_emission
	_mat.albedo_color = Color(1, 1, 1) if on else _base_albedo


## Body colour advertises this drone's munition, so you can read the threat.
func _shot_color() -> Color:
	match shot:
		Shot.ORANGE:
			return Color(1.0, 0.55, 0.1)
		Shot.YELLOW:
			return Color(1.0, 0.9, 0.2)
		Shot.CYAN:
			return Color(0.2, 1.0, 1.0)
		_:
			return Color(0.75, 0.25, 0.9)   # beam drone stays purple


func _fire_beam() -> void:
	if _runner != null and global_position.distance_to(_runner.global_position) < min_range:
		return   # deadzone: too close to fire
	var l := Laser.new()
	l.width = beam_width
	l.speed = projectile_speed * 1.4
	get_parent().add_child(l)
	l.global_position = Vector3(global_position.x, 1.62, global_position.z)


func _fire() -> void:
	if get_tree().get_nodes_in_group("hazard").size() >= max_active_pellets:
		return
	if _runner == null:
		return
	if global_position.distance_to(_runner.global_position) < min_range:
		return   # deadzone: too close to fire

	var rp: Vector3 = _runner.global_position
	var h := Hazard.new()
	var aim: Vector3 = rp

	match shot:
		Shot.ORANGE:
			# Aimed at your old position; sails overhead.
			h.body_color = Color(1.0, 0.5, 0.05)
			aim = rp + Vector3(0, 2.6, 0)
		Shot.YELLOW:
			# Led shot that hits the car.
			h.body_color = Color(1.0, 0.95, 0.25)
			aim = rp + _runner_vel * lead_time + Vector3(0, 0.7, 0)
		Shot.CYAN:
			# Led bolt at the filmer; car immune; duck to avoid.
			h.body_color = Color(0.2, 1.0, 1.0)
			h.filmer = true
			h.bolt = true
			aim = rp + _runner_vel * lead_time + Vector3(0, 1.45, 0)
		_:
			return

	get_parent().add_child(h)
	h.global_position = global_position
	h.velocity = (aim - global_position).normalized() * projectile_speed
