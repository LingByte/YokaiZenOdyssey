extends Node2D
## 通关出口：默认隐藏，清怪后由 LevelRuntimeHelper 调用 show_exit()
## 玩家站在出口按 W (move_up) 进入结算

@onready var area: Area2D = $ExitArea
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var active: bool = false
var player_on_exit: bool = false

func _ready() -> void:
	if area:
		area.collision_layer = 0
		area.collision_mask = 2 # 玩家层
		area.monitoring = false
		area.monitorable = false
		if not area.body_entered.is_connected(_on_exit_area_body_entered):
			area.body_entered.connect(_on_exit_area_body_entered)
		if not area.body_exited.is_connected(_on_exit_area_body_exited):
			area.body_exited.connect(_on_exit_area_body_exited)
	hide_exit()

func show_exit() -> void:
	visible = true
	if sprite:
		sprite.visible = true
		if sprite.sprite_frames and sprite.sprite_frames.has_animation(&"default"):
			sprite.play(&"default")
	if area:
		area.monitoring = true
	active = true
	print("[LevelExit] 出口已开启")

func hide_exit() -> void:
	visible = false
	if sprite:
		sprite.visible = false
	if area:
		area.monitoring = false
	active = false
	player_on_exit = false

func _on_exit_area_body_entered(body: Node) -> void:
	if body != null and body.is_in_group("player"):
		player_on_exit = true

func _on_exit_area_body_exited(body: Node) -> void:
	if body != null and body.is_in_group("player"):
		player_on_exit = false

func _process(_delta: float) -> void:
	if active and player_on_exit and Input.is_action_just_pressed("move_up"):
		_go_settle()

func _go_settle() -> void:
	# 结算数据由 LevelRuntimeHelper 维护在 Global
	Global.finalize_level_settle()
	Global.load_scene("res://scenes/SettleUp.tscn")
