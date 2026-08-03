extends CharacterBody2D
## 敌人基类：巡逻 / 追击 / 接触伤害 / 击杀掉经验
## 具体敌人请 instance BaseEnemy.tscn 并覆盖外观与数值。

signal killed(enemy: Node, exp_reward: int)

@export var max_health: int = 40
@export var move_speed: float = 80.0
@export var chase_speed: float = 140.0
@export var contact_damage: int = 10
@export var exp_reward: int = 25
@export var patrol_range: float = 160.0
@export var detect_range: float = 360.0
@export var attack_range: float = 72.0
@export var bob_amplitude: float = 10.0
@export var bob_speed: float = 2.2
@export var gravity: float = 0.0
@export var flying: bool = true
@export var face_right_by_default: bool = true
@export var can_chase: bool = true
@export var health_bar_offset: Vector2 = Vector2(0, -58)
@export var health_bar_size: Vector2 = Vector2(56, 8)
@export var show_health_bar_when_full: bool = true

var current_health: int
var _origin: Vector2
var _dir: float = 1.0
var _bob_t: float = 0.0
var _dead: bool = false
var _attack_cooldown: float = 0.0
var _target: Node2D = null

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var hitbox: Area2D = $Hitbox
@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
	add_to_group("enemy")
	# 层4=敌人刚体，只碰地面；不与玩家刚体互推
	collision_layer = 4
	collision_mask = 1
	current_health = max_health
	_origin = global_position
	_dir = 1.0 if face_right_by_default else -1.0
	_setup_health_bar()
	_apply_facing()
	_play_move_anim()
	if hurtbox:
		# 检测玩家层(2)
		hurtbox.collision_layer = 0
		hurtbox.collision_mask = 2
		hurtbox.monitoring = true
		hurtbox.monitorable = false
		if not hurtbox.body_entered.is_connected(_on_hurtbox_body_entered):
			hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	if hitbox and not hitbox.area_entered.is_connected(_on_hitbox_area_entered):
		hitbox.area_entered.connect(_on_hitbox_area_entered)

func _physics_process(delta: float) -> void:
	if _dead:
		return
	if _attack_cooldown > 0.0:
		_attack_cooldown = maxf(0.0, _attack_cooldown - delta)

	_bob_t += delta * bob_speed
	_update_target()
	_think_movement(delta)

	if not flying:
		if not is_on_floor():
			velocity.y += gravity * delta
		elif velocity.y > 0.0:
			velocity.y = 0.0

	move_and_slide()
	_sync_bob_offset()
	_damage_overlapping_players()
	_update_animation()

func _update_target() -> void:
	_target = null
	var players := get_tree().get_nodes_in_group("player")
	var best_dist := detect_range
	for node in players:
		if node == null or not is_instance_valid(node):
			continue
		if node is Node2D:
			var d: float = global_position.distance_to((node as Node2D).global_position)
			if d <= best_dist:
				best_dist = d
				_target = node as Node2D

func _think_movement(_delta: float) -> void:
	if can_chase and _target != null:
		var to_player := _target.global_position - global_position
		var dist := to_player.length()
		if dist <= attack_range * 0.85:
			velocity = Vector2.ZERO
		else:
			if flying:
				velocity = to_player.normalized() * chase_speed
			else:
				velocity.x = signf(to_player.x) * chase_speed
				velocity.y = 0.0
			_dir = 1.0 if to_player.x >= 0.0 else -1.0
			_apply_facing()
		return

	velocity.x = _dir * move_speed
	if flying:
		velocity.y = 0.0
	var dx := global_position.x - _origin.x
	if dx > patrol_range:
		_dir = -1.0
		_apply_facing()
	elif dx < -patrol_range:
		_dir = 1.0
		_apply_facing()
	if is_on_wall():
		_dir *= -1.0
		_apply_facing()

func _damage_overlapping_players() -> void:
	if _attack_cooldown > 0.0 or hurtbox == null:
		return
	for body in hurtbox.get_overlapping_bodies():
		_try_damage_player(body)

