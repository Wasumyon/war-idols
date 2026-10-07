extends Node3D
class_name BattlePocket
## A battle on one side of the road: two opposing fighters, at a random spacing,
## trading fire until one is destroyed. Some advance; some hold.

@export var min_spread := 12.0
@export var max_spread := 34.0
@export var fighter_hp := 5
@export var approach_chance := 0.5


func _ready() -> void:
	add_to_group("pocket")
	var spread := randf_range(min_spread, max_spread)

	var a := Fighter.new()
	a.team = 0
	a.team_color = Color(0.3, 0.85, 1.0)
	a.hp = fighter_hp
	a.behavior = Fighter.Behavior.APPROACH if randf() < approach_chance else Fighter.Behavior.HOLD
	add_child(a)
	a.position = Vector3(-spread * 0.5, 2.0, 0)

	var b := Fighter.new()
	b.team = 1
	b.team_color = Color(1.0, 0.5, 0.2)
	b.hp = fighter_hp
	b.behavior = Fighter.Behavior.APPROACH if randf() < approach_chance else Fighter.Behavior.HOLD
	add_child(b)
	b.position = Vector3(spread * 0.5, 2.0, 0)

	a.target = b
	b.target = a
