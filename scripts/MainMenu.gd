extends Node2D

@onready var buttons := [
	$StartGame,
	$LoadArchive,
	$SystemSet,
	$GameExit,
]
@onready var input_blocker: ColorRect = $InputBlocker
@onready var login_panel: Panel = $LoginPanel

var _panel_tween: Tween

func _ready():
	DisplayServer.window_set_title("禅妖山海行")
	var screen_width = get_viewport_rect().size.x

	for i in buttons.size():
		var btn = buttons[i]
		var target_pos = btn.position

		# 初始位置移到右边屏幕外
		btn.position.x = screen_width + 200
		btn.modulate.a = 0
		btn.pivot_offset = btn.size / 2  # 缩放居中

		var tween = create_tween()

		# 位置动画
		tween.tween_property(btn, "position", target_pos, 0.7)\
			.set_delay(i * 0.2)\
			.set_trans(Tween.TRANS_ELASTIC)\
			.set_ease(Tween.EASE_OUT)

		# 透明度动画（并行）
		tween.parallel().tween_property(btn, "modulate:a", 1.0, 0.5)\
			.set_delay(i * 0.2)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN_OUT)

func _on_game_exit_pressed() -> void:
	get_tree().quit()

func _on_start_game_pressed():
	# 检查是否登录
	if not Global.is_logged_in:
		show_login_panel()
		return
	
	# 新游戏模式
	input_blocker.visible = true
	$SaveSelectPanel.show_panel(true)

func _on_read_save_button_pressed():
	# 检查是否登录
	if not Global.is_logged_in:
		show_login_panel()
		return
	
	# 读取存档模式
	input_blocker.visible = true
	$SaveSelectPanel.show_panel(false)

func show_login_panel():
	input_blocker.visible = true
	input_blocker.modulate.a = 0.0
	if _panel_tween:
		_panel_tween.kill()
	_panel_tween = create_tween()
	_panel_tween.tween_property(input_blocker, "modulate:a", 1.0, 0.22)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	login_panel.play_show_animation()

func hide_login_panel():
	await login_panel.play_hide_animation()
	if _panel_tween:
		_panel_tween.kill()
	_panel_tween = create_tween()
	_panel_tween.tween_property(input_blocker, "modulate:a", 0.0, 0.18)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await _panel_tween.finished
	input_blocker.visible = false
	input_blocker.modulate.a = 1.0
	
func show_archive_panel():
	input_blocker.visible = true
	$SaveSelectPanel.show_panel(false)
	
func hide_archive_panel():
	$SaveSelectPanel.visible = false
	input_blocker.visible = false

func show_settings_panel():
	input_blocker.visible = true
	$SettingsPanel.visible = true

func hide_settings_panel():
	$SettingsPanel.visible = false
	input_blocker.visible = false
