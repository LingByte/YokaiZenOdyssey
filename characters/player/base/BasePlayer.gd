extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal mana_changed(current: int, maximum: int)
signal exp_changed(current: int, maximum: int)
signal level_changed(level: int)
signal died

@export var speed: float = 200.0
@export var jump_force: float = -400.0
@export var double_jump_force: float = -420.0
@export var gravity: float = 1000.0
@export var max_health: int = 100
@export var max_mana: int = 100
@export var max_jumps: int = 2
@export var attack_damage: int = 15
@export var defense: int = 0
@export var base_max_health: int = 100
@export var base_max_mana: int = 100
@export var base_exp_to_next: int = 100
@export var base_attack_damage: int = 15
@export var base_defense: int = 0
@export var health_per_level: int = 25
@export var mana_per_level: int = 20
@export var exp_per_level: int = 40
@export var attack_per_level: int = 4
@export var defense_per_level: int = 2

var current_health: int
var current_mana: int
var level: int = 1
var current_exp: int = 0
var exp_to_next: int = 100
var is_attacking: bool = false
var attack_stage: int = 0
var attack_timer: float = 0.0
var attack_max_combo_time: float = 0.3
var jumps_left: int = 2
var is_double_jumping: bool = false
var _was_on_floor: bool = true
var _invincible_time: float = 0.0
var _persist_timer: float = -1.0
var _hud: Node = null
var _move_input: float = 0.0

@onready var sprite = $AnimatedSprite2D

func _ready():
	add_to_group("player")
	# 层2=玩家，只与地面(层1)碰撞，不与敌人刚体互推
	collision_layer = 2
	collision_mask = 1
	_load_progress_from_save()
	jumps_left = max_jumps
	_emit_all_stats()
	_configure_camera()

func _configure_camera() -> void:
	var cam := get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return
	# 靠边时角色可走到屏幕一侧，而不是永远钉在画面正中
	cam.drag_horizontal_enabled = true
	cam.drag_vertical_enabled = true
	cam.drag_left_margin = 0.2
	cam.drag_right_margin = 0.2
	cam.drag_top_margin = 0.2
	cam.drag_bottom_margin = 0.2

func set_camera_bounds(left_x: float, right_x: float) -> void:
	var cam := get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return
	cam.limit_smoothed = false
	cam.limit_left = int(floor(left_x))
	cam.limit_right = int(ceil(right_x))
	# 强制按新边界对齐一次，避免仍停在旧中心
	cam.reset_smoothing()
	cam.force_update_scroll()

func _physics_process(delta):
	if _invincible_time > 0.0:
		_invincible_time = maxf(0.0, _invincible_time - delta)
	if _persist_timer >= 0.0:
		_persist_timer -= delta
		if _persist_timer <= 0.0:
			_persist_timer = -1.0
			_persist_progress()

	if not is_attacking:
		handle_movement(delta)
	move_and_slide()

	update_animation()

	if attack_stage > 0:
		attack_timer += delta
		if attack_timer > attack_max_combo_time:
			reset_attack()

func bind_hud(hud: Node) -> void:
	_hud = hud
	if hud and hud.has_method("bind_player_stats"):
		hud.bind_player_stats(self)

func handle_movement(delta):
	_move_input = Input.get_action_strength("right") - Input.get_action_strength("left")
	velocity.x = _move_input * speed

	if _move_input != 0.0 and sprite:
		sprite.flip_h = _move_input < 0.0

	var on_floor := is_on_floor()
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
		if sprite:
			sprite.play("attack_2")
		_spawn_attack_hitbox(1.2)
	else:
		is_attacking = true
		attack_stage = 1
		attack_timer = 0
		if sprite:
			sprite.play("attack_1")
		_spawn_attack_hitbox(1.0)

func _spawn_attack_hitbox(damage_mul: float = 1.0) -> void:
	var area := Area2D.new()
	area.name = "AttackHitbox"
	area.add_to_group("player_attack")
	var dmg := int(round(attack_damage * damage_mul))
	area.set_meta("damage", dmg)
	area.collision_layer = 0
	area.collision_mask = 4
	area.monitoring = true
	area.monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(70, 60)
	shape.shape = rect
	var face := -1.0 if (sprite and sprite.flip_h) else 1.0
	shape.position = Vector2(48.0 * face, -50.0)
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(func(body: Node):
		if body != null and body.is_in_group("enemy") and body.has_method("take_damage"):
			body.take_damage(dmg)
	)
	get_tree().create_timer(0.22).timeout.connect(func():
		if is_instance_valid(area):
			area.queue_free()
	)

