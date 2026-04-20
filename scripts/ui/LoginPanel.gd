extends Panel

var is_register_mode: bool = false

@onready var agree_checkbox = $UserAgree/AgreeCheckBox
@onready var login_button = $LoginButton
@onready var register_button = $RegisterButton
@onready var switch_mode_button = $SwitchModeButton
@onready var agreement_label = $UserAgree/AgreementLabel
@onready var color_react = $"../InputBlocker"
@onready var name_input = $NameInput
@onready var name_label = $NameLabel

func _ready():
	color_react.color = Color(0, 0, 0, 0.5)
	color_react.mouse_filter = MOUSE_FILTER_STOP
	agreement_label.bbcode_enabled = true
	agreement_label.text = "我已阅读并同意 [url=user]《用户协议》[/url] 和 [url=privacy]《隐私政策》[/url]"
	login_button.disabled = true
	if register_button:
		register_button.disabled = true
	
	# 初始为登录模式
	switch_to_login_mode()
	
	# 检查信号是否已连接，避免重复连接
	if not agree_checkbox.toggled.is_connected(_on_agree_checkbox_toggled):
		agree_checkbox.connect("toggled", _on_agree_checkbox_toggled)
	if not agreement_label.meta_clicked.is_connected(_on_agreement_label_meta_clicked):
		agreement_label.connect("meta_clicked", _on_agreement_label_meta_clicked)
	if switch_mode_button and not switch_mode_button.pressed.is_connected(_on_switch_mode_pressed):
		switch_mode_button.connect("pressed", _on_switch_mode_pressed)

func _on_agree_checkbox_toggled(pressed: bool):
	login_button.disabled = !pressed
	if register_button:
		register_button.disabled = !pressed

func _on_switch_mode_pressed():
	is_register_mode = !is_register_mode
	if is_register_mode:
		switch_to_register_mode()
	else:
		switch_to_login_mode()

func switch_to_login_mode():
	is_register_mode = false
	if switch_mode_button:
		switch_mode_button.text = "没有账号？注册"
	if login_button:
		login_button.visible = true
	if register_button:
		register_button.visible = false
	if name_input:
		name_input.visible = false
	if name_label:
		name_label.visible = false

func switch_to_register_mode():
	is_register_mode = true
	if switch_mode_button:
		switch_mode_button.text = "已有账号？登录"
	if login_button:
		login_button.visible = false
	if register_button:
		register_button.visible = true
	if name_input:
		name_input.visible = true
	if name_label:
		name_label.visible = true

func show_user_agreement_popup():
	print("触发user")
	var popup = get_node_or_null("UserAgreementPopup")
	if popup:
		popup.visible = true
	else:
		print("警告: UserAgreementPopup 节点不存在")

func show_privacy_policy_popup():
	print("触发privacy")
	var popup = get_node_or_null("PrivacyPolicyPopup")
	if popup:
		popup.visible = true
	else:
		print("警告: PrivacyPolicyPopup 节点不存在")

func _on_PrivacyPolicy_CloseButton_pressed():
	var popup = get_node_or_null("PrivacyPolicyPopup")
	if popup:
		popup.visible = false

func _on_UserAgreement_CloseButton_pressed() -> void:
	var popup = get_node_or_null("UserAgreementPopup")
	if popup:
		var content_file = load("res://text/user_agreement.txt")
		if content_file:
			var content = content_file.get_as_text()
			var label = popup.get_node_or_null("ScrollContainer/RichTextLabel")
			if label:
				label.text = content
		popup.visible = false


func _on_agreement_label_meta_clicked(meta: Variant) -> void:
	match meta:
		"user":
			show_user_agreement_popup()  # 弹窗或跳转协议页面
		"privacy":
			show_privacy_policy_popup()
