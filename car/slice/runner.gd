extends Node3D
## Soft-lane runner.
##   A / D (or arrows)  strafe
##   W boost / S slow
##   SPACE              jump   (clears flat slabs and low bolts)
##   LEFT SHIFT         duck   (sinks the streamer into the car; suspends filming)

@export var lane_count := 5
@export var lane_width := 4.0
@export var base_speed := 26.0
@export var boost_speed := 44.0
@export var slow_speed := 14.0
@export var strafe_rate := 10.0

@export var jump_speed := 8.5
@export var gravity := 22.0

@export var stand_height := 1.45
@export var duck_height := 0.9
@export var duck_rate := 12.0

var lane := 2
var speed := 26.0
var alive := true
var ducking := false

var _vy := 0.0
var _height := 0.0
var _grounded := true

@onready var streamer: MeshInstance3D = $Streamer


func _ready() -> void:
	add_to_group("runner")
	_ensure_actions()
	lane = lane_count / 2
	position.x = lane_x(lane)
	$Hitbox.area_entered.connect(_on_area_entered)


## Register jump (SPACE) and duck (LEFT SHIFT) in code.
func _ensure_actions() -> void:
	if not InputMap.has_action("jump"):
		InputMap.add_action("jump")
		var j := InputEventKey.new()
		j.physical_keycode = KEY_SPACE
		InputMap.action_add_event("jump", j)
	if not InputMap.has_action("duck"):
		InputMap.add_action("duck")
		var d := InputEventKey.new()
		d.physical_keycode = KEY_SHIFT
		InputMap.action_add_event("duck", d)


func lane_x(index: int) -> float:
	return (index - (lane_count - 1) / 2.0) * lane_width


func _physics_process(delta: float) -> void:
	if not alive:
		return

	# --- lane selection (soft) ---
	if Input.is_action_just_pressed("turnLeft"):
		lane = max(0, lane - 1)
	if Input.is_action_just_pressed("turnRight"):
		lane = min(lane_count - 1, lane + 1)
	position.x = lerp(position.x, lane_x(lane), clamp(strafe_rate * delta, 0.0, 1.0))

	# --- forward speed ---
	var target_speed := base_speed
	if Input.is_action_pressed("accelerate"):
		target_speed = boost_speed
	elif Input.is_action_pressed("brake"):
		target_speed = slow_speed
	speed = lerp(speed, target_speed, 5.0 * delta)
	position.z -= speed * delta

	# --- jump (raises the whole car, hitbox included) ---
	if Input.is_action_just_pressed("jump") and _grounded:
		_vy = jump_speed
		_grounded = false
	_vy -= gravity * delta
	_height += _vy * delta
	if _height <= 0.0:
		_height = 0.0
		_vy = 0.0
		_grounded = true
	position.y = _height

	# --- duck: the streamer sinks into the car ---
	ducking = Input.is_action_pressed("duck")
	var target_y: float = duck_height if ducking else stand_height
	streamer.position.y = lerp(streamer.position.y, target_y, clamp(duck_rate * delta, 0.0, 1.0))


func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("damaging"):
		get_parent().on_player_hit()
		if area.is_in_group("hazard"):
			area.queue_free()   # projectiles vanish on impact; scenery does not
