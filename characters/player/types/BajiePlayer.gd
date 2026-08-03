# characters/players/types/BajiePlayer.gd
extends "res://characters/player/base/BasePlayer.gd"

func _ready():
	base_max_health = 160
	base_max_mana = 100
	base_attack_damage = 14
	base_defense = 6
	attack_per_level = 3
	defense_per_level = 3
	speed = 300.0
	super._ready()

func handle_input(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	
	velocity = input_vector * speed
	move_and_slide()
