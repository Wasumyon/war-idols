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

@export var mode: Mode = Mode.CROSS
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
@export var beam_attack: bool = false # charge (3 flashes) then fire a beam
@export var charge_time: float = 1.5
@export var beam_width: float = 8.0

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
var _mat: StandardMaterial3D
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
	mat.albedo_color = Color(0.75, 0.25, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.35, 0.08, 0.5)
	mesh.material_override = mat
	_mat = mat
	add_child(mesh)

	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 2.0
	cs.shape = sh
	add_child(cs)


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
			if beam_attack:
				_charging = true
				_charge_t = 0.0
			else:
				_burst_left = burst_count
				_burst_timer = 0.0


func _set_flash(on: bool) -> void:
	if _mat == null:
		return
	_mat.emission = Color(1, 1, 1) if on else _base_emission
	_mat.albedo_color = Color(1, 1, 1) if on else _base_albedo


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
	if _runner != null and global_position.distance_to(_runner.global_position) < min_range:
		return   # deadzone: too close to fire
	var h := Hazard.new()
	get_parent().add_child(h)
	h.velocity = Vector3.ZERO

	if randf() < 0.5:
		# Straight down the nearest lane, at car height.
		var nearest := int(round(global_position.x / lane_width + (lane_count - 1) / 2.0))
		nearest = clampi(nearest, 0, lane_count - 1)
		var x := (nearest - (lane_count - 1) / 2.0) * lane_width
		h.global_position = Vector3(x, 0.8, global_position.z)
		h.velocity = Vector3(0, 0, projectile_speed)
		return

	# Aimed shot: current position / lead / short.
	var pick := randf()
	var aim_point: Vector3 = _runner.global_position
	if pick >= 0.4 and pick < 0.75:
		aim_point = _runner.global_position + _runner_vel * lead_time
	elif pick >= 0.75:
		aim_point = _runner.global_position + Vector3(0, 0, -short_ahead)
		aim_point.y = 0.2

	h.global_position = global_position
	var to := aim_point - global_position
	h.velocity = to.normalized() * projectile_speed
	if pick >= 0.75:
		h.life = to.length() / projectile_speed   # vanish where it "hits the ground"
