extends Control

@onready var avatar: TextureRect = $Avatar
@onready var level_label: Label = $LevelLabel
@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthBar/HealthLabel
@onready var mana_bar: ProgressBar = $ManaBar
@onready var mana_label: Label = $ManaBar/ManaLabel
@onready var exp_bar: ProgressBar = $ExpBar
@onready var exp_label: Label = $ExpBar/ExpLabel

var max_health: int = 100
var current_health: int = 100
var max_mana: int = 100
var current_mana: int = 100
var max_exp: int = 100
var current_exp: int = 0
var level: int = 1

var _hp_tween: Tween
var _mp_tween: Tween
var _exp_tween: Tween

func _ready() -> void:
	Global.apply_character_avatar(avatar, Global.selected_character)
	update_ui(false)

func update_ui(animate: bool = true) -> void:
	level_label.text = "Lv.%d" % level
	_set_bar(health_bar, health_label, current_health, max_health, animate, "_hp_tween")
	_set_bar(mana_bar, mana_label, current_mana, max_mana, animate, "_mp_tween")
	_set_bar(exp_bar, exp_label, current_exp, max_exp, animate, "_exp_tween")
	_tint_health_fill()

func _set_bar(bar: ProgressBar, label: Label, value: int, max_value: int, animate: bool, tween_field: String) -> void:
	if bar == null or label == null:
		return
	bar.max_value = maxi(max_value, 1)
	label.text = "%d/%d" % [value, max_value]
	if not animate:
		bar.value = value
		return
	var tw: Tween = get(tween_field)
	if tw:
		tw.kill()
	tw = create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(bar, "value", float(value), 0.25)
	set(tween_field, tw)

func _tint_health_fill() -> void:
	if health_bar == null:
		return
	var ratio := float(current_health) / float(maxi(max_health, 1))
	var color := Color(0.78, 0.22, 0.2, 1)
	if ratio <= 0.25:
		color = Color(0.9, 0.15, 0.12, 1)
	elif ratio <= 0.5:
		color = Color(0.9, 0.45, 0.15, 1)
	elif ratio >= 0.85:
		color = Color(0.35, 0.72, 0.32, 1)
	var fill := health_bar.get_theme_stylebox("fill")
	if fill is StyleBoxFlat:
		var style := (fill as StyleBoxFlat).duplicate() as StyleBoxFlat
		style.bg_color = color
		health_bar.add_theme_stylebox_override("fill", style)

func set_health(value: int) -> void:
	current_health = clampi(value, 0, max_health)
	update_ui()

func set_mana(value: int) -> void:
	current_mana = clampi(value, 0, max_mana)
	update_ui()

func set_exp(value: int) -> void:
	current_exp = clampi(value, 0, max_exp)
	update_ui()

func set_level(value: int) -> void:
	level = value
	update_ui(false)

func take_damage(amount: int) -> void:
	current_health = clampi(current_health - amount, 0, max_health)
	update_ui()

func heal(amount: int) -> void:
	current_health = clampi(current_health + amount, 0, max_health)
	update_ui()

func use_mana(amount: int) -> void:
	current_mana = clampi(current_mana - amount, 0, max_mana)
	update_ui()

func restore_mana(amount: int) -> void:
	current_mana = clampi(current_mana + amount, 0, max_mana)
	update_ui()

func gain_exp(amount: int) -> void:
	current_exp = clampi(current_exp + amount, 0, max_exp)
	update_ui()

func bind_player_stats(player: Node) -> void:
	if player == null:
		return
	if "max_health" in player:
		max_health = int(player.max_health)
	if "current_health" in player:
		current_health = int(player.current_health)
	update_ui(false)
