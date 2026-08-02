extends Button

var tween: Tween
@onready var http := $"../RegisterRequest"
@onready var uid_input := $"../UsernameInput"
@onready var pwd_input := $"../PasswordInput"
@onready var name_input := $"../NameInput"
@onready var success_dialog := $"../SuccessDialog"

func _ready():
	# 设置 pivot 为按钮中心
	pivot_offset = size / 2
	
	# 验证节点是否存在
	if not http:
		print("[RegisterButton] 警告: RegisterRequest 节点未找到")
	if not uid_input:
		print("[RegisterButton] 警告: UsernameInput 节点未找到")
	if not pwd_input:
		print("[RegisterButton] 警告: PasswordInput 节点未找到")
	if not name_input:
		print("[RegisterButton] 警告: NameInput 节点未找到")
	if not success_dialog:
		print("[RegisterButton] 警告: SuccessDialog 节点未找到")
	
	print("[RegisterButton] 初始化完成，按钮禁用状态: ", disabled)

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

# 显示错误/提示对话框（不会关闭登录面板）
func show_error_dialog(message: String):
	var dialog = get_node_or_null("../SuccessDialog")
	if not dialog:
		dialog = success_dialog

	if dialog and dialog.has_method("show_tip"):
		dialog.show_tip(message, false)
		print("[RegisterButton] 显示提示: ", message)
	elif dialog:
		dialog.dialog_text = message
		dialog.popup_centered()
	else:
		print("[RegisterButton] 错误提示: ", message)
		OS.alert(message, "提示")

func _on_pressed():
	print("[RegisterButton] ========== 按钮被点击 ==========")

	# 检查用户协议是否勾选
	var agree_checkbox = get_node_or_null("../UserAgree/AgreeCheckBox")
	if agree_checkbox == null or not agree_checkbox.button_pressed:
		show_error_dialog("请先勾选并同意《用户协议》和《隐私政策》")
		return

	# 检查输入框是否存在
	if not uid_input:
		print("[RegisterButton] 错误: UsernameInput 节点不存在")
		return
	if not pwd_input:
		print("[RegisterButton] 错误: PasswordInput 节点不存在")
		return
	if not http:
		print("[RegisterButton] 错误: RegisterRequest 节点不存在")
		return
	
	# 检查输入是否为空
	if uid_input.text.is_empty():
		print("[RegisterButton] 警告: 账号为空")
		show_error_dialog("请输入账号")
		return
	if uid_input.text.length() < 3:
		print("[RegisterButton] 警告: 账号长度至少3个字符")
		show_error_dialog("账号长度至少3个字符")
		return
	if pwd_input.text.is_empty():
		print("[RegisterButton] 警告: 密码为空")
		show_error_dialog("请输入密码")
		return
	if pwd_input.text.length() < 6:
		print("[RegisterButton] 警告: 密码长度至少6个字符")
		show_error_dialog("密码长度至少6个字符")
		return
	
	var name = uid_input.text
	if name_input and not name_input.text.is_empty():
		name = name_input.text
	
	print("[RegisterButton] 账号: ", uid_input.text)
	print("[RegisterButton] 密码长度: ", pwd_input.text.length())
	print("[RegisterButton] 昵称: ", name)
	
	var body := {
		"username": uid_input.text,
		"password": pwd_input.text,
		"nickname": name
	}
	var json = JSON.stringify(body)
	var headers = Global.auth_headers()
	var url = Global.api_url("/api/auth/register")
	
	print("[RegisterButton] 发送注册请求...")
	print("[RegisterButton] URL: ", url)
	print("[RegisterButton] 请求体: ", json)
	
	var error = http.request(url, headers, HTTPClient.METHOD_POST, json)
	if error != OK:
		print("[RegisterButton] 请求发送失败，错误码: ", error)
	else:
		print("[RegisterButton] 请求已发送，等待响应...")

func _on_request_completed(result, response_code, headers, body):
	print("[RegisterButton] 收到响应")
	print("[RegisterButton] result: ", result)
	print("[RegisterButton] response_code: ", response_code)
	
	if result != HTTPRequest.RESULT_SUCCESS:
		print("[RegisterButton] 请求失败，result: ", result)
		var error_msg = ""
		match result:
			HTTPRequest.RESULT_CANT_CONNECT:
				error_msg = "无法连接到服务器，请检查服务器是否运行在 %s" % Global.api_base
			HTTPRequest.RESULT_CANT_RESOLVE:
				error_msg = "无法解析主机名"
			HTTPRequest.RESULT_CONNECTION_ERROR:
				error_msg = "连接错误"
			HTTPRequest.RESULT_NO_RESPONSE:
				error_msg = "无响应"
			_:
				error_msg = "未知错误 (错误码: %d)" % result
		show_error_dialog(error_msg)
		return
	
	if response_code != 200 and response_code != 201:
		print("[RegisterButton] HTTP 状态码错误: ", response_code)
		var error_msg = "注册失败"
		if body and body.size() > 0:
			var body_text = body.get_string_from_utf8()
			print("[RegisterButton] 响应体: ", body_text)
			
			var response = JSON.parse_string(body_text)
			if response and response.has("error"):
				error_msg = response["error"]
			elif response_code == 409:
				error_msg = "用户名已存在"
			elif response_code == 400:
				error_msg = "请求参数错误"
			elif response_code == 500:
				error_msg = "服务器错误，请稍后重试"
		show_error_dialog(error_msg)
		return

	var body_text = body.get_string_from_utf8()
	print("[RegisterButton] 响应体内容: ", body_text)
	
	var response = JSON.parse_string(body_text)
	if response == null:
		print("[RegisterButton] 解析 JSON 失败")
		show_error_dialog("服务器响应格式错误")
		return

	print("[RegisterButton] 解析后的响应: ", response)
	print("[RegisterButton] 注册成功，请登录")

	var dialog = get_node_or_null("../SuccessDialog")
	if not dialog:
		dialog = success_dialog
	var msg := "注册成功！请登录"
	if response is Dictionary:
		msg = str(response.get("message", msg))
	if dialog and dialog.has_method("show_tip"):
		dialog.show_tip(msg, false)
	elif dialog:
		dialog.dialog_text = msg
		dialog.popup_centered()

	# 注册成功后切回登录表单，方便直接登录
	var panel = get_parent()
	if panel and panel.has_method("_rerender_form") and panel.get("is_register_mode"):
		await panel._rerender_form(false)

