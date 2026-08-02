extends AcceptDialog

## 为 true 时，点确定会关闭登录面板（仅登录/注册成功使用）
var close_login_on_confirm: bool = false

const DIALOG_SIZE := Vector2i(420, 260)
const FONT_PATH := "res://assets/ttf/FZSTK.TTF"

@onready var ok_button = get_ok_button()

func _ready():
	transparent_bg = true
	borderless = true
	transparent = true
	dialog_autowrap = true
	unresizable = true

	var empty_stylebox = StyleBoxEmpty.new()
	empty_stylebox.content_margin_top = -4
	if ok_button:
		ok_button.add_theme_stylebox_override("normal", empty_stylebox)
		ok_button.add_theme_stylebox_override("hover", empty_stylebox)
		ok_button.add_theme_stylebox_override("pressed", empty_stylebox)
		ok_button.add_theme_stylebox_override("focus", empty_stylebox)
		ok_button.add_theme_color_override("font_color", Color.WHITE)
		ok_button.add_theme_font_size_override("font_size", 22)
		ok_button.custom_minimum_size = Vector2(120, 40)

	_apply_dialog_chrome()

func show_tip(message: String, close_login: bool = false) -> void:
	close_login_on_confirm = close_login
	dialog_text = message.strip_edges()
	_apply_dialog_chrome()
	popup_centered(DIALOG_SIZE)
	call_deferred("_center_message_label")

func _apply_dialog_chrome() -> void:
	size = DIALOG_SIZE
	min_size = DIALOG_SIZE
	var font := load(FONT_PATH) as Font if ResourceLoader.exists(FONT_PATH) else null
	if font:
		add_theme_font_override("font", font)
	add_theme_constant_override("buttons_min_height", 40)

func _center_message_label() -> void:
	var label := get_label()
	if label == null:
		return
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color(0.98, 0.95, 0.88))
	var font := load(FONT_PATH) as Font if ResourceLoader.exists(FONT_PATH) else null
	if font:
		label.add_theme_font_override("font", font)
	label.custom_minimum_size = Vector2(340, 120)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL

func _on_login_success_confirmed():
	if not close_login_on_confirm:
		return
	close_login_on_confirm = false
	var main_menu = get_tree().root.get_node_or_null("MainMenu")
	if main_menu:
		await main_menu.hide_login_panel()
