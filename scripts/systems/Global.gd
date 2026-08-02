# Global.gd
extends Node

## 默认 API 地址；可被 res://.env / user://.env 中的 API_BASE 覆盖
var api_base: String = "http://localhost:8080"

var token: String = ""
var is_logged_in: bool = false
var current_character_id: int = -1
var user_info: Dictionary = {}
var current_save_slot: int = -1
var current_save_data: Dictionary = {}
var selected_character: String = ""
var just_entered_shenxiao: bool = false  # 标记是否刚进入神霄场景

func _ready():
	_load_env_config()
	_load_saved_data()

func _load_env_config() -> void:
	# 优先项目根 .env；若编辑器对点文件受限，可用 config.env
	var env := EnvLoader.load_files(PackedStringArray([
		"res://.env",
		"res://.env.local",
		"res://config.env",
		"user://.env",
	]))
	var base := str(env.get("API_BASE", env.get("API_URL", api_base))).strip_edges()
	if base.ends_with("/"):
		base = base.left(base.length() - 1)
	if not base.is_empty():
		api_base = base
	print("[Global] API_BASE = ", api_base)

func api_url(path: String) -> String:
	if path.begins_with("/"):
		return api_base + path
	return api_base + "/" + path

func auth_headers(extra: Array = []) -> PackedStringArray:
	var headers: PackedStringArray = ["Content-Type: application/json"]
	if not token.is_empty():
		headers.append("Authorization: Bearer %s" % token)
	for h in extra:
		headers.append(h)
	return headers

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

func apply_character_avatar(target: TextureRect, character: String = "") -> void:
	if target == null or not is_instance_valid(target):
		return
	var char_name := character if not character.is_empty() else selected_character
	if char_name == "八戒":
		target.texture = preload("res://assets/avatars/default_avatar02.png")
	else:
		target.texture = preload("res://assets/avatars/default_avatar01.png")

func load_avatar_texture_to(target: TextureRect, url: String):
	if target == null or not is_instance_valid(target):
		return

	# 无 URL 时直接用本地角色头像，避免无效请求
	if url.is_empty():
		apply_character_avatar(target)
		return

	var http := HTTPRequest.new()
	add_child(http)
	var target_ref: WeakRef = weakref(target)

	http.request_completed.connect(func(_result, response_code, _headers, body):
		# HTTPRequest 用完即销毁，避免泄漏
		if is_instance_valid(http):
			http.queue_free()

		var node = target_ref.get_ref()
		if node == null or not is_instance_valid(node):
			# 场景已切换，目标 TextureRect 已释放
			return

		if response_code != 200:
			apply_character_avatar(node)
			return

		var image = Image.new()
		if image.load_png_from_buffer(body) != OK:
			# 也可能是 jpg/webp，回退本地头像
			apply_character_avatar(node)
			return

		node.texture = ImageTexture.create_from_image(image)
	)

	var err := http.request(url)
	if err != OK:
		apply_character_avatar(target)
		if is_instance_valid(http):
			http.queue_free()

# 全局背包管理函数
func toggle_backpack():
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.has_method("toggle_backpack"):
		current_scene.toggle_backpack()
		return

	var pack_panel = null
	var shenxiao = get_tree().root.get_node_or_null("Shenxiao")
	if shenxiao:
		pack_panel = shenxiao.get_node_or_null("CanvasLayer/Panel")
	if pack_panel == null and current_scene:
		pack_panel = current_scene.get_node_or_null("CanvasLayer/Panel")
	if pack_panel == null:
		print("警告: 未找到背包面板")
		return

	pack_panel.visible = not pack_panel.visible
	if pack_panel.visible and pack_panel.has_method("refresh_if_needed"):
		pack_panel.refresh_if_needed()
