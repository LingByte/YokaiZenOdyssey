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

	# 已登录，发起后端请求获取存档列表
	var headers = ["Content-Type: application/json", "Authorization: Bearer %s" % Global.token]
	var url = "http://localhost:7070/api/v1/users/archive"
	$"../LoadArchiveRequest".request(url, headers, HTTPClient.METHOD_GET)

func _on_LoadArchiveRequest_request_completed(result, response_code, headers, body):
	if response_code != 200:
		print("请求失败，状态码:", response_code)
		return

	var json = JSON.parse_string(body.get_string_from_utf8())
	if json == null:
		print("解析 JSON 失败")
		return

	if json.code != 200:
		print("获取存档失败:", json.msg)
		return

	var archives = json.data.archives
	if archives.is_empty():
		print("当前没有任何存档")
	var panel = $"../SaveSelectPanel"
	for i in range(8):
		var button = panel.get_node("SaveSlot%d" % (i + 1))
		
		if i < archives.size():
			var archive = archives[i]
			button.get_node("NameLabel").text = archive.name
			button.get_node("JobLabel").text = archive.job
			button.get_node("LoginTimeLabel").text = smart_time_display(archive.last_login_time)
			Global.load_avatar_texture_to(button.get_node("Avatar"), archive.avatar)
			button.disabled = false

			# 仅在没有连接的情况下绑定
			if not button.has_meta("signal_connected"):
				# 使用 lambda 绑定函数，将 archive.id 捕获
				var archive_id = archive.id
				button.pressed.connect(func():
					Global.current_character_id = archive_id
					Global.load_scene("res://scenes/levels/Shenxiao.tscn")  # 或你目标场景路径
				)
		else:
			button.get_node("NameLabel").text = "空存档"
			button.get_node("JobLabel").text = ""
			button.get_node("LoginTimeLabel").text = ""
			button.get_node("Avatar").texture = null
			button.disabled = false  # 允许点击空存档
			
			# 为空存档绑定点击事件（创建新存档）
			if not button.has_meta("signal_connected"):
				button.set_meta("signal_connected", true)
				button.pressed.connect(func():
					print("点击了空存档，创建新角色")
					# 这里可以打开创建角色界面，或者直接创建默认角色
					# 暂时先进入游戏场景
					if Global.is_logged_in:
						Global.load_scene("res://scenes/levels/Shenxiao.tscn")
					else:
						print("未登录，请先登录")
						get_tree().root.get_node("MainMenu").show_login_panel()
				)
	get_tree().root.get_node("MainMenu").show_archive_panel()

func smart_time_display(iso_str: String) -> String:
	if iso_str.length() < 19:
		return "未知时间"

	# 截取 ISO 时间前部分（去除时区偏移）
	var date_str = iso_str.substr(0, 19)  # "2025-06-03T12:30:00"
	date_str = date_str.replace("T", " ") # "2025-06-03 12:30:00"

	# 拆分为日期和时间
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
