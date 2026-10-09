extends RigidBody3D

@export var maxSpeed : float = 350
@export var steerForce : float = 0.1
@export var lookAhead : float = 100
@export var numOfRays : int = 8

var rayDir : Array[Vector3] = []
var interest : Array[Vector3] = []
var danger : Array[Vector3] = []

var chosenDir : Vector3 = Vector3.ZERO
var velocity : Vector3 = Vector3.ZERO
var acceleration : Vector3 = Vector3.ZERO

func _ready() -> void:
	interest.resize(numOfRays)
	danger.resize(numOfRays)
	rayDir.resize(numOfRays)
	
	for i in numOfRays:
		var angle = i * 2 * PI / numOfRays
		rayDir[i] = Vector3.FORWARD.rotated(Vector3.UP, angle)
		
func _physics_process(delta: float) -> void:
	setInterest()
	setDanger()
	chooseDirection()
	
	#var desiredVelocity = chosenDir.rotated(Vector3.UP, rotation) * maxSpeed
	#velocity = velocity.lerp(desiredVelocity, steerForce)
	#rotation = velocity.
	
func setInterest () -> void:
	if owner and owner.has_method("get_path_direction"):
		var pathDir = owner.get_path_direction(position)
		
	
func setDanger () -> void:
	pass
	
func chooseDirection () -> void:
	pass
