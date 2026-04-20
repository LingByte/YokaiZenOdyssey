extends Node2D

@onready var player_spawn = $PlayerSpawn
var player_scene = preload("res://characters/player/types/SoulPlayer.tscn")
var pack_panel: Panel = null

# Called when the node enters the scene tree for the first time.
func _ready():
	var player = player_scene.instantiate()
	player.global_position = player_spawn.global_position
	player.add_to_group("player")
	add_child(player)
	
	# 获取背包面板
	pack_panel = get_node_or_null("CanvasLayer/Panel")
	if pack_panel:
		pack_panel.visible = false
		print("背包面板已找到并初始化")
	else:
		print("警告: 无法找到背包面板节点")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# 监听 C 键打开/关闭背包
	if Input.is_action_just_pressed("open_backpack"):
		toggle_backpack()

func toggle_backpack():
	# 如果 pack_panel 为 null，尝试重新获取
	if not pack_panel:
		pack_panel = get_node_or_null("CanvasLayer/Panel")
	
	# 优先使用当前场景的背包面板
	if pack_panel:
		pack_panel.visible = not pack_panel.visible
		print("背包面板状态: ", pack_panel.visible)
	else:
		print("警告: 当前关卡场景没有背包面板")
