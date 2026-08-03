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
var _progress_http: HTTPRequest
## 关卡结算
var pending_retry_scene: String = ""
var _settle_draft: Dictionary = {}
var _settle_result: Dictionary = {}

func _ready():
	_load_env_config()
	_load_saved_data()
	_progress_http = HTTPRequest.new()
	_progress_http.name = "ProgressHTTP"
	add_child(_progress_http)

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

## ---- 角色成长进度（仅等级 / 经验，血蓝每局满值） ----

func default_player_progress() -> Dictionary:
	return {
		"player_level": 1,
		"exp": 0,
		"exp_to_next": 100,
	}

func _parse_save_data_field(raw) -> Dictionary:
	if typeof(raw) == TYPE_DICTIONARY:
		return raw
	if typeof(raw) == TYPE_STRING:
		var text := str(raw).strip_edges()
		if text.is_empty():
			return {}
		var parsed = JSON.parse_string(text)
		if typeof(parsed) == TYPE_DICTIONARY:
			return parsed
	return {}

func get_player_progress() -> Dictionary:
	var raw := _parse_save_data_field(current_save_data.get("data", {}))
	if raw.is_empty():
		return {}
	var has_progress := raw.has("player_level") or raw.has("exp")
	if not has_progress:
		return {}
	var out := default_player_progress()
	for key in out.keys():
		if raw.has(key):
			out[key] = raw[key]
	return out

func merge_progress_into_save_data(progress: Dictionary) -> String:
	var data := _parse_save_data_field(current_save_data.get("data", {}))
	# 去掉旧版血蓝字段
	for dead_key in ["max_hp", "hp", "max_mp", "mp"]:
		data.erase(dead_key)
	for key in ["player_level", "exp", "exp_to_next"]:
		if progress.has(key):
			data[key] = progress[key]
	current_save_data["data"] = data
	return JSON.stringify(data)

func save_player_progress(progress: Dictionary) -> void:
	var slim := {
		"player_level": int(progress.get("player_level", 1)),
		"exp": int(progress.get("exp", 0)),
		"exp_to_next": int(progress.get("exp_to_next", 100)),
	}
	if token.is_empty() or current_save_slot < 1:
		merge_progress_into_save_data(slim)
		return
	var data_json := merge_progress_into_save_data(slim)
	var body := JSON.stringify({
		"data": data_json,
		"level": str(current_save_data.get("level", "神霄")),
		"play_time": int(current_save_data.get("play_time", 0)),
		"character": str(current_save_data.get("character", selected_character)),
	})
	var headers := auth_headers()
	var url := api_url("/api/saves/%d" % current_save_slot)
	if _progress_http == null:
		return
	_progress_http.cancel_request()
	var err := _progress_http.request(url, headers, HTTPClient.METHOD_PUT, body)
	if err != OK:
		push_warning("[Global] 持久化进度失败: %s" % err)
	else:
		print("[Global] 进度已提交 Lv.", slim.get("player_level", 1), " EXP ", slim.get("exp", 0))

## ---- 关卡结算草稿 ----

func begin_level_run(level_name: String, retry_scene: String) -> void:
	pending_retry_scene = retry_scene
	_settle_draft = {
		"level_name": level_name,
		"retry_scene": retry_scene,
		"start_msec": Time.get_ticks_msec(),
		"enemies_killed": 0,
		"enemies_total": 0,
	}

func note_enemies_total(count: int) -> void:
	_settle_draft["enemies_total"] = count

func note_enemy_killed() -> void:
	_settle_draft["enemies_killed"] = int(_settle_draft.get("enemies_killed", 0)) + 1

func finalize_level_settle() -> void:
	var start := int(_settle_draft.get("start_msec", Time.get_ticks_msec()))
	var elapsed := maxf(0.0, float(Time.get_ticks_msec() - start) / 1000.0)
	var progress := get_player_progress()
	_settle_result = {
		"level_name": str(_settle_draft.get("level_name", "关卡")),
		"clear_time_sec": elapsed,
		"enemies_killed": int(_settle_draft.get("enemies_killed", 0)),
		"enemies_total": int(_settle_draft.get("enemies_total", 0)),
		"player_level": int(progress.get("player_level", 1)),
	}
	pending_retry_scene = str(_settle_draft.get("retry_scene", pending_retry_scene))

func consume_settle_result() -> Dictionary:
	var out := _settle_result.duplicate(true)
	_settle_result = {}
	return out
