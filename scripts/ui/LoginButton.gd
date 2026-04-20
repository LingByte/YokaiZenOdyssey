extends Button

var tween: Tween
@onready var http := $"../LoginRequest"
@onready var uid_input := $"../UsernameInput"
@onready var pwd_input := $"../PasswordInput"
@onready var success_dialog := $"../SuccessDialog"

func _ready():
	# 设置 pivot 为按钮中心
	pivot_offset = size / 2
	
	# 验证节点是否存在
	if not http:
		print("[LoginButton] 警告: LoginRequest 节点未找到")
	if not uid_input:
		print("[LoginButton] 警告: UsernameInput 节点未找到")
	if not pwd_input:
		print("[LoginButton] 警告: PasswordInput 节点未找到")
	if not success_dialog:
		print("[LoginButton] 警告: SuccessDialog 节点未找到")
	
	print("[LoginButton] 初始化完成，按钮禁用状态: ", disabled)

# 显示错误对话框
func show_error_dialog(message: String):
	# 确保对话框节点存在
	var dialog = get_node_or_null("../SuccessDialog")
	if not dialog:
		dialog = success_dialog
	
	if dialog:
		dialog.dialog_text = message
		dialog.popup_centered()
		print("[LoginButton] 显示错误对话框: ", message)
	else:
		# 如果对话框不存在，使用 print 作为后备
		print("[LoginButton] 错误提示: ", message)
		# 尝试使用 OS.alert 作为后备
		OS.alert(message, "提示")

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
	print("[LoginButton] ========== 按钮被点击 ==========")
	print("[LoginButton] 按钮禁用状态: ", disabled)
	
	# 检查用户协议是否勾选
	var agree_checkbox = get_node_or_null("../UserAgree/AgreeCheckBox")
	if agree_checkbox and not agree_checkbox.button_pressed:
		print("[LoginButton] 警告: 请先勾选用户协议")
		# 显示提示对话框
		show_error_dialog("请先勾选用户协议")
		return
	
	# 如果按钮被禁用，不应该执行
	if disabled:
		print("[LoginButton] 警告: 按钮被禁用")
		show_error_dialog("请先勾选用户协议")
		return
	
	# 检查输入框是否存在
	if not uid_input:
		print("[LoginButton] 错误: UsernameInput 节点不存在")
		return
	if not pwd_input:
		print("[LoginButton] 错误: PasswordInput 节点不存在")
		return
	if not http:
		print("[LoginButton] 错误: LoginRequest 节点不存在")
		return
	
	# 检查输入是否为空
	if uid_input.text.is_empty():
		print("[LoginButton] 警告: 账号为空")
		show_error_dialog("请输入账号")
		return
	if pwd_input.text.is_empty():
		print("[LoginButton] 警告: 密码为空")
		show_error_dialog("请输入密码")
		return
	
	print("[LoginButton] 账号: ", uid_input.text)
	print("[LoginButton] 密码长度: ", pwd_input.text.length())
	
	var body := {
		"uid": uid_input.text,
		"pwd": pwd_input.text
	}
	var json = JSON.stringify(body)
	var headers = ["Content-Type: application/json"]
	var url = "http://localhost:7070/api/v1/users/login"
	
	print("[LoginButton] 发送登录请求...")
	print("[LoginButton] URL: ", url)
	print("[LoginButton] 请求体: ", json)
	
	var error = http.request(url, headers, HTTPClient.METHOD_POST, json)
	if error != OK:
		print("[LoginButton] 请求发送失败，错误码: ", error)
	else:
		print("[LoginButton] 请求已发送，等待响应...")

func _on_request_completed(result, response_code, headers, body):
	print("[LoginButton] 收到响应")
	print("[LoginButton] result: ", result)
	print("[LoginButton] response_code: ", response_code)
	print("[LoginButton] headers: ", headers)
	
	if result != HTTPRequest.RESULT_SUCCESS:
		print("[LoginButton] 请求失败，result: ", result)
		var error_msg = ""
		match result:
			HTTPRequest.RESULT_CHUNKED_BODY_SIZE_MISMATCH:
				error_msg = "分块响应体大小不匹配"
			HTTPRequest.RESULT_CANT_CONNECT:
				error_msg = "无法连接到服务器，请检查服务器是否运行在 http://localhost:7070"
			HTTPRequest.RESULT_CANT_RESOLVE:
				error_msg = "无法解析主机名"
			HTTPRequest.RESULT_CONNECTION_ERROR:
				error_msg = "连接错误"
			HTTPRequest.RESULT_NO_RESPONSE:
				error_msg = "无响应"
			HTTPRequest.RESULT_BODY_SIZE_LIMIT_EXCEEDED:
				error_msg = "响应体大小超限"
			HTTPRequest.RESULT_BODY_DECOMPRESS_FAILED:
				error_msg = "响应体解压失败"
			HTTPRequest.RESULT_REQUEST_FAILED:
				error_msg = "请求失败"
			HTTPRequest.RESULT_DOWNLOAD_FILE_CANT_OPEN:
				error_msg = "无法打开下载文件"
			HTTPRequest.RESULT_DOWNLOAD_FILE_WRITE_ERROR:
				error_msg = "下载文件写入错误"
			HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED:
				error_msg = "重定向次数超限"
			_:
				error_msg = "未知错误 (错误码: %d)" % result
		
		# 检查是否有 TLS/SSL 相关错误（Godot 4.5 使用 RESULT_TLS_HANDSHAKE_ERROR）
		if result == 5:  # TLS_HANDSHAKE_ERROR 的值
			error_msg = "TLS握手失败"
		
		print("[LoginButton] 错误: ", error_msg)
		show_error_dialog(error_msg)
		return
	
	if response_code != 200:
		print("[LoginButton] HTTP 状态码错误: ", response_code)
		var error_msg = "登录失败"
		if body and body.size() > 0:
			var body_text = body.get_string_from_utf8()
			print("[LoginButton] 响应体: ", body_text)
			
			# 尝试解析错误消息
			var response = JSON.parse_string(body_text)
			if response and response.has("msg"):
				error_msg = response["msg"]
			elif response_code == 401:
				error_msg = "账号或密码错误"
			elif response_code == 500:
				error_msg = "服务器错误，请稍后重试"
		
		show_error_dialog(error_msg)
		return

	var body_text = body.get_string_from_utf8()
	print("[LoginButton] 响应体内容: ", body_text)
	
	var response = JSON.parse_string(body_text)
	if response == null:
		print("[LoginButton] 解析 JSON 失败")
		show_error_dialog("服务器响应格式错误")
		return

	print("[LoginButton] 解析后的响应: ", response)

	if response.has("code") and response["code"] == 200:
		if response.has("data") and response["data"].has("token"):
			var token = response["data"]["token"]
			Global.set_token(token)
			print("[LoginButton] 登录成功，token: ", token)
			
			# 弹出成功提示
			if success_dialog:
				success_dialog.dialog_text = "登录成功！"
				success_dialog.popup_centered()
		else:
			print("[LoginButton] 响应格式错误，缺少 token")
			show_error_dialog("登录响应格式错误")
	else:
		var msg = response.get("msg", "未知错误")
		print("[LoginButton] 登录失败，原因: ", msg)
		show_error_dialog(msg)
