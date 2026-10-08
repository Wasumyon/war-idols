extends Node3D
## Soft-lane runner.
##   A / D            strafe
##   W / S            boost / slow
##   SPACE            jump         (0.5s cooldown between jumps)
##   CTRL             duck / cover (avoids filmer-targeting attacks; suspends filming)
##   SHIFT            dash         (forward burst, super armour, smashes obstacles)

@export var lane_count := 5
@export var lane_width := 4.0
@export var base_speed := 26.0
@export var boost_speed := 44.0
@export var slow_speed := 14.0
@export var strafe_rate := 10.0

@export var jump_speed := 8.5
@export var gravity := 22.0
@export var jump_cooldown := 0.5

@export var dash_speed := 68.0
@export var dash_time := 0.45
@export var dash_cooldown := 4.5

@export var stand_height := 1.45
@export var duck_height := 0.9
@export var duck_rate := 12.0

var lane := 2
var speed := 26.0
var alive := true
var ducking := false
var dashing := false

var _vy := 0.0
var _height := 0.0
var _grounded := true
var _jump_cd := 0.0
var _dash_cd := 0.0
var _dash_t := 0.0

@onready var streamer: MeshInstance3D = $Streamer


func _ready() -> void:
	add_to_group("runner")
	_ensure_actions()
	lane = lane_count / 2
	position.x = lane_x(lane)
	$Hitbox.area_entered.connect(_on_area_entered)


func _ensure_actions() -> void:
	if not InputMap.has_action("jump"):
		_bind("jump", KEY_SPACE)
	if not InputMap.has_action("duck"):
		_bind("duck", KEY_CTRL)
	if not InputMap.has_action("dash"):
		_bind("dash", KEY_SHIFT)


func _bind(action: String, key: int) -> void:
	InputMap.add_action(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	InputMap.action_add_event(action, ev)


func lane_x(index: int) -> float:
	return (index - (lane_count - 1) / 2.0) * lane_width


func _physics_process(delta: float) -> void:
	if not alive:
		return
	_jump_cd = max(0.0, _jump_cd - delta)
	_dash_cd = max(0.0, _dash_cd - delta)

	# --- lane selection (soft) ---
	if Input.is_action_just_pressed("turnLeft"):
		lane = max(0, lane - 1)
	if Input.is_action_just_pressed("turnRight"):
		lane = min(lane_count - 1, lane + 1)
	position.x = lerp(position.x, lane_x(lane), clamp(strafe_rate * delta, 0.0, 1.0))

	# --- dash ---
	if Input.is_action_just_pressed("dash") and _dash_cd <= 0.0:
		dashing = true
		_dash_t = dash_time
		_dash_cd = dash_cooldown
	if dashing:
		_dash_t -= delta
		if _dash_t <= 0.0:
			dashing = false

	# --- forward speed ---
	var target_speed := base_speed
	if Input.is_action_pressed("accelerate"):
		target_speed = boost_speed
	elif Input.is_action_pressed("brake"):
		target_speed = slow_speed
	if dashing:
		target_speed = dash_speed
	speed = lerp(speed, target_speed, 5.0 * delta)
	position.z -= speed * delta

	# --- jump (with cooldown) ---
	if Input.is_action_just_pressed("jump") and _grounded and _jump_cd <= 0.0:
		_vy = jump_speed
		_grounded = false
		_jump_cd = jump_cooldown
	_vy -= gravity * delta
	_height += _vy * delta
	if _height <= 0.0:
		_height = 0.0
		_vy = 0.0
		_grounded = true
	position.y = _height

	# --- duck (streamer takes cover) ---
	ducking = Input.is_action_pressed("duck")
	var target_y: float = duck_height if ducking else stand_height
	streamer.position.y = lerp(streamer.position.y, target_y, clamp(duck_rate * delta, 0.0, 1.0))


func _on_area_entered(area: Area3D) -> void:
	if not area.is_in_group("damaging"):
		return

	# Dash smashes ground obstacles and takes no damage.
	if dashing:
		if area.is_in_group("obstacle"):
			area.queue_free()
		return

	# Filmer-targeting attacks: covered = missed.
	if area.is_in_group("filmer"):
		if ducking:
			return
		get_parent().on_player_hit()
		area.queue_free()
		return

	get_parent().on_player_hit()
	if area.is_in_group("hazard"):
		area.queue_free()