func _try_damage_player(body: Node) -> void:
	if _dead or _attack_cooldown > 0.0:
		return
	if body == null or body == self or body.is_in_group("enemy"):
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(contact_damage)
		_attack_cooldown = 0.65
		_flash_attack()

func _flash_attack() -> void:
	if sprite == null:
		return
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(1.5, 0.85, 0.85), 0.06)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.12)

func _sync_bob_offset() -> void:
	if not flying or sprite == null:
		return
	sprite.position.y = sin(_bob_t) * bob_amplitude

func _apply_facing() -> void:
	if sprite == null:
		return
	sprite.flip_h = _dir < 0.0
	var face := 1.0 if _dir >= 0.0 else -1.0
	if collision:
		collision.position.x = absf(collision.position.x) * face
	_mirror_area_shapes(hurtbox, face)
	_mirror_area_shapes(hitbox, face)

func _mirror_area_shapes(area: Area2D, face: float) -> void:
	if area == null:
		return
	for child in area.get_children():
		if child is CollisionShape2D:
			child.position.x = absf(child.position.x) * face

func _play_move_anim() -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	if sprite.sprite_frames.has_animation(&"fly"):
		sprite.play(&"fly")
	elif sprite.sprite_frames.has_animation(&"idle"):
		sprite.play(&"idle")
	elif sprite.sprite_frames.has_animation(&"run"):
		sprite.play(&"run")

func _update_animation() -> void:
	if _dead:
		return
	_play_move_anim()

func is_defeated() -> bool:
	return _dead

func _setup_health_bar() -> void:
	if health_bar == null:
		return
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.show_percentage = false
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layout_health_bar()
	_refresh_health_bar()

func _layout_health_bar() -> void:
	if health_bar == null:
		return
	var half_w := health_bar_size.x * 0.5
	health_bar.position = Vector2(health_bar_offset.x - half_w, health_bar_offset.y)
	health_bar.size = health_bar_size

func _refresh_health_bar() -> void:
	if health_bar == null:
		return
	health_bar.max_value = maxi(1, max_health)
	health_bar.value = clampi(current_health, 0, max_health)
	var ratio := float(current_health) / float(maxi(1, max_health))
	var fill := health_bar.get_theme_stylebox("fill")
	if fill is StyleBoxFlat:
		var style := (fill as StyleBoxFlat).duplicate() as StyleBoxFlat
		if ratio > 0.55:
			style.bg_color = Color(0.86, 0.22, 0.22, 1.0)
		elif ratio > 0.25:
			style.bg_color = Color(0.92, 0.62, 0.18, 1.0)
		else:
			style.bg_color = Color(0.95, 0.28, 0.12, 1.0)
		health_bar.add_theme_stylebox_override("fill", style)
	if _dead:
		health_bar.visible = false
	else:
		health_bar.visible = show_health_bar_when_full or current_health < max_health

func take_damage(amount: int) -> void:
	if _dead or amount <= 0:
		return
	current_health -= amount
	_refresh_health_bar()
	if sprite:
		sprite.modulate = Color(1.4, 0.7, 0.7)
		var tw := create_tween()
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.15)
	if current_health <= 0:
		die()

func die() -> void:
	if _dead:
		return
	_dead = true
	velocity = Vector2.ZERO
	_refresh_health_bar()
	if collision:
		collision.set_deferred("disabled", true)
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
	if hitbox:
		hitbox.set_deferred("monitorable", false)

	_grant_exp_to_players()
	killed.emit(self, exp_reward)

	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(&"die"):
		sprite.play(&"die")
		await sprite.animation_finished
	else:
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.35)
		await tw.finished
	queue_free()

func _grant_exp_to_players() -> void:
	if exp_reward <= 0:
		return
	for node in get_tree().get_nodes_in_group("player"):
		if node != null and is_instance_valid(node) and node.has_method("gain_exp"):
			node.gain_exp(exp_reward)

func _on_hurtbox_body_entered(body: Node) -> void:
	_try_damage_player(body)

func _on_hitbox_area_entered(area: Area2D) -> void:
	if _dead:
		return
	if area.is_in_group("player_attack"):
		var dmg := int(area.get_meta("damage", 10))
		take_damage(dmg)
