extends Node3D

@onready var ball: RigidBody3D = $ball
@onready var model: Node3D = $model
@onready var wheel_fr: MeshInstance3D = $model/wheel_fr
@onready var wheel_fl: MeshInstance3D = $model/wheel_fl
@onready var body: MeshInstance3D = $model/body
@onready var boost_timer: Timer = $boostTimer
@onready var drift_timer: Timer = $driftTimer
@onready var anim: AnimationPlayer = $AnimationPlayer

var acceleration : float = 70.0
var steering : float = 12.0
var turnSpeed : float = 5
var bodyTilt : float = 30

var speedInput : float = 0.0
var rotateInput : float = 0.0

var drifting : bool = false
var driftDirection : float = 0.0
var minimumDrift : bool = false
var boost : float = 1.0
var driftBoost : float = 1.75

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	speedInput = (Input.get_action_strength("accelerate") - Input.get_action_strength("brake")) * acceleration
	rotateInput = deg_to_rad(steering) * (Input.get_action_strength("turnLeft") - Input.get_action_strength("turnRight"))
	
	if Input.is_action_just_pressed("drift") && !drifting && rotateInput != 0 && speedInput > 0.0:
		startDrift()
		
	if drifting:
		var driftAmount: float = 0.0
		driftAmount += Input.get_action_strength("turnLeft") - Input.get_action_strength("turnRight")
		driftAmount *= deg_to_rad(steering * 0.55)
		rotateInput = driftDirection + driftAmount
		
	if drifting && Input.is_action_just_released("drift") || speedInput < 1.0:
		stopDrift()
	print (ball.linear_velocity.length())

func _physics_process(delta: float) -> void:
	model.transform.origin = ball.transform.origin
	ball.apply_central_force(-model.global_transform.basis.z * speedInput * boost)
	wheel_fl.rotate_y(rotateInput)
	wheel_fr.rotate_y(rotateInput)
	
	if ball.linear_velocity.length() > 0.75:
		rotateCar(delta)

func rotateCar (delta: float) -> void:
	var newBasis = model.global_transform.basis.rotated(model.global_transform.basis.y, rotateInput)
	model.global_transform.basis = model.global_transform.basis.slerp(newBasis, turnSpeed * delta)
	model.global_transform = model.global_transform.orthonormalized()
	var t = -rotateInput * ball.linear_velocity.length() / bodyTilt
	body.rotation.z = lerp(body.rotation.z, t, 10 * delta)

func startDrift () -> void:
	drifting = true
	#anim.play("hop")
	minimumDrift = false
	driftDirection = rotateInput
	drift_timer.start()

func stopDrift() -> void:
	if minimumDrift:
		boost = driftBoost
		boost_timer.start()
		#anim.play("zoomOut")
	drifting = false
	minimumDrift = false

func _on_drift_timer_timeout() -> void:
	if drifting:
		minimumDrift = true


func _on_boost_timer_timeout() -> void:
	boost = 1.0
