extends Node2D

@onready var player_spawn = $PlayerSpawn
@onready var base_player = $BasePlayer
@onready var player_hud = $CanvasLayer/PlayerHUD
@onready var pack_panel = $CanvasLayer/Panel
var player: Node2D = null

# Called when the node enters the scene tree for the first time.
func _ready():
	# 隐藏基础玩家
	if base_player:
		base_player.visible = false
		base_player.queue_free()
	
	# 根据选择的角色生成对应的玩家
	var character_scene = ""
	if Global.selected_character == "悟空":
		character_scene = "res://characters/player/types/SoulPlayer.tscn"
	elif Global.selected_character == "八戒":
		character_scene = "res://characters/player/types/BajiePlayer.tscn"
	else:
		# 默认使用悟空
		character_scene = "res://characters/player/types/SoulPlayer.tscn"
	
	print("[Yuntailingzhen] 生成角色: ", Global.selected_character, " 场景: ", character_scene)
	
	if character_scene != "":
		var player_scene = load(character_scene)
		if player_scene:
			player = player_scene.instantiate()
			player.global_position = player_spawn.global_position
			player.add_to_group("player")
			add_child(player)
			player.visible = true
			print("[Yuntailingzhen] 角色生成成功，位置: ", player.global_position)
	
	# 获取背包面板
	if pack_panel:
		pack_panel.visible = false
		print("背包面板已找到并初始化")
	else:
		print("警告: 无法找到背包面板节点")
		# 尝试使用 get_node 获取
		pack_panel = get_node_or_null("CanvasLayer/Panel")
		if pack_panel:
			pack_panel.visible = false
			print("通过 get_node 找到背包面板")
	
	# 初始化HUD
	if player_hud:
		player_hud.update_ui()

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
