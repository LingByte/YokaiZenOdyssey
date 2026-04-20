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

func _on_pressed():
	print("[newStartButton] 新的开始按钮被点击")
	# 检查是否已登录
	if not Global.is_logged_in:
		print("[newStartButton] 未登录，显示登录面板")
		get_tree().root.get_node("MainMenu").show_login_panel()
		return
	
	# 已登录，直接进入游戏
	print("[newStartButton] 已登录，进入游戏场景")
	Global.load_scene("res://scenes/levels/Shenxiao.tscn")
