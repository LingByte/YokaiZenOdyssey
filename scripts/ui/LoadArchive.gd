extends Button

var tween: Tween

func _ready():
	# 设置 pivot 为按钮中心
	pivot_offset = size / 2

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

func _on_ReadSaveButton_pressed():
	if not Global.is_logged_in:
		get_tree().root.get_node("MainMenu").show_login_panel()
		return

	var headers = Global.auth_headers()
	var url = Global.api_url("/api/saves")
	$"../LoadArchiveRequest".request(url, headers, HTTPClient.METHOD_GET)

func _on_LoadArchiveRequest_request_completed(result, response_code, headers, body):
	if response_code != 200:
		print("请求失败，状态码:", response_code)
		return

	var json = JSON.parse_string(body.get_string_from_utf8())
	if json == null:
		print("解析 JSON 失败")
		return

	if not json.has("saves"):
		print("获取存档失败: 响应缺少 saves 字段")
		return

	var saves = json.saves
	var saves_by_slot := {}
	for save in saves:
		saves_by_slot[int(save.slot)] = save

	var panel = $"../SaveSelectPanel"
	for i in range(8):
		var slot_num = i + 1
		var button = panel.get_node("SaveSlot%d" % slot_num)

		if saves_by_slot.has(slot_num):
			var save = saves_by_slot[slot_num]
			button.get_node("NameLabel").text = "存档 %d" % slot_num
			button.get_node("JobLabel").text = save.character
			button.get_node("LoginTimeLabel").text = smart_time_display(str(save.updated_at))
			if save.character == "悟空":
				button.get_node("Avatar").texture = preload("res://assets/avatars/default_avatar01.png")
			elif save.character == "八戒":
				button.get_node("Avatar").texture = preload("res://assets/avatars/default_avatar02.png")
			button.disabled = false

			if not button.has_meta("signal_connected"):
				button.set_meta("signal_connected", true)
				var save_slot = slot_num
				var save_snapshot = save
				button.pressed.connect(func():
					Global.current_save_slot = save_slot
					Global.current_save_data = save_snapshot
					Global.selected_character = save_snapshot.character
					Global.just_entered_shenxiao = true
					Global.load_scene("res://scenes/levels/Shenxiao.tscn")
				)
		else:
			button.get_node("NameLabel").text = "空存档"
			button.get_node("JobLabel").text = ""
			button.get_node("LoginTimeLabel").text = ""
			button.get_node("Avatar").texture = null
			button.disabled = false

			if not button.has_meta("signal_connected"):
				button.set_meta("signal_connected", true)
				var empty_slot = slot_num
				button.pressed.connect(func():
					print("点击了空存档，创建新角色")
					if Global.is_logged_in:
						Global.current_save_slot = empty_slot
						Global.load_scene("res://scenes/RoleSelect.tscn")
					else:
						print("未登录，请先登录")
						get_tree().root.get_node("MainMenu").show_login_panel()
				)
	get_tree().root.get_node("MainMenu").show_archive_panel()

func smart_time_display(iso_str: String) -> String:
	if iso_str.length() < 16:
		return "未知时间"

	# 兼容 "2025-06-03 12:30:00" / "2025-06-03T12:30:00"
	var date_str = iso_str.substr(0, 19).replace("T", " ")
	var parts = date_str.split(" ")
	if parts.size() != 2:
		return "时间格式错误"

	var date_parts = parts[0].split("-")
	var time_parts = parts[1].split(":")
	if date_parts.size() != 3 or time_parts.size() < 2:
		return "时间解析失败"

	var dt = {}
	dt["year"] = int(date_parts[0])
	dt["month"] = int(date_parts[1])
	dt["day"] = int(date_parts[2])
	dt["hour"] = int(time_parts[0])
	dt["minute"] = int(time_parts[1])
	dt["second"] = 0

	var login_time = Time.get_unix_time_from_datetime_dict(dt)
	var now = Time.get_unix_time_from_system()

	var delta = now - login_time
	if delta < 60:
		return "刚刚登录"
	elif delta < 3600:
		return str(int(delta / 60)) + " 分钟前登录"
	elif delta < 86400:
		return str(int(delta / 3600)) + " 小时前登录"
	else:
		var today = Time.get_date_dict_from_system()
		var login_day = dt["day"]
		var login_month = dt["month"]
		var login_year = dt["year"]

		if today["day"] - login_day == 1 and today["month"] == login_month and today["year"] == login_year:
			return "昨天登录"
		elif today["year"] == login_year:
			return str(login_month).pad_zeros(2) + "-" + str(login_day).pad_zeros(2) + " 登录"
		else:
			return str(login_year) + "-" + str(login_month).pad_zeros(2) + "-" + str(login_day).pad_zeros(2) + " 登录"
