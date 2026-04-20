extends Container

func _ready():
	# 根布局 VBoxContainer
	var root_vbox = VBoxContainer.new()
	root_vbox.anchor_right = 1
	root_vbox.anchor_bottom = 1
	root_vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	root_vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(root_vbox)
	# 第一个部分（第一行）
	var part1_vbox = VBoxContainer.new()
	_add_row(part1_vbox, 0)
	root_vbox.add_child(part1_vbox)

	# 空白分隔
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	root_vbox.add_child(spacer1)

	# 第二个部分（第二、三行）
	var part2_vbox = VBoxContainer.new()
	_add_row(part2_vbox, 1)
	# 空白分隔
	var spacer0 = Control.new()
	spacer0.custom_minimum_size = Vector2(0, -20)
	root_vbox.add_child(spacer0)
	_add_row(part2_vbox, 2)
	root_vbox.add_child(part2_vbox)

	# 空白分隔
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	root_vbox.add_child(spacer2)

	# 第三个部分（第四行）
	var part3_vbox = VBoxContainer.new()
	_add_row(part3_vbox, 3)
	root_vbox.add_child(part3_vbox)


func _add_row(vbox: VBoxContainer, row_index: int):
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Godot 4.x：用 add_theme_constant_override 设置按钮间距
	hbox.add_theme_constant_override("separation", 120)

	# 创建两个按钮
	for col in range(2):
		var btn = Button.new()
		btn.text = "Button %d" % (row_index * 2 + col)
		btn.custom_minimum_size = Vector2(100, 50)
		hbox.add_child(btn)

	vbox.add_child(hbox)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
