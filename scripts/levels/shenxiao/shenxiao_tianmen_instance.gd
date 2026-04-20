extends Node2D

@onready var player_spawn = $PlayerSpawn
var player_scene = preload("res://characters/player/types/SoulPlayer.tscn")
@onready var pack_panel = $CanvasLayer/Panel

# Called when the node enters the scene tree for the first time.
func _ready():
	var player = player_scene.instantiate()
	player.global_position = player_spawn.global_position
	player.add_to_group("player")
	add_child(player)
	
	# 初始化背包面板（如果存在）
	if pack_panel:
		pack_panel.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# 监听 C 键打开/关闭背包
	if Input.is_action_just_pressed("open_backpack"):
		toggle_backpack()

func toggle_backpack():
	# 优先使用当前场景的背包面板
	if pack_panel:
		pack_panel.visible = not pack_panel.visible
	else:
		print("警告: 当前关卡场景没有背包面板")
