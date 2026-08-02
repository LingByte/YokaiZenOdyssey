extends CharacterBody2D

@export var speed: float = 200.0
@export var jump_force: float = -400.0
@export var double_jump_force: float = -420.0
@export var gravity: float = 1000.0
@export var max_health: int = 100
@export var max_jumps: int = 2

var current_health: int
var is_attacking: bool = false
var attack_stage: int = 0
var attack_timer: float = 0.0
var attack_max_combo_time: float = 0.3
var jumps_left: int = 2
var is_double_jumping: bool = false
var _was_on_floor: bool = true

@onready var sprite = $AnimatedSprite2D

func _ready():
	current_health = max_health
	jumps_left = max_jumps

func _physics_process(delta):
	if not is_attacking:
		handle_movement(delta)
	move_and_slide()

	update_animation()

	if attack_stage > 0:
		attack_timer += delta
		if attack_timer > attack_max_combo_time:
			reset_attack()

func handle_movement(delta):
	var input_dir = Input.get_action_strength("right") - Input.get_action_strength("left")
	velocity.x = input_dir * speed

	if input_dir != 0 and sprite:
		sprite.flip_h = input_dir < 0

	var on_floor := is_on_floor()
	# 上升中即使短暂贴地也不重置，否则一段跳后立刻丢二段跳
	if on_floor and velocity.y >= 0.0:
		if not _was_on_floor:
			_on_landed()
		jumps_left = max_jumps
		velocity.y = 0.0
	else:
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump"):
		_try_jump()

	_was_on_floor = on_floor and velocity.y >= 0.0

	if Input.is_action_just_pressed("attack"):
		handle_attack()

func _try_jump() -> void:
	if jumps_left <= 0:
		return
	var from_floor := is_on_floor() and velocity.y >= 0.0
	if from_floor or jumps_left == max_jumps:
		# 地面跳，或走下悬崖后的第一次空中跳（不翻滚）
		velocity.y = jump_force
		jumps_left = maxi(jumps_left - 1, 0)
		is_double_jumping = false
		_on_first_jump()
	else:
		velocity.y = double_jump_force
		jumps_left -= 1
		is_double_jumping = true
		_on_double_jump()

func _on_first_jump() -> void:
	pass

func _on_double_jump() -> void:
	if sprite == null:
		return
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(&"jump_flip"):
		sprite.play(&"jump_flip")
	elif sprite.sprite_frames and sprite.sprite_frames.has_animation(&"jump"):
		sprite.play(&"jump")

func _on_landed() -> void:
	is_double_jumping = false

func handle_attack():
	if is_attacking and attack_stage == 1 and attack_timer < attack_max_combo_time:
		attack_stage = 2
		attack_timer = 0
		sprite.play("attack_2")
	else:
		is_attacking = true
		attack_stage = 1
		attack_timer = 0
		sprite.play("attack_1")

func reset_attack():
	is_attacking = false
	attack_stage = 0
	attack_timer = 0

func update_animation():
	if is_attacking:
		return
	# 二段跳翻滚播放中，不打断
	if is_double_jumping and sprite and sprite.animation == &"jump_flip":
		if sprite.is_playing():
			return
		is_double_jumping = false
	if not is_on_floor():
		if sprite.sprite_frames and sprite.sprite_frames.has_animation(&"jump"):
			sprite.play(&"jump")
	elif abs(velocity.x) > 10:
		sprite.play(&"run")
	else:
		sprite.play(&"idle")

func take_damage(amount: int):
	current_health -= amount
	if current_health <= 0:
		die()
	else:
		sprite.play("hurt")

func die():
	sprite.play("die")
	set_physics_process(false)
	await sprite.animation_finished
	queue_free()
