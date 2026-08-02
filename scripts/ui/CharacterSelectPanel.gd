extends Panel

@onready var character_name_input = $VBoxContainer/CharacterInfo/NameInput
@onready var job_option = $VBoxContainer/CharacterInfo/JobOption
@onready var create_button = $VBoxContainer/CreateButton
@onready var cancel_button = $VBoxContainer/CancelButton
@onready var close_button = $CloseButton
@onready var create_request = $CreateRequest

var tween: Tween

# 角色职业选项（需与后端 CreateSaveRequest 一致）
const JOBS = [
	{"name": "悟空", "value": "悟空"},
	{"name": "八戒", "value": "八戒"},
]

func _ready():
	# 设置关闭按钮
	if close_button:
		close_button.pivot_offset = close_button.size / 2
		if not close_button.pressed.is_connected(_on_close_button_pressed):
			close_button.pressed.connect(_on_close_button_pressed)
		if not close_button.mouse_entered.is_connected(_on_close_button_mouse_entered):
			close_button.mouse_entered.connect(_on_close_button_mouse_entered)
		if not close_button.mouse_exited.is_connected(_on_close_button_mouse_exited):
			close_button.mouse_exited.connect(_on_close_button_mouse_exited)
	
	# 填充职业选项
	if job_option:
		for job in JOBS:
			job_option.add_item(job.name)
		job_option.selected = 0
	
	# 连接按钮信号
	if create_button:
		if not create_button.pressed.is_connected(_on_create_button_pressed):
			create_button.pressed.connect(_on_create_button_pressed)
	if cancel_button:
		if not cancel_button.pressed.is_connected(_on_cancel_button_pressed):
			cancel_button.pressed.connect(_on_cancel_button_pressed)
	
	# 设置默认角色名
	if character_name_input:
		character_name_input.placeholder_text = "请输入角色名称"

func _on_create_button_pressed():
	if not Global.is_logged_in:
		print("未登录，请先登录")
		get_tree().root.get_node("MainMenu").show_login_panel()
		hide_panel()
		return
	
	# 验证输入
	var name = character_name_input.text.strip_edges()
	if name.is_empty():
		print("请输入角色名称")
		# 这里可以显示错误提示
		return
	
	if job_option.selected < 0 or job_option.selected >= JOBS.size():
		print("请选择职业")
		return
	
	var job = JOBS[job_option.selected].value
	
	# 创建存档
	create_archive(name, job)

func create_archive(name: String, job: String):
	if Global.current_save_slot < 1:
		print("未选择存档槽位")
		return

	var headers = Global.auth_headers()
	var body = JSON.stringify({
		"slot": Global.current_save_slot,
		"character": job,
		"data": JSON.stringify({"name": name}),
		"level": "神霄",
		"play_time": 0
	})

	var url = Global.api_url("/api/saves")
	create_request.request(url, headers, HTTPClient.METHOD_POST, body)

func _on_create_request_request_completed(result, response_code, headers, body):
	if response_code != 200 and response_code != 201:
		print("创建存档失败，状态码:", response_code)
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json.has("error"):
			print("错误信息:", json.error)
		return

	var json = JSON.parse_string(body.get_string_from_utf8())
	if json == null:
		print("解析 JSON 失败")
		return

	if not json.has("save"):
		print("创建存档失败: 响应缺少 save 字段")
		return

	var save = json.save
	Global.current_character_id = int(save.id)
	Global.selected_character = save.character
	Global.just_entered_shenxiao = true
	print("存档创建成功，ID:", save.id)

	hide_panel()
	Global.load_scene("res://scenes/levels/Shenxiao.tscn")

func _on_cancel_button_pressed():
	hide_panel()

func _on_close_button_pressed():
	hide_panel()

func hide_panel():
	var main_menu = get_tree().root.get_node_or_null("MainMenu")
	if main_menu:
		main_menu.hide_character_select_panel()
	else:
		visible = false

func _on_close_button_mouse_entered():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(close_button, "scale", Vector2(1.1, 1.1), 0.15)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

func _on_close_button_mouse_exited():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(close_button, "scale", Vector2(1, 1), 0.15)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

