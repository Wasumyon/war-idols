extends Node3D
## ============================================================================
## VERTICAL SLICE
## ============================================================================
##
## CONTROLS
##   A / D            strafe            W / S   boost / slow
##   SPACE            jump (cooldown)
##   CTRL             duck / cover (avoids filmer attacks; suspends filming)
##   SHIFT            dash
##   RIGHT MOUSE      zoom (slower, tighter viewfinder)
##   mouse            aim the viewfinder
##   R                restart (after the run ends)
##
## SCORING
##   Keep the viewfinder on a point of interest: FOLLOWERS accrue. DONATIONS
##   then trickle in at a rate that scales with your follower count.
##   Reticle colour = subject tier; the tag above = proximity multiplier.

const DURATION := 90.0
const START_SHIELDS := 3
const FOLLOW_PER_SEC := 10.0
const DONATION_RATE := 0.004   # money/sec per follower
const IFRAMES := 0.8

const NEAR_DIST := 12.0
const FAR_DIST := 140.0
const MAX_MULT := 4.0

const SNAP_COOLDOWN := 5.0
const SNAP_BURST := 320.0
const SNAP_MIN_TIER := 2   # orange and above count as a "good snap"

const RETICLE_W := 130.0
const RETICLE_W_ZOOM := 84.0
const BASE_FOV := 78.0
const ZOOM_FOV := 46.0
const RETICLE_RATE_ZOOM := 7.0

const VIG_BASE := 0.22
const VIG_LOCK := 0.60
const VIG_RATE := 3.5

var followers := 0.0
var money := 0.0
var shields := START_SHIELDS
var footage_by_type := {}
var run_active := true
var _iframe := 0.0
var _vig := VIG_BASE
var _reticle_pos := Vector2.ZERO
var _zoom := false
var _snap_cd := 0.0
var _lmb_prev := false

@onready var runner = $Runner
@onready var cam: Camera3D = $Runner/Camera3D
@onready var run_timer: Timer = $RunTimer
@onready var reticle = $HUD/Reticle
@onready var vignette: ColorRect = $HUD/Vignette
@onready var points_label: Label = $HUD/Points
@onready var shields_label: Label = $HUD/Shields
@onready var speed_label: Label = $HUD/Speed
@onready var time_label: Label = $HUD/Time
@onready var cooldowns = $HUD/Cooldowns
@onready var snap_toast: Label = $HUD/SnapToast


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	run_timer.wait_time = DURATION
	run_timer.timeout.connect(_end_run)
	run_timer.start()
	_update_hud(1.0)


func _physics_process(delta: float) -> void:
	if not run_active:
		return
	_iframe = max(0.0, _iframe - delta)

	# --- zoom (right mouse) ---
	_zoom = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	var target_fov: float = ZOOM_FOV if _zoom else BASE_FOV
	cam.fov = lerp(cam.fov, target_fov, clamp(6.0 * delta, 0.0, 1.0))

	# --- reticle follows the cursor; lags (slower) when zoomed ---
	var mouse := get_viewport().get_mouse_position()
	if _zoom:
		_reticle_pos = _reticle_pos.lerp(mouse, clamp(RETICLE_RATE_ZOOM * delta, 0.0, 1.0))
	else:
		_reticle_pos = mouse

	# --- passive filming ---
	var target = _film_target()
	if runner.ducking:
		target = null   # ducking suspends filming
	var tier := 0
	var mult := 1.0
	if target != null:
		tier = int(target.tier)
		mult = _proximity_mult(target)
		followers += FOLLOW_PER_SEC * float(target.value) * mult * delta
		footage_by_type[target.type_name] = float(footage_by_type.get(target.type_name, 0.0)) + 1.0
		# Donations are stochastic but driven by follower count.
		money += followers * DONATION_RATE * delta * randf_range(0.5, 1.5)
		footage_by_type["_donations"] = float(footage_by_type.get("_donations", 0.0)) + 1.0

	var width: float = RETICLE_W_ZOOM if _zoom else RETICLE_W
	reticle.set_state(_reticle_pos, tier, mult, width)

	var vig_target: float = VIG_LOCK if tier > 0 else VIG_BASE
	_vig = lerp(_vig, vig_target, clamp(VIG_RATE * delta, 0.0, 1.0))
	vignette.material.set_shader_parameter("intensity", _vig)

	# --- camera snap (left mouse): big follower burst on a good target ---
	if _snap_cd > 0.0:
		_snap_cd = max(0.0, _snap_cd - delta)
	var lmb := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var good_snap: bool = target != null and tier >= SNAP_MIN_TIER and _snap_cd <= 0.0
	if lmb and not _lmb_prev and good_snap:
		followers += SNAP_BURST * mult
		_snap_cd = SNAP_COOLDOWN
		snap_toast.modulate.a = 1.0
	_lmb_prev = lmb
	snap_toast.modulate.a = lerp(snap_toast.modulate.a, (1.0 if good_snap else 0.0), clamp(6.0 * delta, 0.0, 1.0))
	cooldowns.set_cooldowns(_snap_cd, SNAP_COOLDOWN, runner._dash_cd, runner.dash_cooldown)

	_update_hud(mult)


func _reticle_half() -> Vector2:
	var w: float = RETICLE_W_ZOOM if _zoom else RETICLE_W
	return Vector2(w * 0.5, (w / (16.0 / 9.0)) * 0.5)


## Returns the point of interest whose screen position falls inside the
## viewfinder rectangle, or null.
func _film_target():
	var half := _reticle_half()
	var best = null
	var best_d := INF
	for n in get_tree().get_nodes_in_group("interest"):
		if not (n is Area3D) or not n.visible:
			continue
		var gp: Vector3 = n.global_position
		if cam.is_position_behind(gp):
			continue
		var sp := cam.unproject_position(gp)
		if abs(sp.x - _reticle_pos.x) <= half.x and abs(sp.y - _reticle_pos.y) <= half.y:
			var d := sp.distance_to(_reticle_pos)
			if d < best_d:
				best_d = d
				best = n
	return best


func _proximity_mult(target) -> float:
	var d := cam.global_position.distance_to(target.global_position)
	var t: float = clamp((FAR_DIST - d) / (FAR_DIST - NEAR_DIST), 0.0, 1.0)
	return 1.0 + (MAX_MULT - 1.0) * t


func on_player_hit() -> void:
	if not run_active or _iframe > 0.0:
		return
	_iframe = IFRAMES
	shields -= 1
	_flash_shields()
	if shields <= 0:
		_end_run()


func _flash_shields() -> void:
	shields_label.modulate = Color(1.0, 0.3, 0.3)
	await get_tree().create_timer(0.25).timeout
	shields_label.modulate = Color(1, 1, 1)


func _update_hud(mult: float) -> void:
	points_label.text = "Followers: %d" % int(followers)
	shields_label.text = "Shields: %d" % shields
	speed_label.text = "$%d   %d m/s   x%.1f" % [int(money), int(runner.speed), mult]
	var t := int(ceil(run_timer.time_left))
	time_label.text = "%02d:%02d" % [int(t / 60.0), t % 60]


func _end_run() -> void:
	run_active = false
	run_timer.stop()
	runner.alive = false
	reticle.set_state(Vector2(-1000, -1000), 0, 1.0, RETICLE_W)
	vignette.material.set_shader_parameter("intensity", VIG_BASE)
	points_label.text = "RUN OVER  -  press R"
	shields_label.text = "Followers: %d   $%d" % [int(followers), int(money)]
	speed_label.text = ""
	time_label.text = "00:00"


func _unhandled_input(event: InputEvent) -> void:
	if not run_active and event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()
