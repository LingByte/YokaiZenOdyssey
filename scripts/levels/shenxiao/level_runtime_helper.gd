extends Object
class_name LevelRuntimeHelper
## 关卡统一：角色落点、分波敌人、清关开出口、结算统计

const PLAYER_SPAWN := Vector2(280, 640)
const LEVEL_EXIT_SCENE := preload("res://scenes/levels/components/LevelExit.tscn")
const WAVE_CONTROLLER_SCRIPT := preload("res://scripts/levels/shenxiao/LevelWaveController.gd")

const LEVEL_DISPLAY_NAMES := {
	"res://scenes/levels/shenxiaoTianmen.tscn": "天门试炼",
	"res://scenes/levels/Yuntailingzhen.tscn": "云台灵阵",
	"res://scenes/levels/YuQueQinTianTai.tscn": "玉阙擎天台",
}

## 默认三波分区（适用天门 / 云台 / 玉阙 长关卡）
const DEFAULT_WAVES := [
	{
		"left": 0.0,
		"right": 2100.0,
		"spawns": [
			Vector2(520, 560),
			Vector2(780, 520),
			Vector2(1100, 540),
		],
	},
	{
		"left": 2100.0,
		"right": 4800.0,
		"spawns": [
			Vector2(2500, 540),
			Vector2(3000, 500),
			Vector2(3600, 560),
			Vector2(4200, 520),
		],
	},
	{
		"left": 4800.0,
		"right": 9200.0,
		"spawns": [
			Vector2(5400, 520),
			Vector2(6200, 560),
			Vector2(7200, 500),
			Vector2(8200, 540),
		],
	},
]

static func character_scene_path() -> String:
	if Global.selected_character == "八戒":
		return "res://characters/player/types/BajiePlayer.tscn"
	return "res://characters/player/types/SoulPlayer.tscn"

static func waves_for_scene(scene_path: String) -> Array:
	# 目前三关共用分区；后续可按 scene_path 定制
	return DEFAULT_WAVES.duplicate(true)

static func ensure_player_spawn(host: Node) -> Marker2D:
	var spawn := host.get_node_or_null("PlayerSpawn") as Marker2D
	if spawn == null:
		spawn = Marker2D.new()
		spawn.name = "PlayerSpawn"
		host.add_child(spawn)
	spawn.position = PLAYER_SPAWN
	return spawn

static func spawn_player(host: Node) -> Node2D:
	var legacy := host.get_node_or_null("BasePlayer")
	if legacy:
		if legacy.is_in_group("player"):
			legacy.remove_from_group("player")
		legacy.visible = false
		legacy.queue_free()

	var spawn := ensure_player_spawn(host)
	var packed: PackedScene = load(character_scene_path())
	if packed == null:
		push_error("LevelRuntimeHelper: 无法加载角色场景")
		return null

	var player: Node2D = packed.instantiate()
	host.add_child(player)
	player.global_position = spawn.global_position
	player.add_to_group("player")
	player.visible = true
	print("[LevelRuntime] 角色 ", Global.selected_character, " @ ", player.global_position)
	return player

static func ensure_level_exit(host: Node) -> Node:
	var exit_node := host.get_node_or_null("LevelExit")
	if exit_node == null:
		exit_node = LEVEL_EXIT_SCENE.instantiate()
		exit_node.name = "LevelExit"
		host.add_child(exit_node)
	if exit_node is Node2D:
		var root := exit_node as Node2D
		if root.position != Vector2.ZERO:
			root.position = Vector2.ZERO
	if exit_node.has_method("hide_exit"):
		exit_node.hide_exit()
	return exit_node

static func _count_total_enemies(waves: Array) -> int:
	var total := 0
	for w in waves:
		total += (w.get("spawns", []) as Array).size()
	return total

static func _on_all_waves_cleared(host: Node, controller: Node) -> void:
	if controller and controller.has_method("force_open_exit_bounds"):
		controller.force_open_exit_bounds()
	var exit_node := host.get_node_or_null("LevelExit")
	if exit_node and exit_node.has_method("show_exit"):
		exit_node.show_exit()
	print("[LevelRuntime] 全波次清空，出口开启")

static func bootstrap(host: Node, player_hud: Node = null) -> Node2D:
	var scene_path := str(host.scene_file_path)
	var display := str(LEVEL_DISPLAY_NAMES.get(scene_path, host.name))
	Global.begin_level_run(display, scene_path)

	var exit_node := ensure_level_exit(host)
	var player := spawn_player(host)

	# 隐藏场景里旧的一次性刷怪点（改由波次控制器刷）
	var old_spawns := host.get_node_or_null("EnemySpawnContainer")
	if old_spawns:
		old_spawns.visible = false

	var waves := waves_for_scene(scene_path)
	Global.note_enemies_total(_count_total_enemies(waves))

	var controller: Node = WAVE_CONTROLLER_SCRIPT.new()
	controller.name = "LevelWaveController"
	host.add_child(controller)
	controller.all_waves_cleared.connect(_on_all_waves_cleared.bind(host, controller))
	controller.setup(host, waves, player)

	if waves.is_empty():
		if exit_node and exit_node.has_method("show_exit"):
			exit_node.show_exit()
	else:
		if exit_node and exit_node.has_method("hide_exit"):
			exit_node.hide_exit()

	if player and player.has_method("bind_hud"):
		player.bind_hud(player_hud)
	elif player_hud:
		if player and player_hud.has_method("bind_player_stats"):
			player_hud.bind_player_stats(player)
		elif player_hud.has_method("update_ui"):
			player_hud.update_ui()
	return player
