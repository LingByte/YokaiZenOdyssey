extends Control
## 关卡结算：贴合背景装饰框，无黑色面板

const FONT_PATH := "res://assets/ttf/FZSTK.TTF"
const MAP_SCENE := "res://scenes/levels/Shenxiao.tscn"

@onready var title_label: Label = $Content/TitleLabel
@onready var time_label: Label = $Content/TimeLabel
@onready var kill_label: Label = $Content/KillLabel
@onready var level_label: Label = $Content/LevelLabel
@onready var btn_map: Button = $Content/ReturnMapButton
@onready var btn_retry: Button = $Content/RetryButton

func _ready() -> void:
	var font: Font = load(FONT_PATH) as Font if ResourceLoader.exists(FONT_PATH) else null
	for node in [title_label, time_label, kill_label, level_label, btn_map, btn_retry]:
		if node and font:
			node.add_theme_font_override("font", font)

	var data: Dictionary = Global.consume_settle_result()
	var seconds := float(data.get("clear_time_sec", 0.0))
	var kills := int(data.get("enemies_killed", 0))
	var level_name := str(data.get("level_name", "关卡"))
	var player_lv := int(data.get("player_level", 1))

	title_label.text = "通关结算"
	level_label.text = "关卡：%s　　角色等级：Lv.%d" % [level_name, maxi(player_lv, 1)]
	time_label.text = "通关用时：%s" % _format_time(seconds)
	kill_label.text = "击败敌人：%d" % kills

	btn_map.pressed.connect(_on_return_map)
	btn_retry.pressed.connect(_on_retry)

func _format_time(sec: float) -> String:
	var total := int(floor(sec))
	var m := total / 60
	var s := total % 60
	var ms := int((sec - float(total)) * 100.0)
	return "%02d:%02d.%02d" % [m, s, ms]

func _on_return_map() -> void:
	Global.load_scene(MAP_SCENE)

func _on_retry() -> void:
	var path := Global.pending_retry_scene
	if path.is_empty():
		path = MAP_SCENE
	Global.load_scene(path)
