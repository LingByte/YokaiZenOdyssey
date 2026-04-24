extends Control

@onready var avatar = $Avatar
@onready var level_label = $LevelLabel
@onready var health_bar = $HealthBar
@onready var health_label = $HealthBar/HealthLabel
@onready var mana_bar = $ManaBar
@onready var mana_label = $ManaBar/ManaLabel
@onready var exp_bar = $ExpBar
@onready var exp_label = $ExpBar/ExpLabel

# 玩家数据
var max_health: int = 100
var current_health: int = 100
var max_mana: int = 100
var current_mana: int = 100
var max_exp: int = 100
var current_exp: int = 0
var level: int = 1

func _ready() -> void:
	# 根据选择的角色设置头像
	if Global.selected_character == "悟空":
		avatar.texture = load("res://assets/avatars/default_avatar01.png")
	elif Global.selected_character == "八戒":
		avatar.texture = load("res://assets/avatars/default_avatar02.png")
	else:
		avatar.texture = load("res://assets/avatars/default_avatar01.png")
	
	# 初始化UI
	update_ui()

func update_ui():
	# 更新等级
	level_label.text = "Lv." + str(level)
	
	# 更新血条
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_label.text = str(current_health) + "/" + str(max_health)
	
	# 更新蓝条
	mana_bar.max_value = max_mana
	mana_bar.value = current_mana
	mana_label.text = str(current_mana) + "/" + str(max_mana)
	
	# 更新经验条
	exp_bar.max_value = max_exp
	exp_bar.value = current_exp
	exp_label.text = str(current_exp) + "/" + str(max_exp)

func set_health(value: int):
	current_health = clamp(value, 0, max_health)
	update_ui()

func set_mana(value: int):
	current_mana = clamp(value, 0, max_mana)
	update_ui()

func set_exp(value: int):
	current_exp = clamp(value, 0, max_exp)
	update_ui()

func set_level(value: int):
	level = value
	update_ui()

func take_damage(amount: int):
	current_health = clamp(current_health - amount, 0, max_health)
	update_ui()

func heal(amount: int):
	current_health = clamp(current_health + amount, 0, max_health)
	update_ui()

func use_mana(amount: int):
	current_mana = clamp(current_mana - amount, 0, max_mana)
	update_ui()

func restore_mana(amount: int):
	current_mana = clamp(current_mana + amount, 0, max_mana)
	update_ui()

func gain_exp(amount: int):
	current_exp = clamp(current_exp + amount, 0, max_exp)
	update_ui()
