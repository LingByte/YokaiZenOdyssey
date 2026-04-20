# characters/players/types/Player1.gd
extends "res://characters/player/base/BasePlayer.gd"

func _ready():
	# 调用基类初始化
	super._ready()
	# 可以自定义自己的初始血量或速度
	max_health = 150
	speed = 300.0

func handle_input(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	
	velocity = input_vector * speed
	move_and_slide()
