extends Panel

@onready var master_volume_slider = $VBoxContainer/AudioSettings/MasterVolumeSlider
@onready var music_volume_slider = $VBoxContainer/AudioSettings/MusicVolumeSlider
@onready var sfx_volume_slider = $VBoxContainer/AudioSettings/SFXVolumeSlider
@onready var master_volume_label = $VBoxContainer/AudioSettings/MasterVolumeLabel
@onready var music_volume_label = $VBoxContainer/AudioSettings/MusicVolumeLabel
@onready var sfx_volume_label = $VBoxContainer/AudioSettings/SFXVolumeLabel

@onready var fullscreen_checkbox = $VBoxContainer/VideoSettings/FullscreenCheckBox
@onready var vsync_checkbox = $VBoxContainer/VideoSettings/VSyncCheckBox
@onready var resolution_option = $VBoxContainer/VideoSettings/ResolutionOption

@onready var close_button = $CloseButton

var tween: Tween

const RESOLUTIONS = [
	{"name": "1280x720", "width": 1280, "height": 720},
	{"name": "1366x768", "width": 1366, "height": 768},
	{"name": "1920x1080", "width": 1920, "height": 1080},
	{"name": "2560x1440", "width": 2560, "height": 1440},
]

func _ready():
	# 设置关闭按钮的pivot
	if close_button:
		close_button.pivot_offset = close_button.size / 2
		# 连接关闭按钮信号
		if not close_button.pressed.is_connected(_on_close_button_pressed):
			close_button.pressed.connect(_on_close_button_pressed)
		# 连接鼠标悬停信号以实现缩放效果
		if not close_button.mouse_entered.is_connected(_on_close_button_mouse_entered):
			close_button.mouse_entered.connect(_on_close_button_mouse_entered)
		if not close_button.mouse_exited.is_connected(_on_close_button_mouse_exited):
			close_button.mouse_exited.connect(_on_close_button_mouse_exited)
	
	# 加载保存的设置
	load_settings()
	
	# 连接信号
	if master_volume_slider:
		master_volume_slider.value_changed.connect(_on_master_volume_changed)
	if music_volume_slider:
		music_volume_slider.value_changed.connect(_on_music_volume_changed)
	if sfx_volume_slider:
		sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	if fullscreen_checkbox:
		fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	if vsync_checkbox:
		vsync_checkbox.toggled.connect(_on_vsync_toggled)
	if resolution_option:
		resolution_option.item_selected.connect(_on_resolution_selected)
		# 填充分辨率选项
		for res in RESOLUTIONS:
			resolution_option.add_item(res.name)
	
	# 更新标签显示
	update_volume_labels()

func load_settings():
	# 从ConfigFile加载设置，如果不存在则使用默认值
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err != OK:
		# 使用默认设置
		set_default_settings()
		return
	
	# 加载音频设置
	if master_volume_slider:
		master_volume_slider.value = config.get_value("audio", "master_volume", 100.0)
	if music_volume_slider:
		music_volume_slider.value = config.get_value("audio", "music_volume", 80.0)
	if sfx_volume_slider:
		sfx_volume_slider.value = config.get_value("audio", "sfx_volume", 80.0)
	
	# 加载视频设置
	if fullscreen_checkbox:
		fullscreen_checkbox.button_pressed = config.get_value("video", "fullscreen", false)
	if vsync_checkbox:
		vsync_checkbox.button_pressed = config.get_value("video", "vsync", true)
	
	# 应用视频设置
	apply_video_settings()
	
	# 加载分辨率设置
	var saved_resolution_index = config.get_value("video", "resolution_index", 0)
	if resolution_option and saved_resolution_index < RESOLUTIONS.size():
		resolution_option.selected = saved_resolution_index
		apply_resolution(saved_resolution_index)

func save_settings():
	var config = ConfigFile.new()
	
	# 保存音频设置
	if master_volume_slider:
		config.set_value("audio", "master_volume", master_volume_slider.value)
	if music_volume_slider:
		config.set_value("audio", "music_volume", music_volume_slider.value)
	if sfx_volume_slider:
		config.set_value("audio", "sfx_volume", sfx_volume_slider.value)
	
	# 保存视频设置
	if fullscreen_checkbox:
		config.set_value("video", "fullscreen", fullscreen_checkbox.button_pressed)
	if vsync_checkbox:
		config.set_value("video", "vsync", vsync_checkbox.button_pressed)
	if resolution_option:
		config.set_value("video", "resolution_index", resolution_option.selected)
	
	# 保存到文件
	config.save("user://settings.cfg")

func set_default_settings():
	# 设置默认值
	if master_volume_slider:
		master_volume_slider.value = 100.0
	if music_volume_slider:
		music_volume_slider.value = 80.0
	if sfx_volume_slider:
		sfx_volume_slider.value = 80.0
	if fullscreen_checkbox:
		fullscreen_checkbox.button_pressed = false
	if vsync_checkbox:
		vsync_checkbox.button_pressed = true
	if resolution_option:
		resolution_option.selected = 0
	
	apply_video_settings()
	update_volume_labels()

func apply_video_settings():
	if fullscreen_checkbox:
		if fullscreen_checkbox.button_pressed:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	if vsync_checkbox:
		if vsync_checkbox.button_pressed:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		else:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func apply_resolution(index: int):
	if index < 0 or index >= RESOLUTIONS.size():
		return
	
	var res = RESOLUTIONS[index]
	DisplayServer.window_set_size(Vector2i(res.width, res.height))
	# 居中窗口
	var screen_size = DisplayServer.screen_get_size()
	var window_size = Vector2i(res.width, res.height)
	var pos = (screen_size - window_size) / 2
	DisplayServer.window_set_position(pos)

func update_volume_labels():
	if master_volume_label and master_volume_slider:
		master_volume_label.text = "主音量: %d%%" % int(master_volume_slider.value)
	if music_volume_label and music_volume_slider:
		music_volume_label.text = "音乐音量: %d%%" % int(music_volume_slider.value)
	if sfx_volume_label and sfx_volume_slider:
		sfx_volume_label.text = "音效音量: %d%%" % int(sfx_volume_slider.value)

func _on_master_volume_changed(value: float):
	update_volume_labels()
	# 应用音量（这里需要根据实际的音频系统实现）
	# AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value / 100.0))
	save_settings()

func _on_music_volume_changed(value: float):
	update_volume_labels()
	# 应用音量
	# AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value / 100.0))
	save_settings()

func _on_sfx_volume_changed(value: float):
	update_volume_labels()
	# 应用音量
	# AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value / 100.0))
	save_settings()

func _on_fullscreen_toggled(button_pressed: bool):
	apply_video_settings()
	save_settings()

func _on_vsync_toggled(button_pressed: bool):
	apply_video_settings()
	save_settings()

func _on_resolution_selected(index: int):
	apply_resolution(index)
	save_settings()

func _on_close_button_pressed():
	var main_menu = get_tree().root.get_node_or_null("MainMenu")
	if main_menu:
		main_menu.hide_settings_panel()
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

