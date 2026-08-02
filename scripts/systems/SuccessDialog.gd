extends AcceptDialog

## 为 true 时，点确定会关闭登录面板（仅登录/注册成功使用）
var close_login_on_confirm: bool = false

@onready var ok_button = get_ok_button()

func _ready():
	var empty_stylebox = StyleBoxEmpty.new()
	empty_stylebox.content_margin_top = -4
	ok_button.add_theme_stylebox_override("normal", empty_stylebox)
	ok_button.add_theme_stylebox_override("hover", empty_stylebox)
	ok_button.add_theme_stylebox_override("pressed", empty_stylebox)
	ok_button.add_theme_stylebox_override("focus", empty_stylebox)
	ok_button.add_theme_color_override("font_color", Color.WHITE)
	ok_button.add_theme_font_size_override("font_size", 18)

func show_tip(message: String, close_login: bool = false) -> void:
	close_login_on_confirm = close_login
	dialog_text = message
	popup_centered()

func _on_login_success_confirmed():
	if not close_login_on_confirm:
		return
	close_login_on_confirm = false
	var main_menu = get_tree().root.get_node_or_null("MainMenu")
	if main_menu:
		await main_menu.hide_login_panel()
