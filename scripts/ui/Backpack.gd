extends Node2D

@onready var closed_sprite := $ClosePack
@onready var open_sprite := $OpenPack
@onready var label := $Label
@onready var area := $Area2D

func _ready():
	label.visible = true
	# 初始状态：显示关闭背包
	closed_sprite.visible = true
	open_sprite.visible = false

func _on_mouse_entered():
	print("触碰")
	closed_sprite.visible = false
	open_sprite.visible = true
	label.visible = false

func _on_mouse_exited():
	print("离开")
	closed_sprite.visible = true
	open_sprite.visible = false
	label.visible = true

func _on_input_event(viewport, event, shape_idx):
	print("点击")
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("点击了")
		# 尝试在当前场景中查找背包面板
		var current_scene = get_tree().current_scene
		if current_scene:
			# 如果当前场景有 toggle_backpack 方法，调用它
			if current_scene.has_method("toggle_backpack"):
				current_scene.toggle_backpack()
			# 否则尝试查找背包面板
			elif current_scene.has_method("show_pack_panel"):
				current_scene.show_pack_panel()
			else:
				# 尝试使用全局函数
				Global.toggle_backpack()
