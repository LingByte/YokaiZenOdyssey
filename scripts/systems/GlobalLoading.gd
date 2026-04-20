extends Control

var next_scene_path := ""
@onready var loading_label := $Label
@onready var spinner = $Spinner

func _ready():
	# 延迟 1 帧保证布局加载完
	await get_tree().process_frame
	_load_target_scene()
	start_spinner()

func _load_target_scene():
	if next_scene_path == "":
		push_error("No scene set for loading!")
		return
	var packed_scene = load(next_scene_path)
	if packed_scene:
		await get_tree().create_timer(0.8).timeout  # 可加最低加载时间
		get_tree().change_scene_to_packed(packed_scene)
		queue_free()  # 加上这行（尽管 change_scene 会处理）
	else:
		loading_label.text = "加载失败"

func start_spinner():
	var tween = create_tween().set_loops()
	tween.tween_property(spinner, "rotation_degrees", 360, 1.0) \
		.set_trans(Tween.TRANS_LINEAR) \
		.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(spinner, "rotation_degrees", 0, 0)  # 归零用于循环
