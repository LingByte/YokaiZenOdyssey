extends "res://characters/enemies/base/BaseEnemy.gd"
## 1号敌人：紫焰骷髅 —— 继承 BaseEnemy.tscn / BaseEnemy.gd

const TARGET_HEIGHT := 96.0

func _ready() -> void:
	super._ready()
	_sync_sprite_scale()

func _sync_sprite_scale() -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	var anim: StringName = sprite.animation
	if anim == &"" and sprite.sprite_frames.has_animation(&"fly"):
		anim = &"fly"
	if not sprite.sprite_frames.has_animation(anim):
		return
	var tex: Texture2D = sprite.sprite_frames.get_frame_texture(anim, 0)
	if tex == null:
		return
	var h := float(tex.get_height())
	if h <= 1.0:
		return
	var s := TARGET_HEIGHT / h
	sprite.centered = true
	sprite.scale = Vector2(s, s)
