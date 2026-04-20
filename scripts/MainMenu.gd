extends Node2D

@onready var buttons := [
	$StartGame,
	$LoadArchive,
	$SystemSet,
	$GameExit,
]

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

func show_login_panel():
	$InputBlocker.visible = true
	$LoginPanel.visible = true

func hide_login_panel():
	$LoginPanel.visible = false
	$InputBlocker.visible = false
	
func show_archive_panel():
	$InputBlocker.visible = true
	$SaveSelectPanel.visible = true
	
func hide_archive_panel():
	$SaveSelectPanel.visible = false
	$InputBlocker.visible = false

func show_settings_panel():
	$InputBlocker.visible = true
	$SettingsPanel.visible = true

func hide_settings_panel():
	$SettingsPanel.visible = false
	$InputBlocker.visible = false
	
