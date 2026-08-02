extends Panel

const TEX_LOGIN := preload("res://assets/enter/loginPanel.png")
const TEX_REGISTER := preload("res://assets/enter/registerPanel.png")
const TEX_LOGIN_BTN := preload("res://assets/button/loginButton.png")
const TEX_REGISTER_BTN := preload("res://assets/button/registerButton.png")

# 按素材比例适配面板尺寸（登录 362x444，注册 433x576），适配 720 高度
const PANEL_LOGIN_SIZE := Vector2(490, 600)
const PANEL_REGISTER_SIZE := Vector2(490, 652)

var is_register_mode: bool = false
var _animating: bool = false
var _mode_switching: bool = false
var _scan_band: ColorRect
var _scan_core: ColorRect
var _glow: ColorRect
var _form_nodes: Array[Control] = []
var _panel_style: StyleBoxTexture

@onready var agree_checkbox = $UserAgree/AgreeCheckBox
@onready var login_button = $LoginButton
@onready var register_button = $RegisterButton
@onready var switch_mode_button = $SwitchModeButton
@onready var agreement_label = $UserAgree/AgreementLabel
@onready var color_react = $"../InputBlocker"
@onready var name_input = $NameInput
@onready var name_label = $NameLabel
@onready var username_input = $UsernameInput
@onready var username_label = $UsernameLabel
@onready var password_input = $PasswordInput
@onready var password_label = $PasswordLabel
@onready var user_agree = $UserAgree
@onready var close_button = $CloseButton

# 登录布局（配合 loginPanel「登录」标题区）
const LAYOUT_LOGIN := {
	"username": Vector2(150, 220),
	"username_label": Vector2(85, 220),
	"password": Vector2(150, 310),
	"password_label": Vector2(85, 309),
	"user_agree": Vector2(100, 390),
	"action_button": Vector2(176, 470),
	"switch_mode": Vector2(165, 530),
	"close": Vector2(420, 20),
}

# 注册布局（整体下移，为标题区和 nickname 留空）
const LAYOUT_REGISTER := {
	"username": Vector2(145, 205),
	"username_label": Vector2(80, 205),
	"name": Vector2(145, 285),
	"name_label": Vector2(80, 284),
	"password": Vector2(145, 365),
	"password_label": Vector2(80, 364),
	"user_agree": Vector2(95, 445),
	"action_button": Vector2(155, 525),
	"switch_mode": Vector2(165, 610),
	"close": Vector2(420, 20),
}

func _ready():
	clip_contents = true
	_setup_panel_style()
	_setup_fx_layers()
	_collect_form_nodes()

	color_react.color = Color(0, 0, 0, 0.55)
	color_react.mouse_filter = MOUSE_FILTER_STOP
	agreement_label.bbcode_enabled = true
	agreement_label.meta_underlined = true
	agreement_label.text = "我已阅读并同意 [url=user][color=#e8c86a]《用户协议》[/color][/url] 和 [url=privacy][color=#e8c86a]《隐私政策》[/color][/url]"

	_ensure_policy_popups()
	_skin_action_buttons()
	_apply_mode_layout(false)
	_set_form_alpha(1.0)
	_update_action_button_state(agree_checkbox.button_pressed if agree_checkbox else false)

	if not agree_checkbox.toggled.is_connected(_on_agree_checkbox_toggled):
		agree_checkbox.connect("toggled", _on_agree_checkbox_toggled)
	if not agreement_label.meta_clicked.is_connected(_on_agreement_label_meta_clicked):
		agreement_label.connect("meta_clicked", _on_agreement_label_meta_clicked)
	if switch_mode_button and not switch_mode_button.pressed.is_connected(_on_switch_mode_pressed):
		switch_mode_button.connect("pressed", _on_switch_mode_pressed)

func _setup_panel_style() -> void:
	_panel_style = StyleBoxTexture.new()
	_panel_style.texture = TEX_LOGIN
	add_theme_stylebox_override("panel", _panel_style)

func _skin_action_buttons() -> void:
	_apply_button_texture(login_button, TEX_LOGIN_BTN)
	_apply_button_texture(register_button, TEX_REGISTER_BTN)
	# 注册按钮图已含「注册」文字
	if register_button:
		register_button.text = ""

