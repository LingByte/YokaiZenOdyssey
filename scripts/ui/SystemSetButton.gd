extends Button

var tween: Tween

func _ready():
	# 设置 pivot 为按钮中心
	pivot_offset = size / 2

func _on_mouse_entered():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.15)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

func _on_mouse_exited():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.15)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)


func _on_pressed() -> void:
	var main_menu = get_tree().root.get_node_or_null("MainMenu")
	if main_menu:
		main_menu.show_settings_panel()
	else:
		print("警告: 未找到MainMenu节点")
