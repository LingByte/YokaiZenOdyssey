extends Control

@onready var soul_button = $SoulButton
@onready var bajie_button = $BajieButton
@onready var soul_idle = $SoulIdle
@onready var bajie_idle = $BajieIdle
@onready var confirm_button = $ConfirmButton
@onready var return_button = $ReturnButton
@onready var selected_character_label = $SelectedCharacterLabel

var selected_character: String = ""

func _ready():
	soul_button.pressed.connect(_on_soul_selected)
	bajie_button.pressed.connect(_on_bajie_selected)
	soul_idle.pressed.connect(_on_soul_selected)
	bajie_idle.pressed.connect(_on_bajie_selected)
	confirm_button.pressed.connect(_on_confirm_selected)
	return_button.pressed.connect(_on_return_pressed)
	return_button.mouse_entered.connect(_on_return_mouse_entered)
	return_button.mouse_exited.connect(_on_return_mouse_exited)
	
	# 初始设置为灰色
	soul_idle.modulate = Color(0.5, 0.5, 0.5, 1)
	bajie_idle.modulate = Color(0.5, 0.5, 0.5, 1)
	
	selected_character_label.text = "请选择角色"

func _on_soul_selected():
	selected_character = "SoulPlayer"
	selected_character_label.text = "已选择: 灵魂行者"
	soul_idle.modulate = Color.WHITE
	bajie_idle.modulate = Color(0.5, 0.5, 0.5, 1)
	_play_scale_animation(soul_idle)

func _on_bajie_selected():
	selected_character = "BajiePlayer"
	selected_character_label.text = "已选择: 八戒"
	bajie_idle.modulate = Color.WHITE
	soul_idle.modulate = Color(0.5, 0.5, 0.5, 1)
	_play_scale_animation(bajie_idle)

func _play_scale_animation(node: TextureButton):
	var tween = create_tween()
	tween.tween_property(node, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(node, "scale", Vector2(1.0, 1.0), 0.1)

func _on_confirm_selected():
	if selected_character.is_empty():
		return
	# TODO: 保存选择的角色并进入游戏
	print("Selected character: ", selected_character)
	# 这里可以切换到游戏场景，并实例化对应角色

func _on_return_pressed():
	# 点击旋转效果
	var tween = create_tween()
	tween.tween_property(return_button, "rotation_degrees", 15, 0.1)
	tween.tween_property(return_button, "rotation_degrees", 0, 0.1)
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_return_mouse_entered():
	# hover 放大效果
	var tween = create_tween()
	tween.tween_property(return_button, "scale", Vector2(1.1, 1.1), 0.15)

func _on_return_mouse_exited():
	# 鼠标移出恢复
	var tween = create_tween()
	tween.tween_property(return_button, "scale", Vector2(1.0, 1.0), 0.15)
