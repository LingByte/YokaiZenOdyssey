extends "res://characters/player/base/BasePlayer.gd"

## 新 idle/run/jump/jump_flip 单帧约 1256px；攻击/受伤等旧表另算
const TARGET_HEIGHT_HIRES := 160.0
const TARGET_HEIGHT_LEGACY := 220.0
const FLIP_ROTATION_DURATION := 0.38

var _flip_tween: Tween

func _ready():
	super._ready()
	max_health = 150
	speed = 300.0
	max_jumps = 2
	double_jump_force = -440.0
	if sprite:
		if not sprite.animation_changed.is_connected(_on_sprite_animation_changed):
			sprite.animation_changed.connect(_on_sprite_animation_changed)
		_sync_sprite_visual()

func _on_sprite_animation_changed() -> void:
	_sync_sprite_visual()

func update_animation() -> void:
	var before: StringName = sprite.animation if sprite else &""
	super.update_animation()
	if sprite and sprite.animation != before:
		_sync_sprite_visual()

func handle_attack() -> void:
	super.handle_attack()
	_sync_sprite_visual()

func take_damage(amount: int) -> void:
	super.take_damage(amount)
	_sync_sprite_visual()

func _on_double_jump() -> void:
	super._on_double_jump()
	_sync_sprite_visual()
	_play_flip_spin()

func _on_landed() -> void:
	super._on_landed()
	_stop_flip_spin()

func _play_flip_spin() -> void:
	if sprite == null:
		return
	if _flip_tween:
		_flip_tween.kill()
	sprite.rotation = 0.0
	var dir: float = -1.0 if sprite.flip_h else 1.0
	_flip_tween = create_tween()
	_flip_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_flip_tween.tween_property(sprite, "rotation", dir * TAU, FLIP_ROTATION_DURATION)
	_flip_tween.finished.connect(_on_flip_spin_finished, CONNECT_ONE_SHOT)

func _on_flip_spin_finished() -> void:
	if sprite:
		sprite.rotation = 0.0

func _stop_flip_spin() -> void:
	if _flip_tween:
		_flip_tween.kill()
		_flip_tween = null
	if sprite:
		sprite.rotation = 0.0

func _target_height_for(anim: StringName) -> float:
	if anim == &"idle" or anim == &"run" or anim == &"jump" or anim == &"jump_flip":
		return TARGET_HEIGHT_HIRES
	return TARGET_HEIGHT_LEGACY

func _sync_sprite_visual() -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	var anim: StringName = sprite.animation
	if not sprite.sprite_frames.has_animation(anim):
		return
	var tex: Texture2D = sprite.sprite_frames.get_frame_texture(anim, sprite.frame)
	if tex == null:
		return
	var h: float = float(tex.get_height())
	if h <= 1.0:
		return
	var target: float = _target_height_for(anim)
	var s: float = target / h
	sprite.centered = true
	sprite.scale = Vector2(s, s)
	# 翻滚时保留旋转；其余动作脚底对齐
	if anim != &"jump_flip":
		sprite.position = Vector2(0.0, -target * 0.5)
	else:
		sprite.position = Vector2(0.0, -target * 0.45)
