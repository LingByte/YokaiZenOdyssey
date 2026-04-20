extends CharacterBody2D

@export var speed: float = 200.0
@export var jump_force: float = -400.0
@export var gravity: float = 1000.0

var is_attacking: bool = false
var is_facing_right: bool = true

@onready var visual_root: Node2D = $VisualRoot
@onready var skeleton: Skeleton2D = $VisualRoot/Skeleton2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var weapon_sprite: Sprite2D = $VisualRoot/Skeleton2D/Bone2D/RightArm/Sprite2D2
@onready var left_foot_sprite: Sprite2D = $VisualRoot/Skeleton2D/Bone2D/LeftLeg/Sprite2D
@onready var right_foot_sprite: Sprite2D = $VisualRoot/Skeleton2D/Bone2D/RightLeg/Sprite2D

func _ready():
	animation_player.play("idle")
	# 场景中 VisualRoot 默认 scale 是 -1（朝向右侧），所以保持这个设置
	visual_root.scale.x = -1

func _physics_process(delta):
	handle_gravity(delta)
	handle_movement(delta)
	handle_jump()
	handle_attack()
	move_and_slide()
	update_animation()

func handle_gravity(delta):
	velocity.y += gravity * delta

func handle_movement(delta):
	var input_dir = Input.get_action_strength("right") - Input.get_action_strength("left")
	velocity.x = input_dir * speed

	if input_dir != 0:
		is_facing_right = input_dir > 0
		visual_root.scale.x = -1 if is_facing_right else 1  # 向右时翻转，向左时不翻转

		# 手动修复挂在 Bone2D 下的 Sprite 缩放问题
		weapon_sprite.scale.x = 1 if is_facing_right else -1
		left_foot_sprite.scale.x = 1 if is_facing_right else -1  # 防止脚翻转变形
		right_foot_sprite.scale.x = 1 if is_facing_right else -1  # 防止脚翻转变形
	
		
func handle_jump():
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_force

func handle_attack():
	if is_attacking:
		return
	if Input.is_action_just_pressed("attack"):
		is_attacking = true
		animation_player.play("attack")

func update_animation():
	if is_attacking:
		if not animation_player.is_playing():
			is_attacking = false
		else:
			return

	if not is_on_floor():
		animation_player.play("jump")
	elif abs(velocity.x) > 10:
		animation_player.play("run")
	else:
		animation_player.play("idle")