func _apply_button_texture(button: Button, texture: Texture2D) -> void:
	if button == null or texture == null:
		return
	var style := StyleBoxTexture.new()
	style.texture = texture
	for key in [
		"normal", "normal_mirrored",
		"pressed", "pressed_mirrored",
		"hover", "hover_mirrored",
		"hover_pressed", "hover_pressed_mirrored",
		"disabled", "disabled_mirrored",
		"focus",
	]:
		button.add_theme_stylebox_override(key, style)

func _collect_form_nodes() -> void:
	_form_nodes.clear()
	for node in [
		username_label, username_input,
		name_label, name_input,
		password_label, password_input,
		user_agree, login_button, register_button, switch_mode_button,
	]:
		if node:
			_form_nodes.append(node)

func _setup_fx_layers() -> void:
	_glow = ColorRect.new()
	_glow.name = "PanelGlow"
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow.color = Color(0.85, 0.72, 0.35, 0.0)
	_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_glow.offset_left = -10
	_glow.offset_top = -10
	_glow.offset_right = 10
	_glow.offset_bottom = 10
	add_child(_glow)
	move_child(_glow, 0)

	_scan_band = ColorRect.new()
	_scan_band.name = "ScanBand"
	_scan_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scan_band.color = Color(0.95, 0.82, 0.4, 0.12)
	_scan_band.visible = false
	_scan_band.size = Vector2(size.x, 56)
	_scan_band.position = Vector2(0, -56)
	add_child(_scan_band)

	_scan_core = ColorRect.new()
	_scan_core.name = "ScanCore"
	_scan_core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scan_core.color = Color(1.0, 0.92, 0.55, 0.85)
	_scan_core.visible = false
	_scan_core.size = Vector2(size.x, 3)
	_scan_core.position = Vector2(0, -3)
	add_child(_scan_core)

func play_show_animation() -> void:
	if _animating:
		return
	_animating = true
	visible = true
	modulate.a = 0.0
	scale = Vector2(0.88, 0.94)
	_apply_mode_layout(is_register_mode)
	_set_form_alpha(1.0)
	_reset_scan_line()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.28)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.42)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_glow, "color:a", 0.18, 0.2)
	tween.tween_property(_scan_band, "position:y", size.y + 8.0, 0.55)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_scan_core, "position:y", size.y + 8.0, 0.55)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

	var fade := create_tween()
	fade.set_parallel(true)
	fade.tween_property(_scan_band, "modulate:a", 0.0, 0.18)
	fade.tween_property(_scan_core, "modulate:a", 0.0, 0.18)
	fade.tween_property(_glow, "color:a", 0.0, 0.35)
	await fade.finished

	_scan_band.visible = false
	_scan_core.visible = false
	_animating = false

	if username_input:
		username_input.grab_focus()

