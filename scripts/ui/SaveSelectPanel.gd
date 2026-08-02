extends Panel

var save_slots = []
var save_data = {}  # 存储从后端获取的存档数据
var is_new_game_mode: bool = false  # 是否为新游戏模式

@onready var close_button = $CloseButton
@onready var http_request = $HTTPRequest

func _ready():
	# 获取所有存档槽位
	for i in range(1, 9):
		var slot = get_node_or_null("SaveSlot%d" % i)
		if slot:
			save_slots.append(slot)
			slot.pressed.connect(_on_save_slot_pressed.bind(i))
	
	# 连接关闭按钮
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	# 连接 HTTP 请求
	if http_request:
		http_request.request_completed.connect(_on_request_completed)
	
	# 初始化时隐藏所有存档信息
	_reset_save_slots()

func show_panel(new_game: bool = false):
	is_new_game_mode = new_game
	visible = true
	
	# 从后端获取存档数据
	_fetch_save_games()

func _reset_save_slots():
	for slot in save_slots:
		var name_label = slot.get_node_or_null("NameLabel")
		var job_label = slot.get_node_or_null("JobLabel")
		var time_label = slot.get_node_or_null("LoginTimeLabel")
		var avatar = slot.get_node_or_null("Avatar")
		
		if name_label:
			name_label.text = "空存档"
		if job_label:
			job_label.text = ""
		if time_label:
			time_label.text = ""
		if avatar:
			avatar.texture = null

func _fetch_save_games():
	if not Global.token:
		print("[SaveSelectPanel] 未登录，无法获取存档")
		return
	
	var headers = Global.auth_headers()
	var url = Global.api_url("/api/saves")
	
	print("[SaveSelectPanel] 获取存档数据...")
	var error = http_request.request(url, headers, HTTPClient.METHOD_GET)
	if error != OK:
		print("[SaveSelectPanel] 请求失败: ", error)

func _on_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		print("[SaveSelectPanel] 请求失败，result: ", result)
		return
	
	if response_code != 200:
		print("[SaveSelectPanel] HTTP 状态码错误: ", response_code)
		var body_text = body.get_string_from_utf8()
		print("[SaveSelectPanel] 响应体: ", body_text)
		return
	
	var body_text = body.get_string_from_utf8()
	print("[SaveSelectPanel] 响应体: ", body_text)
	
	var response = JSON.parse_string(body_text)
	if response == null:
		print("[SaveSelectPanel] 解析 JSON 失败")
		return
	
	# 更新存档数据
	if response.has("saves"):
		_update_save_slots(response["saves"])

func _update_save_slots(saves):
	save_data = {}
	
	# 先重置所有槽位
	_reset_save_slots()
	
	# 更新有数据的槽位
	for save in saves:
		var slot = int(save.slot)
		save_data[slot] = save
		
		# 找到对应的槽位按钮
		var slot_index = slot - 1
		if slot_index >= 0 and slot_index < save_slots.size():
			var slot_button = save_slots[slot_index]
			var name_label = slot_button.get_node_or_null("NameLabel")
			var job_label = slot_button.get_node_or_null("JobLabel")
			var time_label = slot_button.get_node_or_null("LoginTimeLabel")
			var avatar = slot_button.get_node_or_null("Avatar")
			
			if name_label:
				name_label.text = "存档 " + str(slot)
			if job_label:
				job_label.text = save.character
			if time_label:
				var datetime = save.updated_at
				if datetime:
					time_label.text = datetime.substr(5, 11)  # 只显示日期时间部分
			if avatar:
				# 根据角色显示不同的头像
				if save.character == "悟空":
					avatar.texture = preload("res://assets/avatars/default_avatar01.png")
				elif save.character == "八戒":
					avatar.texture = preload("res://assets/avatars/default_avatar02.png")

func _on_save_slot_pressed(slot: int):
	print("[SaveSelectPanel] 点击存档槽位: ", slot)
	
	if is_new_game_mode:
		# 新游戏模式：检查槽位是否为空
		if save_data.has(slot):
			# 槽位已有数据，询问是否覆盖
			_show_confirm_dialog(slot)
		else:
			# 槽位为空，直接进入角色选择
			_goto_character_selection(slot)
	else:
		# 读取存档模式：检查槽位是否有数据
		if save_data.has(slot):
			# 槽位有数据，加载游戏
			_load_game(slot)
		else:
			# 槽位为空，提示用户
			_show_empty_slot_dialog()

func _goto_character_selection(slot: int):
	print("[SaveSelectPanel] 进入角色选择，槽位: ", slot)
	# 保存当前选择的槽位到全局变量
	Global.current_save_slot = slot
	
	# 隐藏存档面板
	visible = false
	get_parent().get_node("InputBlocker").visible = false
	
	# 显示角色选择页面
	Global.load_scene("res://scenes/RoleSelect.tscn")

func _load_game(slot: int):
	print("[SaveSelectPanel] 加载游戏，槽位: ", slot)
	var save = save_data[slot]
	
	# 保存存档数据到全局变量
	Global.current_save_slot = slot
	Global.current_save_data = save
	Global.selected_character = save.character
	
	# 根据存档数据加载对应的关卡
	print("[SaveSelectPanel] 存档数据: ", save)
	print("[SaveSelectPanel] 关卡: ", save.level)
	
	# 隐藏存档面板
	visible = false
	get_parent().get_node("InputBlocker").visible = false
	
	# 设置刚进入神霄场景的标志
	Global.just_entered_shenxiao = true
	
	# 跳转到对应的关卡
	if save.level and save.level != "":
		# 根据关卡名称跳转
		if "Shenxiao" in save.level or "神霄" in save.level:
			Global.load_scene("res://scenes/levels/Shenxiao.tscn")
		else:
			Global.load_scene("res://scenes/levels/Yuntailingzhen.tscn")
	else:
		# 默认跳转到神霄
		Global.load_scene("res://scenes/levels/Shenxiao.tscn")

func _show_confirm_dialog(slot: int):
	# TODO: 显示确认对话框
	print("[SaveSelectPanel] 槽位 ", slot, " 已有数据，是否覆盖？")
	# 暂时直接覆盖
	_goto_character_selection(slot)

func _show_empty_slot_dialog():
	# TODO: 显示空槽位提示对话框
	print("[SaveSelectPanel] 该槽位为空")

func _on_close_pressed():
	visible = false
	get_parent().get_node("InputBlocker").visible = false
