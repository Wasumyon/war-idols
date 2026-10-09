extends Node3D
## Soft-lane runner.
##   A / D            strafe
##   W / S            boost / slow
##   SPACE            jump         (0.5s cooldown between jumps)
##   CTRL             duck / cover (avoids filmer-targeting attacks; suspends filming)
##   SHIFT            dash         (bubble + speedlines; super armour; smashes obstacles)
##
## NOTE: Shift and Ctrl are read from the physical key, not the InputMap.
## Modifier keys bound as actions frequently fail to match, because the event
## arrives with its own modifier flag set (shift_pressed / ctrl_pressed).

@export var lane_count := 5
@export var lane_width := 4.0
@export var base_speed := 26.0
@export var boost_speed := 44.0
@export var slow_speed := 14.0
@export var strafe_rate := 10.0

@export var jump_speed := 8.5
@export var gravity := 22.0
@export var jump_cooldown := 0.5

@export var dash_speed := 92.0
@export var dash_time := 0.55
@export var dash_cooldown := 6.5

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
var _shift_prev := false
var _invuln := 0.0
var _bubble: MeshInstance3D
var _lines: Node3D

@onready var streamer: MeshInstance3D = $Streamer
@onready var body: MeshInstance3D = $Body


func _ready() -> void:
	add_to_group("runner")
	_ensure_jump_action()
	_build_dash_fx()
	lane = lane_count / 2
	position.x = lane_x(lane)
	$Hitbox.area_entered.connect(_on_area_entered)
	$StreamHit.area_entered.connect(_on_stream_hit)


func _ensure_jump_action() -> void:
	if InputMap.has_action("jump"):
		return
	InputMap.add_action("jump")
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_SPACE
	InputMap.action_add_event("jump", ev)


## A translucent bubble around the car plus radial speedlines, shown on dash.
func _build_dash_fx() -> void:
	_bubble = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 2.6
	sm.height = 5.2
	_bubble.mesh = sm
	var bm := StandardMaterial3D.new()
	bm.albedo_color = Color(0.2, 0.9, 1.0, 0.22)
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.emission_enabled = true
	bm.emission = Color(0.1, 0.6, 0.8)
	_bubble.material_override = bm
	_bubble.position = Vector3(0, 0.7, 0)
	_bubble.visible = false
	add_child(_bubble)

	_lines = Node3D.new()
	for i in 8:
		var m := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.06, 0.06, 7.0)
		m.mesh = box
		var lm := StandardMaterial3D.new()
		lm.albedo_color = Color(1, 1, 1, 0.55)
		lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.material_override = lm
		var ang := float(i) / 8.0 * TAU
		m.position = Vector3(cos(ang) * 2.3, 0.8 + sin(ang) * 1.7, 0.0)
		_lines.add_child(m)
	_lines.visible = false
	add_child(_lines)


func lane_x(index: int) -> float:
	return (index - (lane_count - 1) / 2.0) * lane_width


## Blink the car + streamer for `t` seconds (called on a hit).
func start_invuln(t: float) -> void:
	_invuln = t


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

	# --- dash (physical key: modifier actions are unreliable) ---
	var shift_now := Input.is_physical_key_pressed(KEY_SHIFT)
	if shift_now and not _shift_prev and _dash_cd <= 0.0:
		dashing = true
		_dash_t = dash_time
		_dash_cd = dash_cooldown
	_shift_prev = shift_now
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
	speed = lerp(speed, target_speed, (14.0 if dashing else 5.0) * delta)
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

	# --- duck: Ctrl, Q, or either side mouse button (top/rear thumb) ---
	ducking = Input.is_physical_key_pressed(KEY_CTRL) \
		or Input.is_physical_key_pressed(KEY_Q) \
		or Input.is_mouse_button_pressed(MOUSE_BUTTON_XBUTTON1) \
		or Input.is_mouse_button_pressed(MOUSE_BUTTON_XBUTTON2)
	var target_y: float = duck_height if ducking else stand_height
	streamer.position.y = lerp(streamer.position.y, target_y, clamp(duck_rate * delta, 0.0, 1.0))
	# The streamer's hitbox rides with them: standing = in the beam's path,
	# ducked = below it.
	$StreamHit.position.y = streamer.position.y

	# --- invulnerability blink ---
	if _invuln > 0.0:
		_invuln -= delta
		var on: bool = fmod(_invuln, 0.16) < 0.08
		body.visible = on
		streamer.visible = on
	else:
		body.visible = true
		streamer.visible = true

	# --- dash effects + smashing ---
	_bubble.visible = dashing
	_lines.visible = dashing
	if dashing:
		_bubble.scale = Vector3.ONE * (1.0 + sin(Time.get_ticks_msec() * 0.02) * 0.06)
		_smash()


## Destroy any ground obstacle currently overlapping the car while dashing.
func _smash() -> void:
	for a in $Hitbox.get_overlapping_areas():
		if a.is_in_group("obstacle"):
			a.queue_free()


## Filmer-targeting attacks only connect with the streamer's hitbox. Standing
## puts them in the beam; ducking drops them below it.
func _on_stream_hit(area: Area3D) -> void:
	if not area.is_in_group("filmer"):
		return
	if ducking:
		return   # covered: the laser cannot touch you
	if dashing:
		return   # super armour shrugs this off too
	get_parent().on_player_hit()


func _on_area_entered(area: Area3D) -> void:
	if not area.is_in_group("damaging"):
		return

	# The car is immune to filmer-targeting attacks; only the streamer hitbox
	# (StreamHit) reacts to those.
	if area.is_in_group("filmer"):
		return

	if dashing:
		if area.is_in_group("obstacle"):
			area.queue_free()
		return

	get_parent().on_player_hit()
	if area.is_in_group("hazard"):
		area.queue_free()
