extends Node2D

@onready var area = $ExitArea
@onready var sprite = $AnimatedSprite2D  # 或 Sprite2D
@onready var player = null
var active = false
var player_on_exit = false

func _ready():
	area.body_entered.connect(_on_exit_area_body_entered)
	area.body_exited.connect(_on_exit_area_body_exited)
	hide_exit()
	show_exit()

# 调用这个函数让出口出现（外部触发）
func show_exit():
	visible = true
	area.monitoring = true
	sprite.visible = true
	active = true

func hide_exit():
	visible = false
	area.monitoring = false
	sprite.visible = false
	active = false

# 玩家进入出口区域
func _on_exit_area_body_entered(body):
	print("出发了碰撞")
	if body.is_in_group("player"):
		print("碰到了")
		player_on_exit = true
		player = body

func _on_exit_area_body_exited(body):
	print("出发了离开")
	if body.is_in_group("player"):
		print("离开了")
		player_on_exit = false
		player = null

func _process(delta):
	if active and player_on_exit and Input.is_action_just_pressed("move_up"):  # "move_up" 绑定 W
		change_scene()

func change_scene():
	Global.load_scene("res://scenes/levels/Shenxiao.tscn")  # 或你目标场景路径
