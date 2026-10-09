extends Node3D
## Vertical slice - Step 1: mouse reticle, film raycast, live score.
##
## Controls:
##   WASD / arrows  - drive
##   mouse          - move the reticle
##   hold LMB       - film a target under the reticle
##   R (when over)  - restart
##
## This scene is a self-contained test of the core verb: film a moving subject
## while you drive. It intentionally touches nothing in test.tscn / test_static.tscn.

const DURATION := 90.0
const START_SHIELDS := 3
const PTS_PER_SEC := 10.0
const RAY_LENGTH := 500.0

var points := 0.0
var shields := START_SHIELDS
var footage_by_type := {}
var run_active := true

@onready var cam: Camera3D = $Car/model/Camera3D
@onready var run_timer: Timer = $RunTimer
@onready var reticle = $HUD/Reticle
@onready var points_label: Label = $HUD/Points
@onready var shields_label: Label = $HUD/Shields
@onready var time_label: Label = $HUD/Time


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_ensure_film_action()
	run_timer.wait_time = DURATION
	run_timer.timeout.connect(_end_run)
	run_timer.start()
	_update_hud()


## Registers the "film" action in code so we don't have to hand-edit project.godot.
func _ensure_film_action() -> void:
	if InputMap.has_action("film"):
		return
	InputMap.add_action("film")
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("film", ev)


func _physics_process(delta: float) -> void:
	if not run_active:
		return

	var target = _film_target()
	var filming: bool = target != null and Input.is_action_pressed("film")
	reticle.set_active(filming)

	if filming:
		var gain: float = PTS_PER_SEC * float(target.film_value) * delta
		points += gain
		footage_by_type[target.type_name] = float(footage_by_type.get(target.type_name, 0.0)) + gain

	_update_hud()


## Casts a ray from the chase camera through the mouse. Returns the filmable
## node under the cursor, or null.
func _film_target():
	var mouse := get_viewport().get_mouse_position()
	var from := cam.project_ray_origin(mouse)
	var to := from + cam.project_ray_normal(mouse) * RAY_LENGTH
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	var collider = hit.get("collider")
	if collider != null and collider.is_in_group("filmable"):
		return collider
	return null


func _update_hud() -> void:
	points_label.text = "Footage: %d" % int(points)
	shields_label.text = "Shields: %d" % shields
	var t := int(ceil(run_timer.time_left))
	time_label.text = "%02d:%02d" % [int(t / 60.0), t % 60]


func _end_run() -> void:
	run_active = false
	run_timer.stop()
	reticle.set_active(false)
	reticle.visible = false
	points_label.text = "RUN OVER  -  press R"
	shields_label.text = "Footage: %d" % int(points)
	time_label.text = "00:00"


func _unhandled_input(event: InputEvent) -> void:
	if not run_active and event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()
