extends Node2D

@onready var icon = $Icon
@onready var glow = $Glow
@onready var label = $Label
@onready var tween: Tween
@onready var area = $Area2D

# 要跳转的目标场景路径（可在实例化时赋值）
var target_scene_path: String = "res://scenes/levels/shenxiaoTianmen.tscn"

# 关卡名，可在实例化时设置
var level_name: String = "玉阙擎天台"

func _ready():
	tween = create_tween()
	label.text = level_name
	label.visible = false
	start_glow_animation()

	# 绑定 Area2D 的 hover 信号
	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)
	area.input_event.connect(_on_area_input_event)

func _on_mouse_entered():
	label.visible = true
	glow.visible = false
	tween.kill()

func _on_mouse_exited():
	label.visible = false
	glow.visible = true
	start_glow_animation()

func start_glow_animation():
	glow.modulate.a = 0.4
	tween.kill()
	tween = create_tween().set_loops()
	tween.tween_property(glow, "modulate:a", 0.1, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(glow, "modulate:a", 0.4, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_area_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("进入关卡：", level_name)
		get_tree().change_scene_to_file(target_scene_path)
