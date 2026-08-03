extends Node2D

@onready var player_hud = $CanvasLayer/PlayerHUD
var pack_panel: Control = null
var player: Node2D = null

func _ready():
	player = LevelRuntimeHelper.bootstrap(self, player_hud)
	pack_panel = BackpackLevelHelper.install(self)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("open_backpack"):
		toggle_backpack()

func toggle_backpack():
	if pack_panel == null or not is_instance_valid(pack_panel):
		pack_panel = BackpackLevelHelper.install(self)
	BackpackLevelHelper.toggle(pack_panel)
