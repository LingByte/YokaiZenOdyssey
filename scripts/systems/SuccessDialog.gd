extends AcceptDialog

var ok_button = $".".get_ok_button()

func _ready():
	# 创建一个空的 StyleBox
	var empty_stylebox = StyleBoxEmpty.new()
	empty_stylebox.content_margin_top = -4  # 向上移动文字
	ok_button.add_theme_stylebox_override("normal", empty_stylebox)
	ok_button.add_theme_stylebox_override("hover", empty_stylebox)
	ok_button.add_theme_stylebox_override("pressed", empty_stylebox)
	ok_button.add_theme_stylebox_override("focus", empty_stylebox)
	ok_button.add_theme_color_override("font_color", Color.WHITE)
	ok_button.add_theme_font_size_override("font_size", 18)

func _on_login_success_confirmed():
	get_tree().root.get_node("MainMenu").hide_login_panel()
