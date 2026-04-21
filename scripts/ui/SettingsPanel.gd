extends Panel

@onready var master_volume_slider = $VBoxContainer/AudioSettings/MasterVolumeSlider
@onready var music_volume_slider = $VBoxContainer/AudioSettings/MusicVolumeSlider
@onready var sfx_volume_slider = $VBoxContainer/AudioSettings/SFXVolumeSlider
@onready var master_volume_label = $VBoxContainer/AudioSettings/MasterVolumeLabel
@onready var music_volume_label = $VBoxContainer/AudioSettings/MusicVolumeLabel
@onready var sfx_volume_label = $VBoxContainer/AudioSettings/SFXVolumeLabel

@onready var close_button = $CloseButton

var tween: Tween

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
	
	# 应用音频设置
	apply_audio_settings()

func save_settings():
	var config = ConfigFile.new()
	
	# 保存音频设置
	if master_volume_slider:
		config.set_value("audio", "master_volume", master_volume_slider.value)
	if music_volume_slider:
		config.set_value("audio", "music_volume", music_volume_slider.value)
	if sfx_volume_slider:
		config.set_value("audio", "sfx_volume", sfx_volume_slider.value)
	
	
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
	update_volume_labels()
	apply_audio_settings()

func update_volume_labels():
	if master_volume_label and master_volume_slider:
		master_volume_label.text = "主音量: %d%%" % int(master_volume_slider.value)
	if music_volume_label and music_volume_slider:
		music_volume_label.text = "音乐音量: %d%%" % int(music_volume_slider.value)
	if sfx_volume_label and sfx_volume_slider:
		sfx_volume_label.text = "音效音量: %d%%" % int(sfx_volume_slider.value)

func apply_audio_settings():
	# 应用音频设置
	if master_volume_slider:
		var master_bus_index = AudioServer.get_bus_index("Master")
		if master_bus_index >= 0:
			AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(master_volume_slider.value / 100.0))
	
	if music_volume_slider:
		var music_bus_index = AudioServer.get_bus_index("Music")
		if music_bus_index >= 0:
			AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(music_volume_slider.value / 100.0))
		else:
			# 如果 Music 总线不存在，使用 Master 总线
			var master_bus_index = AudioServer.get_bus_index("Master")
			if master_bus_index >= 0:
				AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(music_volume_slider.value / 100.0))
	
	if sfx_volume_slider:
		var sfx_bus_index = AudioServer.get_bus_index("SFX")
		if sfx_bus_index >= 0:
			AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(sfx_volume_slider.value / 100.0))
		else:
			# 如果 SFX 总线不存在，使用 Master 总线
			var master_bus_index = AudioServer.get_bus_index("Master")
			if master_bus_index >= 0:
				AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(sfx_volume_slider.value / 100.0))

func _on_master_volume_changed(value: float):
	update_volume_labels()
	apply_audio_settings()
	save_settings()

func _on_music_volume_changed(value: float):
	update_volume_labels()
	apply_audio_settings()
	save_settings()

func _on_sfx_volume_changed(value: float):
	update_volume_labels()
	apply_audio_settings()
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

