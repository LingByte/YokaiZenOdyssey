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
	Global.load_avatar_texture_to(userAvatar, 'https://cetide-1325039295.cos.ap-chengdu.myqcloud.com/west/default_avatar01.png')

	# 连接计时器超时信号
	heartbeat_timer.timeout.connect(send_heartbeat)

func _process(delta: float) -> void:
	# 监听 C 键打开/关闭背包
	if Input.is_action_just_pressed("open_backpack"):
		toggle_backpack()

func toggle_backpack():
	packPanel.visible = not packPanel.visible

func send_heartbeat():
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer %s" % Global.token
	]
	var url = "http://localhost:7070/api/v1/users/ping"
	heartbeat_request.request(url, headers, HTTPClient.METHOD_POST)

func show_pack_panel():
	packPanel.visible = true

func hide_pack_panel():
	packPanel.visible = false
