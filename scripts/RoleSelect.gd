extends Control

@onready var soul_button = $SoulButton
@onready var bajie_button = $BajieButton
@onready var soul_idle = $SoulIdle
@onready var bajie_idle = $BajieIdle
@onready var confirm_button = $ConfirmButton
@onready var return_button = $ReturnButton
@onready var selected_character_label = $SelectedCharacterLabel
@onready var http_request = $HTTPRequest

var selected_character: String = ""

func _ready():
	soul_button.pressed.connect(_on_soul_selected)
	bajie_button.pressed.connect(_on_bajie_selected)
	soul_idle.pressed.connect(_on_soul_selected)
	bajie_idle.pressed.connect(_on_bajie_selected)
	confirm_button.pressed.connect(_on_confirm_selected)
	return_button.pressed.connect(_on_return_pressed)
	return_button.mouse_entered.connect(_on_return_mouse_entered)
	return_button.mouse_exited.connect(_on_return_mouse_exited)
	
	if http_request:
		http_request.request_completed.connect(_on_request_completed)
	
	# 初始设置为灰色
	soul_idle.modulate = Color(0.5, 0.5, 0.5, 1)
	bajie_idle.modulate = Color(0.5, 0.5, 0.5, 1)
	
	selected_character_label.text = "请选择角色"

func _on_soul_selected():
	selected_character = "悟空"
	selected_character_label.text = "已选择: 悟空"
	soul_idle.modulate = Color.WHITE
	bajie_idle.modulate = Color(0.5, 0.5, 0.5, 1)
	_play_scale_animation(soul_idle)

func _on_bajie_selected():
	selected_character = "八戒"
	selected_character_label.text = "已选择: 八戒"
	bajie_idle.modulate = Color.WHITE
	soul_idle.modulate = Color(0.5, 0.5, 0.5, 1)
	_play_scale_animation(bajie_idle)

func _play_scale_animation(node: TextureButton):
	var tween = create_tween()
	tween.tween_property(node, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(node, "scale", Vector2(1.0, 1.0), 0.1)

func _on_confirm_selected():
	if selected_character.is_empty():
		return
	
	if Global.current_save_slot == -1:
		print("[RoleSelect] 错误：未选择存档槽位")
		return
	
	# 创建存档请求
	var progress = Global.default_player_progress()
	var body = {
		"slot": Global.current_save_slot,
		"character": selected_character,
		"data": JSON.stringify(progress),
		"level": "神霄",
		"play_time": 0
	}
	var json = JSON.stringify(body)
	var headers = Global.auth_headers()
	var url = Global.api_url("/api/saves")
	
	print("[RoleSelect] 创建存档请求: ", json)
	
	if http_request:
		var error = http_request.request(url, headers, HTTPClient.METHOD_POST, json)
		if error != OK:
			print("[RoleSelect] 请求发送失败: ", error)

func _on_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		print("[RoleSelect] 请求失败，result: ", result)
		return
	
	if response_code != 200 and response_code != 201:
		print("[RoleSelect] HTTP 状态码错误: ", response_code)
		var body_text = body.get_string_from_utf8()
		print("[RoleSelect] 响应体: ", body_text)
		return
	
	var body_text = body.get_string_from_utf8()
	print("[RoleSelect] 响应体: ", body_text)
	
	var response = JSON.parse_string(body_text)
	if response == null:
		print("[RoleSelect] 解析 JSON 失败")
		return
	
	print("[RoleSelect] 存档创建成功")
	
	# 保存角色选择到全局变量
	Global.selected_character = selected_character
	if typeof(response) == TYPE_DICTIONARY and response.has("save"):
		Global.current_save_data = response["save"]
	else:
		Global.current_save_data = {
			"slot": Global.current_save_slot,
			"character": selected_character,
			"data": JSON.stringify(Global.default_player_progress()),
			"level": "神霄",
			"play_time": 0,
		}
	
	# 设置刚进入神霄场景的标志
	Global.just_entered_shenxiao = true
	
	# 进入神霄关卡
	Global.load_scene("res://scenes/levels/Shenxiao.tscn")

func _on_return_pressed():
	# 点击旋转效果
	var tween = create_tween()
	tween.tween_property(return_button, "rotation_degrees", 15, 0.1)
	tween.tween_property(return_button, "rotation_degrees", 0, 0.1)
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_return_mouse_entered():
	# hover 放大效果
	var tween = create_tween()
	tween.tween_property(return_button, "scale", Vector2(1.1, 1.1), 0.15)

func _on_return_mouse_exited():
	# 鼠标移出恢复
	var tween = create_tween()
	tween.tween_property(return_button, "scale", Vector2(1.0, 1.0), 0.15)
