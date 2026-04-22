# Global.gd
extends Node

var token: String = ""
var is_logged_in: bool = false
var current_character_id: int = -1
var user_info: Dictionary = {}
var current_save_slot: int = -1
var current_save_data: Dictionary = {}
var selected_character: String = ""
var just_entered_shenxiao: bool = false  # 标记是否刚进入神霄场景

func _ready():
	_load_saved_data()

func load_scene(path: String):
	var loader = preload("res://scenes/system/GlobalLoading.tscn").instantiate()
	loader.next_scene_path = path
	get_tree().root.add_child(loader)
	if get_tree().current_scene:
		get_tree().current_scene.queue_free()

func set_token(t):
	token = t
	is_logged_in = true
	_save_token_to_disk()

func set_user_info(info: Dictionary):
	user_info = info
	_save_user_info_to_disk()

func get_user_info() -> Dictionary:
	return user_info

func clear_login():
	token = ""
	is_logged_in = false
	user_info = {}
	_delete_saved_data()

func _save_token_to_disk():
	var config = ConfigFile.new()
	config.set_value("user", "token", token)
	config.save("user://user_data.cfg")

func _save_user_info_to_disk():
	var config = ConfigFile.new()
	for key in user_info:
		config.set_value("user", key, user_info[key])
	config.save("user://user_data.cfg")

func _load_saved_data():
	var config = ConfigFile.new()
	var err = config.load("user://user_data.cfg")
	if err == OK:
		token = config.get_value("user", "token", "")
		is_logged_in = not token.is_empty()
		user_info = {}
		for key in config.get_section_keys("user"):
			user_info[key] = config.get_value("user", key)

func _delete_saved_data():
	var file = FileAccess.open("user://user_data.cfg", FileAccess.WRITE)
	if file:
		file.close()
		DirAccess.remove_absolute("user://user_data.cfg")

func load_avatar_texture_to(target: TextureRect, url: String):
	var http := HTTPRequest.new()
	add_child(http)

	http.request_completed.connect(func(result, response_code, headers, body):
		if response_code != 200:
			target.texture = preload("res://assets/avatars/default_avatar_64x64.png")
			return

		var image = Image.new()
		if image.load_png_from_buffer(body) != OK:
			target.texture = preload("res://assets/avatars/default_avatar_64x64.png")
			return

		var texture = ImageTexture.create_from_image(image)
		target.texture = texture
		http.queue_free()
	)

	http.request(url)

# 全局背包管理函数
func toggle_backpack():
	var root = get_tree().root
	# 先尝试在 Shenxiao 场景中查找背包面板
	var shenxiao = root.get_node_or_null("Shenxiao")
	if shenxiao:
		var pack_panel = shenxiao.get_node_or_null("CanvasLayer/Panel")
		if pack_panel:
			# 切换显示/隐藏
			pack_panel.visible = not pack_panel.visible
			return
	
	# 如果不在 Shenxiao 场景，尝试在当前场景中查找
	var current_scene = get_tree().current_scene
	if current_scene:
		# 尝试查找背包面板（可能在 CanvasLayer/Panel 路径下）
		var pack_panel = current_scene.get_node_or_null("CanvasLayer/Panel")
		if pack_panel:
			pack_panel.visible = not pack_panel.visible
			return
	
	print("警告: 未找到背包面板")