func play_hide_animation() -> void:
	if _animating:
		return
	_animating = true
	_reset_scan_line()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_scan_band, "position:y", -56.0, 0.35)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(_scan_core, "position:y", -3.0, 0.35)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.28)\
		.set_delay(0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(0.92, 0.96), 0.28)\
		.set_delay(0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished

	_scan_band.visible = false
	_scan_core.visible = false
	visible = false
	modulate.a = 1.0
	scale = Vector2.ONE
	# 关闭后回到登录态，下次打开是登录面板
	is_register_mode = false
	_apply_mode_layout(false)
	_animating = false

func _reset_scan_line() -> void:
	_scan_band.visible = true
	_scan_core.visible = true
	_scan_band.modulate.a = 1.0
	_scan_core.modulate.a = 1.0
	_scan_band.size = Vector2(size.x, 56)
	_scan_core.size = Vector2(size.x, 3)
	_scan_band.position = Vector2(0, -56)
	_scan_core.position = Vector2(0, -3)

func _on_agree_checkbox_toggled(pressed: bool):
	# 保持可点击，未勾选时由按钮内部弹提示
	_update_action_button_state(pressed)

func _update_action_button_state(agreed: bool) -> void:
	var tint := Color.WHITE if agreed else Color(0.72, 0.72, 0.72, 0.92)
	if login_button:
		login_button.disabled = false
		login_button.modulate = tint
	if register_button:
		register_button.disabled = false
		register_button.modulate = tint

func _on_switch_mode_pressed():
	if _animating or _mode_switching:
		return
	_rerender_form(not is_register_mode)

func _rerender_form(to_register: bool) -> void:
	_mode_switching = true
	if switch_mode_button:
		switch_mode_button.disabled = true

	# 1) 整表淡出 + 扫描线扫过
	_reset_scan_line()
	var out_tween := create_tween()
	out_tween.set_parallel(true)
	out_tween.tween_property(_scan_band, "position:y", size.y + 8.0, 0.32)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	out_tween.tween_property(_scan_core, "position:y", size.y + 8.0, 0.32)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	out_tween.tween_property(_glow, "color:a", 0.16, 0.18)
	out_tween.tween_property(self, "modulate:a", 0.0, 0.22)\
		.set_delay(0.08)
	var out_index := 0
	for node in _form_nodes:
		if node == null or not node.visible:
			continue
		out_tween.tween_property(node, "modulate:a", 0.0, 0.18)\
			.set_delay(out_index * 0.02)
		out_index += 1

	await out_tween.finished

	# 2) 切换皮肤 + 重排全部字段
	is_register_mode = to_register
	_clear_form_inputs()
	_apply_mode_layout(to_register)
	_set_form_alpha(0.0)
	modulate.a = 0.0
	scale = Vector2(0.94, 0.96)

	# 3) 新面板入场
	_reset_scan_line()
	var in_tween := create_tween()
	in_tween.set_parallel(true)
	in_tween.tween_property(self, "modulate:a", 1.0, 0.28)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	in_tween.tween_property(self, "scale", Vector2.ONE, 0.36)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	in_tween.tween_property(_scan_band, "position:y", size.y + 8.0, 0.42)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	in_tween.tween_property(_scan_core, "position:y", size.y + 8.0, 0.42)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	var visible_nodes: Array[Control] = []
	for node in _form_nodes:
		if node.visible:
			visible_nodes.append(node)

	for i in visible_nodes.size():
		var node := visible_nodes[i]
		var base_x := node.position.x
		node.position.x = base_x + 22.0
		in_tween.tween_property(node, "modulate:a", 1.0, 0.22)\
			.set_delay(0.05 + i * 0.04)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		in_tween.tween_property(node, "position:x", base_x, 0.28)\
			.set_delay(0.05 + i * 0.04)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	await in_tween.finished

	var fade := create_tween()
	fade.set_parallel(true)
	fade.tween_property(_scan_band, "modulate:a", 0.0, 0.15)
	fade.tween_property(_scan_core, "modulate:a", 0.0, 0.15)
	fade.tween_property(_glow, "color:a", 0.0, 0.25)
	await fade.finished

	_scan_band.visible = false
	_scan_core.visible = false
	if switch_mode_button:
		switch_mode_button.disabled = false
	_mode_switching = false

	if username_input and username_input.visible:
		username_input.grab_focus()

func _apply_mode_layout(register_mode: bool) -> void:
	_apply_panel_frame(register_mode)
	var layout: Dictionary = LAYOUT_REGISTER if register_mode else LAYOUT_LOGIN

	_place_control(username_input, layout["username"], Vector2(250, 35))
	_place_control(username_label, layout["username_label"], Vector2(58, 36))
	_place_control(password_input, layout["password"], Vector2(250, 31))
	_place_control(password_label, layout["password_label"], Vector2(58, 39))
	_place_control(user_agree, layout["user_agree"], Vector2(310, 40))
	_place_control(switch_mode_button, layout["switch_mode"], Vector2(160, 30))

	if close_button:
		close_button.position = layout["close"]
		close_button.size = Vector2(52, 53)

	if register_mode:
		name_input.visible = true
		name_label.visible = true
		_place_control(name_input, layout["name"], Vector2(250, 31))
		_place_control(name_label, layout["name_label"], Vector2(60, 33))
		login_button.visible = false
		register_button.visible = true
		# registerButton 更宽，按素材比例放大一点
		_place_control(register_button, layout["action_button"], Vector2(180, 72))
		if switch_mode_button:
			switch_mode_button.text = "已有账号？登录"
	else:
		name_input.visible = false
		name_label.visible = false
		login_button.visible = true
		register_button.visible = false
		_place_control(login_button, layout["action_button"], Vector2(148, 58))
		if switch_mode_button:
			switch_mode_button.text = "没有账号？注册"

	_update_action_button_state(agree_checkbox.button_pressed if agree_checkbox else false)

func _apply_panel_frame(register_mode: bool) -> void:
	var panel_size: Vector2 = PANEL_REGISTER_SIZE if register_mode else PANEL_LOGIN_SIZE
	if _panel_style == null:
		_setup_panel_style()
	_panel_style.texture = TEX_REGISTER if register_mode else TEX_LOGIN
	add_theme_stylebox_override("panel", _panel_style)

	size = panel_size
	custom_minimum_size = panel_size
	_center_on_viewport()
	pivot_offset = size / 2

func _center_on_viewport() -> void:
	var vp := get_viewport_rect().size
	# 注册面板更高，略微上移避免贴底
	var y := (vp.y - size.y) * 0.5
	if is_register_mode:
		y = maxf(8.0, y - 8.0)
	position = Vector2((vp.x - size.x) * 0.5, y)

func _place_control(node: Control, pos: Vector2, size_vec: Vector2) -> void:
	if node == null:
		return
	node.position = pos
	node.size = size_vec

func _set_form_alpha(alpha: float) -> void:
	for node in _form_nodes:
		if node and node.visible:
			node.modulate.a = alpha

func _clear_form_inputs() -> void:
	if username_input:
		username_input.text = ""
	if password_input:
		password_input.text = ""
	if name_input:
		name_input.text = ""
	if agree_checkbox:
		agree_checkbox.button_pressed = false
	_update_action_button_state(false)

func _ensure_policy_popups() -> void:
	if get_node_or_null("UserAgreementPopup") == null:
		_create_policy_popup(
			"UserAgreementPopup",
			"用户协议",
			"res://text/user_agreement.txt"
		)
	if get_node_or_null("PrivacyPolicyPopup") == null:
		_create_policy_popup(
			"PrivacyPolicyPopup",
			"隐私政策",
			"res://text/privacy_policy.txt"
		)

func _create_policy_popup(node_name: String, title: String, text_path: String) -> void:
	var popup := Panel.new()
	popup.name = node_name
	popup.visible = false
	popup.z_index = 20
	popup.size = Vector2(420, 460)
	popup.position = Vector2((size.x - popup.size.x) * 0.5, (size.y - popup.size.y) * 0.5)

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.07, 0.06, 0.96)
	bg.border_color = Color(0.78, 0.62, 0.32, 1)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(8)
	bg.content_margin_left = 16
	bg.content_margin_right = 16
	bg.content_margin_top = 14
	bg.content_margin_bottom = 14
	popup.add_theme_stylebox_override("panel", bg)

	var title_label := Label.new()
	title_label.name = "TitleLabel"
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.position = Vector2(20, 12)
	title_label.size = Vector2(340, 36)
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	popup.add_child(title_label)

	var close_btn := Button.new()
	close_btn.name = "CloseButton"
	close_btn.text = "×"
	close_btn.flat = true
	close_btn.position = Vector2(372, 8)
	close_btn.size = Vector2(36, 36)
	close_btn.add_theme_font_size_override("font_size", 28)
	close_btn.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	close_btn.pressed.connect(func(): popup.visible = false)
	popup.add_child(close_btn)

	var scroll := ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.position = Vector2(18, 56)
	scroll.size = Vector2(384, 340)
	popup.add_child(scroll)

	var rich := RichTextLabel.new()
	rich.name = "RichTextLabel"
	rich.bbcode_enabled = true
	rich.fit_content = true
	rich.scroll_active = false
	rich.custom_minimum_size = Vector2(360, 0)
	rich.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rich.add_theme_font_size_override("normal_font_size", 16)
	rich.add_theme_color_override("default_color", Color(0.92, 0.9, 0.85))
	rich.text = _load_text_file(text_path)
	scroll.add_child(rich)

	var ok_btn := Button.new()
	ok_btn.name = "OkButton"
	ok_btn.text = "我知道了"
	ok_btn.position = Vector2(140, 408)
	ok_btn.size = Vector2(140, 36)
	ok_btn.pressed.connect(func(): popup.visible = false)
	popup.add_child(ok_btn)

	add_child(popup)

func _load_text_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return "暂无内容"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return "暂无内容"
	return file.get_as_text()

func show_user_agreement_popup():
	_ensure_policy_popups()
	var popup = get_node_or_null("UserAgreementPopup")
	if popup:
		_show_policy_popup(popup)

func show_privacy_policy_popup():
	_ensure_policy_popups()
	var popup = get_node_or_null("PrivacyPolicyPopup")
	if popup:
		_show_policy_popup(popup)

func _show_policy_popup(popup: Control) -> void:
	popup.size = Vector2(420, 460)
	popup.position = Vector2((size.x - popup.size.x) * 0.5, (size.y - popup.size.y) * 0.5)
	popup.visible = true
	popup.move_to_front()

func _on_agreement_label_meta_clicked(meta: Variant) -> void:
	match str(meta):
		"user":
			show_user_agreement_popup()
		"privacy":
			show_privacy_policy_popup()
