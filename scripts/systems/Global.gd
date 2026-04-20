# Global.gd
extends Node

var token: String = ""
var is_logged_in: bool = false
var current_character_id: int = -1

func load_scene(path: String):
	var loader = preload("res://scenes/system/GlobalLoading.tscn").instantiate()
	loader.next_scene_path = path
	get_tree().root.add_child(loader)
	if get_tree().current_scene:
		get_tree().current_scene.queue_free()

func set_token(t):
	token = t
	is_logged_in = true

func clear_login():
	token = ""
	is_logged_in = false

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
