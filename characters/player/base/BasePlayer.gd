extends CharacterBody2D

@export var speed: float = 200.0
@export var jump_force: float = -400.0
@export var gravity: float = 1000.0
@export var max_health: int = 100

var current_health: int
var is_attacking: bool = false
var attack_stage: int = 0
var attack_timer: float = 0.0
var attack_max_combo_time: float = 0.3

@onready var sprite = $AnimatedSprite2D

func _ready():
	current_health = max_health

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

	# 翻转角色朝向
	if input_dir != 0:
		sprite.flip_h = input_dir < 0  # 向右时不翻转，向左时翻转

	# 重力
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# 跳跃
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_force

	# 攻击输入
	if Input.is_action_just_pressed("attack"):
		handle_attack()

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
		return  # 不打断攻击动画
	elif not is_on_floor():
		sprite.play("jump")
	elif abs(velocity.x) > 10:
		sprite.play("run")
	else:
		sprite.play("idle")

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
