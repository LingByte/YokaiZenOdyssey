extends Control

@onready var video: VideoStreamPlayer = $VideoPlayer
@onready var skip_hint: Label = $SkipHint

var can_skip := false

func _ready():
	DisplayServer.window_set_title("禅妖山海行")
	var viewport_size = get_viewport_rect().size
	video.position = Vector2.ZERO
	video.size = viewport_size
	video.expand = true
	video.play()
	video.finished.connect(_on_video_finished)

	skip_hint.position.x = viewport_size.x - skip_hint.size.x - 20
	skip_hint.position.y = viewport_size.y - skip_hint.size.y - 10
	skip_hint.modulate.a = 0

	var tween = create_tween()
	tween.tween_property(skip_hint, "modulate:a", 0.6, 0.5).set_delay(1.0)

	can_skip = true

func _input(event):
	if not can_skip:
		return
	if event is InputEventKey or event is InputEventMouseButton:
		if event.pressed:
			_go_to_menu()

func _on_video_finished():
	_go_to_menu()

func _go_to_menu():
	can_skip = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