func reset_attack():
	is_attacking = false
	attack_stage = 0
	attack_timer = 0

func update_animation():
	if is_attacking:
		return
	if is_double_jumping and sprite and sprite.animation == &"jump_flip":
		if sprite.is_playing():
			return
		is_double_jumping = false
	if sprite == null:
		return
	if not is_on_floor():
		if sprite.sprite_frames and sprite.sprite_frames.has_animation(&"jump"):
			sprite.play(&"jump")
	elif absf(_move_input) > 0.1:
		# 贴墙时 velocity 可能为 0，仍按输入播跑动
		sprite.play(&"run")
	else:
		sprite.play(&"idle")

func take_damage(amount: int):
	if _invincible_time > 0.0 or amount <= 0 or current_health <= 0:
		return
	var mitigated := maxi(1, amount - defense)
	current_health = maxi(current_health - mitigated, 0)
	_invincible_time = 0.75
	modulate = Color(1.5, 0.7, 0.7)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.25)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		die()
	elif sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("hurt"):
		sprite.play("hurt")

func gain_exp(amount: int) -> void:
	if amount <= 0 or current_health <= 0:
		return
	current_exp += amount
	var leveled := false
	while current_exp >= exp_to_next:
		current_exp -= exp_to_next
		_level_up()
		leveled = true
	exp_changed.emit(current_exp, exp_to_next)
	if leveled:
		_emit_all_stats()
	_schedule_persist(true)

func _stats_level_offset() -> int:
	return maxi(level - 1, 0)

func _recalculate_stats_for_level() -> void:
	var lv := _stats_level_offset()
	max_health = base_max_health + lv * health_per_level
	max_mana = base_max_mana + lv * mana_per_level
	exp_to_next = base_exp_to_next + lv * exp_per_level
	attack_damage = base_attack_damage + lv * attack_per_level
	defense = base_defense + lv * defense_per_level

func _level_up() -> void:
	level += 1
	_recalculate_stats_for_level()
	current_health = max_health
	current_mana = max_mana
	level_changed.emit(level)
	health_changed.emit(current_health, max_health)
	mana_changed.emit(current_mana, max_mana)
	print("[Player] 升级至 Lv.%d  HP%d MP%d ATK%d DEF%d 下一级%d经验" % [
		level, max_health, max_mana, attack_damage, defense, exp_to_next
	])

func die():
	died.emit()
	_persist_progress()
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("die"):
		sprite.play("die")
		set_physics_process(false)
		await sprite.animation_finished
	queue_free()

func _emit_all_stats() -> void:
	health_changed.emit(current_health, max_health)
	mana_changed.emit(current_mana, max_mana)
	exp_changed.emit(current_exp, exp_to_next)
	level_changed.emit(level)

func _load_progress_from_save() -> void:
	var progress := Global.get_player_progress()
	if progress.is_empty():
		level = 1
		current_exp = 0
	else:
		level = maxi(int(progress.get("player_level", 1)), 1)
		current_exp = maxi(int(progress.get("exp", 0)), 0)
	# 血蓝 / 攻防按等级推算，进关永远满血蓝，不读存档
	_recalculate_stats_for_level()
	# 若存档有自定义下一级经验则采用
	if not progress.is_empty() and progress.has("exp_to_next"):
		exp_to_next = maxi(int(progress.get("exp_to_next")), 1)
	current_health = max_health
	current_mana = max_mana

func get_progress_dict() -> Dictionary:
	return {
		"player_level": level,
		"exp": current_exp,
		"exp_to_next": exp_to_next,
	}

func _schedule_persist(immediate: bool = false) -> void:
	if immediate:
		_persist_timer = -1.0
		_persist_progress()
	else:
		_persist_timer = 0.8

func _persist_progress() -> void:
	Global.save_player_progress(get_progress_dict())
