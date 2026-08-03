extends Node
class_name LevelWaveController
## 关卡分波：清波开门；镜头 limit 与墙对齐，顶墙时人停在屏幕右侧

signal wave_started(wave_index: int)
signal wave_cleared(wave_index: int)
signal all_waves_cleared

const ENEMY_01 := preload("res://characters/enemies/types/Enemy01.tscn")
const LEVEL_CAMERA_RIGHT := 10141.0

var waves: Array = []
var current_wave: int = 0
var _host: Node = null
var _player: Node2D = null
var _left_wall: StaticBody2D
var _right_wall: StaticBody2D
var _wave_enemies: Array[Node] = []
var _awaiting_enter_next: bool = false
var _pending_left_x: float = 0.0
var _camera_left: float = 0.0
var _camera_right: float = LEVEL_CAMERA_RIGHT
var _all_done: bool = false

func setup(host: Node, wave_defs: Array, player: Node2D = null) -> void:
	_host = host
	_player = player
	waves = wave_defs
	_ensure_walls()
	current_wave = 0
	_all_done = false
	_awaiting_enter_next = false
	if waves.is_empty():
		all_waves_cleared.emit()
		return
	_apply_bounds_for_wave(0)
	_spawn_wave(0)
	wave_started.emit(0)
	# 下一帧再刷一次镜头，避开旧 BasePlayer 残留 / 相机未就绪
	call_deferred("_sync_camera_limits")

func _physics_process(_delta: float) -> void:
	# 每帧维持镜头边界，防止被其它逻辑覆盖
	if not _all_done and not waves.is_empty():
		_sync_camera_limits()

	if not _awaiting_enter_next or _all_done:
		return
	var player := _find_player()
	if player == null:
		return
	if player.global_position.x >= _pending_left_x + 24.0:
		_set_wall_x(_left_wall, _pending_left_x, true)
		_camera_left = _pending_left_x
		_sync_camera_limits()
		_awaiting_enter_next = false
		print("[Wave] 已锁定波区 left=", _pending_left_x)

func _find_player() -> Node2D:
	if _player != null and is_instance_valid(_player):
		return _player
	if _host == null:
		return null
	for node in _host.get_tree().get_nodes_in_group("player"):
		if node == null or not is_instance_valid(node):
			continue
		if node.is_queued_for_deletion():
			continue
		if not (node is Node2D):
			continue
		# 只要带 Camera2D 的活动角色
		if node.get_node_or_null("Camera2D") == null:
			continue
		_player = node as Node2D
		return _player
	return null

func _sync_camera_limits() -> void:
	var player := _find_player()
	if player == null:
		return
	var cam := player.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return
	cam.limit_smoothed = false
	cam.limit_left = int(floor(_camera_left))
	cam.limit_right = int(ceil(_camera_right))
	# 顶到右边界时让角色更容易贴到屏幕右侧
	cam.drag_horizontal_enabled = true
	cam.drag_left_margin = 0.15
	cam.drag_right_margin = 0.05
	if player.has_method("set_camera_bounds"):
		player.set_camera_bounds(_camera_left, _camera_right)

func _ensure_walls() -> void:
	_left_wall = _make_wall("WaveLeftWall")
	_right_wall = _make_wall("WaveRightWall")
	_host.add_child(_left_wall)
	_host.add_child(_right_wall)

func _make_wall(wall_name: String) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = wall_name
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(24, 2400)
	shape.shape = rect
	shape.position = Vector2(0, 400)
	body.add_child(shape)
	return body

func _set_wall_x(wall: StaticBody2D, x: float, enabled: bool) -> void:
	if wall == null:
		return
	wall.global_position = Vector2(x, 0)
	for child in wall.get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).set_deferred("disabled", not enabled)

func _apply_bounds_for_wave(wave_index: int) -> void:
	if wave_index < 0 or wave_index >= waves.size():
		return
	var w: Dictionary = waves[wave_index]
	var left_x := float(w.get("left", 0.0))
	var right_x := float(w.get("right", 2000.0))
	_camera_right = right_x
	if wave_index == 0:
		_set_wall_x(_left_wall, left_x, true)
		_camera_left = left_x
		_awaiting_enter_next = false
	else:
		_set_wall_x(_left_wall, left_x, false)
		_pending_left_x = left_x
		_awaiting_enter_next = true
	_set_wall_x(_right_wall, right_x, true)
	_sync_camera_limits()

func _spawn_wave(wave_index: int) -> void:
	_wave_enemies.clear()
	if wave_index < 0 or wave_index >= waves.size():
		return
	var w: Dictionary = waves[wave_index]
	var spawns: Array = w.get("spawns", [])
	for pos in spawns:
		var enemy: Node = ENEMY_01.instantiate()
		_host.add_child(enemy)
		if enemy is Node2D:
			(enemy as Node2D).global_position = pos as Vector2
		if "patrol_range" in enemy:
			enemy.patrol_range = 140.0
		if "detect_range" in enemy:
			enemy.detect_range = 420.0
		if enemy.has_signal("killed"):
			enemy.killed.connect(_on_wave_enemy_killed)
		_wave_enemies.append(enemy)
	print("[Wave] 第 ", wave_index + 1, "/", waves.size(), " 波 @ right=", waves[wave_index].get("right"), " 敌人 ", _wave_enemies.size())

func _on_wave_enemy_killed(_enemy: Node, _exp: int) -> void:
	Global.note_enemy_killed()
	_host.get_tree().create_timer(0.05).timeout.connect(_check_wave_clear)

func _alive_in_wave() -> int:
	var n := 0
	for e in _wave_enemies:
		if e == null or not is_instance_valid(e):
			continue
		if e.has_method("is_defeated") and e.is_defeated():
			continue
		n += 1
	return n

func _check_wave_clear() -> void:
	if not is_instance_valid(self) or _all_done:
		return
	if _alive_in_wave() > 0:
		return
	wave_cleared.emit(current_wave)
	_advance_wave()

func _advance_wave() -> void:
	_set_wall_x(_right_wall, float(waves[current_wave].get("right", 0.0)), false)

	var next := current_wave + 1
	if next >= waves.size():
		_all_done = true
		_awaiting_enter_next = false
		print("[Wave] 全部波次完成")
		all_waves_cleared.emit()
		return

	current_wave = next
	_apply_bounds_for_wave(current_wave)
	_spawn_wave(current_wave)
	wave_started.emit(current_wave)

func force_open_exit_bounds() -> void:
	_all_done = true
	_awaiting_enter_next = false
	if _right_wall:
		_set_wall_x(_right_wall, 99999.0, false)
	if _left_wall and waves.size() > 0:
		var last_left := float(waves[waves.size() - 1].get("left", 0.0))
		_set_wall_x(_left_wall, last_left, true)
		_camera_left = last_left
	_camera_right = LEVEL_CAMERA_RIGHT
	_sync_camera_limits()
