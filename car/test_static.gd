extends Node3D

@onready var cam_main: Camera3D = $camMain
@onready var cam_top: Camera3D = $CamTop
@onready var cam_r: Camera3D = $CamR
@onready var cam_l: Camera3D = $CamL
@onready var cam_fl: Camera3D = $CamFL
@onready var cam_fr: Camera3D = $CamFR
@onready var cam_bl: Camera3D = $CamBL
@onready var cam_br: Camera3D = $CamBR
@onready var cam_b: Camera3D = $CamB
@onready var cam_f: Camera3D = $CamF

func _ready() -> void:
	cam_main.global_transform = cam_top.global_transform

func _input(event: InputEvent) -> void:
	if Input.is_physical_key_pressed(KEY_KP_6):
		var tween = create_tween().set_parallel(true)
		tween.tween_property(cam_main, "global_transform", cam_r.global_transform, 1.0)
	
	if Input.is_physical_key_pressed(KEY_KP_4):
		var tween = create_tween().set_parallel(true)
		tween.tween_property(cam_main, "global_transform", cam_l.global_transform, 1.0)
	
	if Input.is_physical_key_pressed(KEY_KP_5):
		var tween = create_tween().set_parallel(true)
		tween.tween_property(cam_main, "global_transform", cam_top.global_transform, 1.0)
	
	if Input.is_physical_key_pressed(KEY_KP_3):
		var tween = create_tween().set_parallel(true)
		tween.tween_property(cam_main, "global_transform", cam_br.global_transform, 1.0)

	if Input.is_physical_key_pressed(KEY_KP_1):
		var tween = create_tween().set_parallel(true)
		tween.tween_property(cam_main, "global_transform", cam_bl.global_transform, 1.0)

	if Input.is_physical_key_pressed(KEY_KP_9):
		var tween = create_tween().set_parallel(true)
		tween.tween_property(cam_main, "global_transform", cam_fr.global_transform, 1.0)

	if Input.is_physical_key_pressed(KEY_KP_7):
		var tween = create_tween().set_parallel(true)
		tween.tween_property(cam_main, "global_transform", cam_fl.global_transform, 1.0)
	
	if Input.is_physical_key_pressed(KEY_KP_8):
		var tween = create_tween().set_parallel(true)
		tween.tween_property(cam_main, "global_transform", cam_f.global_transform, 1.0)
	
	if Input.is_physical_key_pressed(KEY_KP_2):
		var tween = create_tween().set_parallel(true)
		tween.tween_property(cam_main, "global_transform", cam_b.global_transform, 1.0)
