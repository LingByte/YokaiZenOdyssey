extends Node2D

@onready var heartbeat_timer = $HeartbeatTimer
@onready var heartbeat_request = $HeartbeatRequest
@onready var userAvatar = $Panel/TextureRect
@onready var packPanel = $CanvasLayer/Panel

func _ready() -> void:
	packPanel.visible = false
	
	var id = Global.current_character_id
	if id != -1:
		print("当前选中角色 ID：", id)
		# load_character_data(id)

	# 先立刻显示本地头像，再异步拉远程（回调内会校验节点是否仍有效）
	Global.apply_character_avatar(userAvatar)
	var remote_avatar := ""
	if Global.user_info.has("avatar"):
		remote_avatar = str(Global.user_info["avatar"])
	if not remote_avatar.is_empty():
		Global.load_avatar_texture_to(userAvatar, remote_avatar)

	# 连接计时器超时信号
	if heartbeat_timer and not heartbeat_timer.timeout.is_connected(send_heartbeat):
		heartbeat_timer.timeout.connect(send_heartbeat)

func _process(delta: float) -> void:
	# 监听 C 键打开/关闭背包
	if Input.is_action_just_pressed("open_backpack"):
		toggle_backpack()

func toggle_backpack():
	packPanel.visible = not packPanel.visible
	if packPanel.visible and packPanel.has_method("refresh_if_needed"):
		packPanel.refresh_if_needed()

func send_heartbeat():
	if Global.token.is_empty():
		return
	var headers = Global.auth_headers()
	var url = Global.api_url("/api/users/ping")
	heartbeat_request.request(url, headers, HTTPClient.METHOD_POST)

func show_pack_panel():
	packPanel.visible = true
	if packPanel.has_method("refresh_if_needed"):
		packPanel.refresh_if_needed()

func hide_pack_panel():
	packPanel.visible = false
