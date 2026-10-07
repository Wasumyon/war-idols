extends Node3D
class_name LaneSpawner
## Spawns the world ahead of the runner.
##
## HIERARCHY / FOCUS: side battles come in CLUSTERS (a battle line, not a lone
## pocket), and only one cluster runs at a time - while it does, air spawns are
## slowed so the player reads one feature, not three.
##
##  GROUND (every row_spacing): FilmTarget or HazardEmitter, IN a lane.
##  AIR    (every air_interval): a Drone OFF the grid - CROSS or HOVER.
##  BATTLE (every battle_interval): a cluster of side battles, far outside the
##         lane corridor.

@export var lane_count := 5
@export var lane_width := 4.0

# --- ground layer ---
@export var spawn_ahead := 150.0
@export var row_spacing := 20.0
@export var spawn_chance := 0.9
@export var emitter_chance := 0.3
@export var emitter_min_gap := 55.0
@export var flat_chance := 0.65

# --- air layer ---
@export var air_interval := 2.4
@export var air_spawn_ahead := 130.0
@export var hover_chance := 0.4
@export var max_hover := 2

# --- side battle clusters (far outside the lane corridor) ---
@export var battle_interval := 5.5
@export var cluster_min := 2
@export var cluster_max := 4
@export var pocket_x := 55.0
@export var cluster_x_spread := 14.0
@export var cluster_z_spread := 28.0
@export var cluster_z_min := 100.0
@export var cluster_z_max := 150.0

var lane_weights := [3.0, 2.0, 1.0, 2.0, 3.0]

var _runner: Node3D
var _next_z := 0.0
var _started := false
var _cleanup := 0.0
var _air_cool := 0.0
var _battle_cool := 0.0
var _last_emitter_z := 100000.0
var _last_lane := -1


func _ready() -> void:
	_runner = get_tree().get_first_node_in_group("runner")


func lane_x(index: int) -> float:
	return (index - (lane_count - 1) / 2.0) * lane_width


func _process(delta: float) -> void:
	if _runner == null:
		_runner = get_tree().get_first_node_in_group("runner")
		return
	if not _started:
		_next_z = _runner.global_position.z - spawn_ahead
		_started = true

	# --- ground rows ---
	var horizon := _runner.global_position.z - spawn_ahead
	while _next_z > horizon:
		_spawn_row(_next_z)
		_next_z -= row_spacing

	var feature_busy := get_tree().get_nodes_in_group("pocket").size() > 0

	# --- air layer (slowed while a battle cluster is running) ---
	_air_cool -= delta
	if _air_cool <= 0.0:
		_air_cool = air_interval * randf_range(0.7, 1.3)
		if feature_busy:
			_air_cool *= 2.0
		else:
			_spawn_air()

	# --- battle clusters (only when nothing else is featuring) ---
	_battle_cool -= delta
	if _battle_cool <= 0.0:
		_battle_cool = battle_interval * randf_range(0.8, 1.2)
		if not feature_busy:
			_spawn_battle()

	# --- recycle what the player has passed ---
	_cleanup -= delta
	if _cleanup <= 0.0:
		_cleanup = 1.0
		for child in get_children():
			if child is Node3D and child.global_position.z > _runner.global_position.z + 40.0:
				child.queue_free()


func _spawn_row(z: float) -> void:
	if randf() > spawn_chance:
		return

	var lane := _pick_lane()
	if lane == _last_lane:
		lane = (lane + 1) % lane_count
	_last_lane = lane

	if randf() < emitter_chance and abs(z - _last_emitter_z) >= emitter_min_gap:
		_last_emitter_z = z
		var e := HazardEmitter.new()
		add_child(e)
		e.global_position = Vector3(lane_x(lane), 3.5, z)
		return

	var t := FilmTarget.new()
	t.flat = randf() < flat_chance
	t.value = 0.8 if t.flat else 1.6
	add_child(t)
	var y := 0.25 if t.flat else 1.4
	t.global_position = Vector3(lane_x(lane), y, z)


func _spawn_air() -> void:
	var z := _runner.global_position.z - air_spawn_ahead
	var hovering := randf() < hover_chance
	if hovering and get_tree().get_nodes_in_group("hover_drone").size() >= max_hover:
		hovering = false

	if hovering:
		var dh := Drone.new()
		dh.mode = Drone.Mode.HOVER
		dh.tier = 2
		dh.value = 2.0
		add_child(dh)
		dh.global_position = Vector3(randf_range(-14.0, 14.0), randf_range(7.0, 11.0), z)
	else:
		var side := -1.0 if randf() < 0.5 else 1.0
		var dc := Drone.new()
		dc.mode = Drone.Mode.CROSS
		dc.tier = 3
		dc.value = 2.8
		dc.lateral_speed = randf_range(18.0, 28.0) * -side
		add_child(dc)
		dc.global_position = Vector3(side * 26.0, randf_range(6.0, 11.0), z)


## A cluster of battles on one side, grouped so it reads as one engagement.
func _spawn_battle() -> void:
	var side := 1.0 if randf() < 0.5 else -1.0
	var count := randi_range(cluster_min, cluster_max)
	var base_z := _runner.global_position.z - randf_range(cluster_z_min, cluster_z_max)
	for i in count:
		var p := BattlePocket.new()
		add_child(p)
		var x := side * (pocket_x + randf_range(-cluster_x_spread, cluster_x_spread))
		var z := base_z + randf_range(-cluster_z_spread, cluster_z_spread)
		p.global_position = Vector3(x, 0.0, z)


## Weighted random lane pick - the "hazard density" lever.
func _pick_lane() -> int:
	var total := 0.0
	for w in lane_weights:
		total += w
	var r := randf() * total
	for i in lane_weights.size():
		r -= lane_weights[i]
		if r <= 0.0:
			return i
	return lane_count / 2
