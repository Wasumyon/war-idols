extends Node3D
## ============================================================================
## VERTICAL SLICE - STEP 3: tiers, proximity multiplier, flying enemy
## ============================================================================
##
## CONTROLS
##   A / D (or arrows)  strafe one lane
##   W boost / S slow
##   mouse              aim the reticle   (filming is PASSIVE: just stay on it)
##   R (after end)      restart
##
## FILMING
##   Keep the reticle on a "point of interest" and points accrue automatically.
##   Reticle COLOR = subject tier. Reticle SIZE = proximity multiplier
##   (closer subject = more points).
##
## THE OBJECTS
##   FilmTarget  - red ground block. tier 1 (yellow). Film or crash into it.
##   Drone       - purple flyer, OFF the lane grid. tier 2 (orange).
##                 Fires projectiles down a lane OR aimed at you.
##   Hazard      - yellow projectile. Damages on contact; not filmable.
## ----------------------------------------------------------------------------


const DURATION := 90.0
const START_SHIELDS := 3
const PTS_PER_SEC := 10.0
const RAY_LENGTH := 500.0
const IFRAMES := 0.8

# Proximity multiplier: at NEAR_DIST or closer you get MAX_MULT; at FAR_DIST, 1.0.
const NEAR_DIST := 12.0
const FAR_DIST := 140.0
const MAX_MULT := 3.0
const CAPTURE_RADIUS := 28.0   # pixel tolerance around the cursor

# Vignette: soft base, closes in (smoothed) when you are on a subject.
const VIG_BASE := 0.22
const VIG_LOCK := 0.60
const VIG_RATE := 3.5


var points := 0.0
var shields := START_SHIELDS
var footage_by_type := {}
var run_active := true
var _iframe := 0.0
var _vig := VIG_BASE


@onready var runner = $Runner
@onready var cam: Camera3D = $Runner/Camera3D
@onready var run_timer: Timer = $RunTimer
@onready var reticle = $HUD/Reticle
@onready var vignette: ColorRect = $HUD/Vignette
@onready var points_label: Label = $HUD/Points
@onready var shields_label: Label = $HUD/Shields
@onready var speed_label: Label = $HUD/Speed
@onready var time_label: Label = $HUD/Time


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

	# --- passive filming ----------------------------------------------------
	var target = _film_target()
	if runner.ducking:
		target = null   # ducking suspends filming
	var tier := 0
	var mult := 1.0
	if target != null:
		tier = int(target.tier)
		mult = _proximity_mult(target)
		var gain: float = PTS_PER_SEC * float(target.value) * mult * delta
		points += gain
		footage_by_type[target.type_name] = float(footage_by_type.get(target.type_name, 0.0)) + gain

	reticle.set_state(tier, mult)
	# Vignette eases toward its target instead of snapping.
	var vig_target: float = VIG_LOCK if tier > 0 else VIG_BASE
	_vig = lerp(_vig, vig_target, clamp(VIG_RATE * delta, 0.0, 1.0))
	vignette.material.set_shader_parameter("intensity", _vig)
	_update_hud(mult)


func _proximity_mult(target) -> float:
	var d := cam.global_position.distance_to(target.global_position)
	var t: float = clamp((FAR_DIST - d) / (FAR_DIST - NEAR_DIST), 0.0, 1.0)
	return 1.0 + (MAX_MULT - 1.0) * t


## Casts rays from the camera through the mouse (centre + a ring of offsets) so
## the reticle has a generous capture area. Returns the point of interest
## under the cursor, or null.
func _film_target():
	var mouse := get_viewport().get_mouse_position()
	var r := CAPTURE_RADIUS
	var offsets := [
		Vector2.ZERO,
		Vector2(r, 0), Vector2(-r, 0), Vector2(0, r), Vector2(0, -r),
		Vector2(r, r) * 0.7, Vector2(-r, r) * 0.7,
		Vector2(r, -r) * 0.7, Vector2(-r, -r) * 0.7,
	]
	for off in offsets:
		var p: Vector2 = mouse + off
		var from := cam.project_ray_origin(p)
		var to := from + cam.project_ray_normal(p) * RAY_LENGTH
		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.collide_with_areas = true
		query.collide_with_bodies = false
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			continue
		var collider = hit.get("collider")
		if collider != null and collider.is_in_group("interest"):
			return collider
	return null


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
	points_label.text = "Footage: %d" % int(points)
	shields_label.text = "Shields: %d" % shields
	speed_label.text = "%d m/s   x%.1f" % [int(runner.speed), mult]
	var t := int(ceil(run_timer.time_left))
	time_label.text = "%02d:%02d" % [int(t / 60.0), t % 60]


func _end_run() -> void:
	run_active = false
	run_timer.stop()
	runner.alive = false
	reticle.set_state(0, 1.0)
	reticle.visible = false
	points_label.text = "RUN OVER  -  press R"
	shields_label.text = "Footage: %d" % int(points)
	speed_label.text = ""
	time_label.text = "00:00"


func _unhandled_input(event: InputEvent) -> void:
	if not run_active and event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()
