extends Node2D

@onready var player_spawn = $PlayerSpawn
@onready var base_player = $BasePlayer
@onready var player_hud = $CanvasLayer/PlayerHUD
var pack_panel: Control = null
var player: Node2D = null

func _ready():
	if base_player:
		base_player.visible = false
		base_player.queue_free()

	var character_scene = ""
	if Global.selected_character == "悟空":
		character_scene = "res://characters/player/types/SoulPlayer.tscn"
	elif Global.selected_character == "八戒":
		character_scene = "res://characters/player/types/BajiePlayer.tscn"
	else:
		character_scene = "res://characters/player/types/SoulPlayer.tscn"

	print("[YuQueQinTianTai] 生成角色: ", Global.selected_character, " 场景: ", character_scene)

	if character_scene != "":
		var player_scene = load(character_scene)
		if player_scene:
			player = player_scene.instantiate()
			player.global_position = player_spawn.global_position
			player.add_to_group("player")
			add_child(player)
			player.visible = true
			print("[YuQueQinTianTai] 角色生成成功，位置: ", player.global_position)

	pack_panel = BackpackLevelHelper.install(self)

	if player_hud:
		player_hud.update_ui()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("open_backpack"):
		toggle_backpack()

func toggle_backpack():
	if pack_panel == null or not is_instance_valid(pack_panel):
		pack_panel = BackpackLevelHelper.install(self)
	BackpackLevelHelper.toggle(pack_panel)
