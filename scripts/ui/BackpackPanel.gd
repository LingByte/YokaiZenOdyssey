extends Panel
## 背包面板：可挂在神霄完整 UI 上，也可在关卡空壳上自建交互层

const BAG_CAPACITY := 18
const FONT_PATH := "res://assets/ttf/FZSTK.TTF"

var http: HTTPRequest
var tab_equipment: Button
var tab_property: Button
var tab_fashion: Button
var tab_scripture: Button
var equip_weapon: Button
var equip_accessory: Button
var equip_armor: Button
var equip_artifact: Button
var label_hp: Label
var label_mp: Label
var label_atk: Label
var label_def: Label
var label_luck: Label
var label_dodge: Label
var label_crit: Label
var label_re_hp: Label
var label_re_mp: Label
var label_magic: Label

var _bag_buttons: Array[Button] = []
var _current_category: String = "equipment"
var _slots: Array = []
var _equipment: Array = []
var _selected_inv_id: int = -1
var _selected_equip_slot: String = ""
var _detail_label: Label
var _action_button: Button
var _font: Font

func _ready() -> void:
	_font = load(FONT_PATH) as Font if ResourceLoader.exists(FONT_PATH) else null
	_resolve_or_build_ui()
	if http and not http.request_completed.is_connected(_on_http_completed):
		http.request_completed.connect(_on_http_completed)

	_wire_tabs()
	_wire_equip_slots()
	for i in _bag_buttons.size():
		var btn := _bag_buttons[i]
		var idx := i
		if not btn.pressed.is_connected(_on_bag_slot_pressed.bind(idx)):
			btn.pressed.connect(_on_bag_slot_pressed.bind(idx))
	if _action_button and not _action_button.pressed.is_connected(_on_action_pressed):
		_action_button.pressed.connect(_on_action_pressed)
	_highlight_tab()

func _resolve_or_build_ui() -> void:
	http = get_node_or_null("HTTPRequest") as HTTPRequest
	if http == null:
		http = HTTPRequest.new()
		http.name = "HTTPRequest"
		add_child(http)

	tab_equipment = get_node_or_null("Equipment") as Button
	tab_property = get_node_or_null("Property") as Button
	tab_fashion = get_node_or_null("Fashionable") as Button
	tab_scripture = get_node_or_null("Scripture") as Button

	equip_weapon = get_node_or_null("Panel/Equipment/Button") as Button
	equip_accessory = get_node_or_null("Panel/Equipment/Button2") as Button
	equip_armor = get_node_or_null("Panel/Equipment/Button3") as Button
	equip_artifact = get_node_or_null("Panel/Equipment/Button4") as Button

	label_hp = get_node_or_null("Panel/Node2D/Heath") as Label
	label_mp = get_node_or_null("Panel/Node2D/Mana") as Label
	label_atk = get_node_or_null("Panel/Node2D/Attack") as Label
	label_def = get_node_or_null("Panel/Node2D/Defend") as Label
	label_luck = get_node_or_null("Panel/Node2D/Luck") as Label
	label_dodge = get_node_or_null("Panel/Node2D/Sidestep") as Label
	label_crit = get_node_or_null("Panel/Node2D/Crit") as Label
	label_re_hp = get_node_or_null("Panel/Node2D/ReBlood") as Label
	label_re_mp = get_node_or_null("Panel/Node2D/ReMana") as Label
	label_magic = get_node_or_null("Panel/Node2D/ReMagic") as Label

	if tab_equipment == null:
		_build_runtime_ui()
	else:
		_collect_bag_buttons()
		_ensure_detail_ui()
		_ensure_close_button()

func _build_runtime_ui() -> void:
	# 关卡空壳：按神霄布局自建可交互控件
	tab_equipment = _make_tab("Equipment", "装备", Vector2(602, 74))
	tab_property = _make_tab("Property", "道具", Vector2(752, 73))
	tab_fashion = _make_tab("Fashionable", "时装", Vector2(899, 74))
	tab_scripture = _make_tab("Scripture", "经文", Vector2(1046, 73))

	var side := Panel.new()
	side.name = "Panel"
	side.position = Vector2(70, 97)
	side.size = Vector2(471, 540)
	var side_style := StyleBoxFlat.new()
	side_style.bg_color = Color(0.08, 0.1, 0.08, 0.55)
	side_style.set_corner_radius_all(6)
	side.add_theme_stylebox_override("panel", side_style)
	add_child(side)

	var stats_host := Node2D.new()
	stats_host.name = "Node2D"
	side.add_child(stats_host)
	label_hp = _make_stat_label(stats_host, "Heath", Vector2(33, 288), "HP:     70")
	label_mp = _make_stat_label(stats_host, "Mana", Vector2(285, 288), "MP:     100")
	label_atk = _make_stat_label(stats_host, "Attack", Vector2(33, 334), "攻击:     10")
	label_def = _make_stat_label(stats_host, "Defend", Vector2(285, 332), "防御:     0")
	label_luck = _make_stat_label(stats_host, "Luck", Vector2(33, 368), "幸运:     70")
	label_dodge = _make_stat_label(stats_host, "Sidestep", Vector2(285, 367), "闪避:     0%")
	label_re_hp = _make_stat_label(stats_host, "ReBlood", Vector2(33, 412), "回血:     0")
	label_crit = _make_stat_label(stats_host, "Crit", Vector2(285, 410), "暴击:     0%")
	label_re_mp = _make_stat_label(stats_host, "ReMana", Vector2(33, 446), "回蓝:     0")
	label_magic = _make_stat_label(stats_host, "ReMagic", Vector2(285, 445), "魔抗:     0%")

	var equip_host := Node2D.new()
	equip_host.name = "Equipment"
	side.add_child(equip_host)
	equip_weapon = _make_equip_btn(equip_host, "Button", "武器", Vector2(304, 73))
	equip_accessory = _make_equip_btn(equip_host, "Button2", "饰品", Vector2(384, 73))
	equip_armor = _make_equip_btn(equip_host, "Button3", "装备", Vector2(304, 181))
	equip_artifact = _make_equip_btn(equip_host, "Button4", "法宝", Vector2(384, 181))

	_bag_buttons.clear()
	var origins := [
		Vector2(609, 131), Vector2(707, 130), Vector2(804, 131), Vector2(900, 131), Vector2(997, 131), Vector2(1094, 131),
		Vector2(609, 215), Vector2(707, 214), Vector2(804, 215), Vector2(900, 215), Vector2(997, 215), Vector2(1094, 215),
		Vector2(609, 300), Vector2(707, 299), Vector2(804, 300), Vector2(900, 300), Vector2(997, 300), Vector2(1094, 300),
	]
	for i in BAG_CAPACITY:
		var btn := Button.new()
		btn.name = "Button%d" % (i + 1) if i > 0 else "Button"
		btn.position = origins[i]
		btn.size = Vector2(86, 73)
		btn.focus_mode = Control.FOCUS_NONE
		_style_slot_button(btn)
		add_child(btn)
		_bag_buttons.append(btn)

	_ensure_detail_ui()
	_ensure_close_button()

func _make_tab(node_name: String, text: String, pos: Vector2) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.text = text
	btn.position = pos
	btn.size = Vector2(128, 33)
	btn.focus_mode = Control.FOCUS_NONE
	if _font:
		btn.add_theme_font_override("font", _font)
	btn.add_theme_font_size_override("font_size", 28)
	add_child(btn)
	return btn

func _make_stat_label(parent: Node, node_name: String, pos: Vector2, text: String) -> Label:
	var label := Label.new()
	label.name = node_name
	label.position = pos
	label.size = Vector2(160, 31)
	label.text = text
	if _font:
		label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", 22)
	parent.add_child(label)
	return label

func _make_equip_btn(parent: Node, node_name: String, text: String, pos: Vector2) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.text = text
	btn.position = pos
	btn.size = Vector2(65, 65)
	btn.focus_mode = Control.FOCUS_NONE
	_style_slot_button(btn)
	parent.add_child(btn)
	return btn

func _style_slot_button(btn: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.08, 0.35)
	style.set_border_width_all(1)
	style.border_color = Color(0.55, 0.45, 0.28, 0.55)
	style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)

func _collect_bag_buttons() -> void:
	_bag_buttons.clear()
	var candidates: Array[Button] = []
	for child in get_children():
		if child is Button and String(child.name).begins_with("Button"):
			candidates.append(child)
	candidates.sort_custom(func(a: Button, b: Button) -> bool:
		if absf(a.position.y - b.position.y) > 20.0:
			return a.position.y < b.position.y
		return a.position.x < b.position.x
	)
	_bag_buttons = candidates
	if _bag_buttons.size() > BAG_CAPACITY:
		_bag_buttons = _bag_buttons.slice(0, BAG_CAPACITY)

func _ensure_detail_ui() -> void:
	_detail_label = get_node_or_null("DetailLabel") as Label
	if _detail_label == null:
		_detail_label = Label.new()
		_detail_label.name = "DetailLabel"
		_detail_label.position = Vector2(609, 400)
		_detail_label.size = Vector2(560, 120)
		_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if _font:
			_detail_label.add_theme_font_override("font", _font)
		_detail_label.add_theme_font_size_override("font_size", 20)
		_detail_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.8))
		_detail_label.text = "选择一件物品查看详情"
		add_child(_detail_label)

	_action_button = get_node_or_null("ActionButton") as Button
	if _action_button == null:
		_action_button = Button.new()
		_action_button.name = "ActionButton"
		_action_button.position = Vector2(609, 530)
		_action_button.size = Vector2(160, 44)
		_action_button.text = "装备"
		_action_button.visible = false
		if _font:
			_action_button.add_theme_font_override("font", _font)
		add_child(_action_button)

func _ensure_close_button() -> void:
	var close_btn := get_node_or_null("CloseButton") as Button
	if close_btn == null:
		close_btn = Button.new()
		close_btn.name = "CloseButton"
		close_btn.position = Vector2(1225, 7)
		close_btn.size = Vector2(50, 50)
		close_btn.text = "×"
		close_btn.focus_mode = Control.FOCUS_NONE
		add_child(close_btn)
	if not close_btn.pressed.is_connected(_on_close_pressed):
		close_btn.pressed.connect(_on_close_pressed)

func _on_close_pressed() -> void:
	visible = false

func _wire_tabs() -> void:
	if tab_equipment and not tab_equipment.pressed.is_connected(_set_tab.bind("equipment")):
		tab_equipment.pressed.connect(_set_tab.bind("equipment"))
	if tab_property and not tab_property.pressed.is_connected(_set_tab.bind("consumable")):
		tab_property.pressed.connect(_set_tab.bind("consumable"))
	if tab_fashion and not tab_fashion.pressed.is_connected(_set_tab.bind("fashion")):
		tab_fashion.pressed.connect(_set_tab.bind("fashion"))
	if tab_scripture and not tab_scripture.pressed.is_connected(_set_tab.bind("scripture")):
		tab_scripture.pressed.connect(_set_tab.bind("scripture"))

func _wire_equip_slots() -> void:
	if equip_weapon and not equip_weapon.pressed.is_connected(_on_equip_slot_pressed.bind("weapon")):
		equip_weapon.pressed.connect(_on_equip_slot_pressed.bind("weapon"))
	if equip_accessory and not equip_accessory.pressed.is_connected(_on_equip_slot_pressed.bind("accessory")):
		equip_accessory.pressed.connect(_on_equip_slot_pressed.bind("accessory"))
	if equip_armor and not equip_armor.pressed.is_connected(_on_equip_slot_pressed.bind("armor")):
		equip_armor.pressed.connect(_on_equip_slot_pressed.bind("armor"))
	if equip_artifact and not equip_artifact.pressed.is_connected(_on_equip_slot_pressed.bind("artifact")):
		equip_artifact.pressed.connect(_on_equip_slot_pressed.bind("artifact"))

func refresh_if_needed() -> void:
	refresh()

func refresh() -> void:
	if _detail_label == null:
		return
	if Global.token.is_empty() or Global.current_save_slot < 1:
		_detail_label.text = "未登录或未选择存档，无法加载背包"
		return
	var headers = Global.auth_headers()
	var url = Global.api_url("/api/saves/%d/inventory" % Global.current_save_slot)
	var err = http.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		_detail_label.text = "请求背包失败"

func _set_tab(category: String) -> void:
	_current_category = category
	_selected_inv_id = -1
	_selected_equip_slot = ""
	if _action_button:
		_action_button.visible = false
	_highlight_tab()
	_render_bag()

func _highlight_tab() -> void:
	var tabs := {
		"equipment": tab_equipment,
		"consumable": tab_property,
		"fashion": tab_fashion,
		"scripture": tab_scripture,
	}
	for key in tabs:
		var btn: Button = tabs[key]
		if btn:
			btn.modulate = Color(1.2, 1.15, 0.85) if key == _current_category else Color.WHITE

func _on_http_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		_detail_label.text = "网络错误"
		return
	var text := body.get_string_from_utf8()
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		_detail_label.text = "解析背包数据失败"
		return
	if response_code >= 400:
		_detail_label.text = str(data.get("error", "请求失败"))
		return

	var inv = data
	if data.has("inventory"):
		inv = data["inventory"]
	_apply_inventory(inv)

func _apply_inventory(inv: Dictionary) -> void:
	_slots = inv.get("slots", [])
	_equipment = inv.get("equipment", [])
	_update_stats(inv.get("stats", {}))
	_render_equipment()
	_render_bag()
	if _detail_label and _detail_label.text.begins_with("未登录"):
		_detail_label.text = "选择一件物品查看详情"

func _update_stats(stats: Dictionary) -> void:
	if label_hp: label_hp.text = "HP:     %d" % int(stats.get("hp", 70))
	if label_mp: label_mp.text = "MP:     %d" % int(stats.get("mp", 100))
	if label_atk: label_atk.text = "攻击:     %d" % int(stats.get("atk", 10))
	if label_def: label_def.text = "防御:     %d" % int(stats.get("def", 0))
	if label_luck: label_luck.text = "幸运:     %d" % int(stats.get("luck", 70))
	if label_dodge: label_dodge.text = "闪避:     %d%%" % int(stats.get("dodge", 0))
	if label_crit: label_crit.text = "暴击:     %d%%" % int(stats.get("crit", 0))
	if label_re_hp: label_re_hp.text = "回血:     %d" % int(stats.get("re_hp", 0))
	if label_re_mp: label_re_mp.text = "回蓝:     %d" % int(stats.get("re_mp", 0))
	if label_magic: label_magic.text = "魔抗:     %d%%" % int(stats.get("magic_res", 0))

func _icon_for_item(item: Dictionary) -> Texture2D:
	var icon_id := str(item.get("icon", item.get("id", "")))
	if icon_id.is_empty():
		return null
	var path := "res://assets/items/%s.png" % icon_id
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

func _set_button_icon(btn: Button, item: Dictionary, fallback_text: String) -> void:
	if btn == null:
		return
	var tex := _icon_for_item(item) if not item.is_empty() else null
	if tex:
		btn.icon = tex
		btn.expand_icon = true
		btn.text = ""
	else:
		btn.icon = null
		btn.text = fallback_text

func _render_equipment() -> void:
	var by_slot := {}
	for e in _equipment:
		by_slot[str(e.get("slot", ""))] = e
	_set_equip_btn(equip_weapon, by_slot.get("weapon", {}), "武器")
	_set_equip_btn(equip_accessory, by_slot.get("accessory", {}), "饰品")
	_set_equip_btn(equip_armor, by_slot.get("armor", {}), "装备")
	_set_equip_btn(equip_artifact, by_slot.get("artifact", {}), "法宝")

func _set_equip_btn(btn: Button, entry, fallback: String) -> void:
	if btn == null:
		return
	if typeof(entry) != TYPE_DICTIONARY:
		btn.icon = null
		btn.text = fallback
		return
	var item = entry.get("item", null)
	if item == null or typeof(item) != TYPE_DICTIONARY:
		btn.icon = null
		btn.text = fallback
		return
	_set_button_icon(btn, item, fallback)

func _render_bag() -> void:
	var filtered: Array = []
	for s in _slots:
		var item: Dictionary = s.get("item", {})
		if str(item.get("category", "")) == _current_category:
			filtered.append(s)

	for i in _bag_buttons.size():
		var btn := _bag_buttons[i]
		btn.disabled = false
		if i < filtered.size():
			var slot_data: Dictionary = filtered[i]
			var item: Dictionary = slot_data.get("item", {})
			_set_button_icon(btn, item, str(item.get("name", "")))
			var qty := int(slot_data.get("quantity", 1))
			if qty > 1 and btn.text.is_empty():
				btn.text = "x%d" % qty
			btn.set_meta("inventory_id", int(slot_data.get("inventory_id", -1)))
			btn.set_meta("slot_data", slot_data)
			btn.modulate = Color(1.15, 1.1, 0.9) if int(slot_data.get("inventory_id", -1)) == _selected_inv_id else Color.WHITE
		else:
			btn.icon = null
			btn.text = ""
			if btn.has_meta("inventory_id"):
				btn.remove_meta("inventory_id")
			if btn.has_meta("slot_data"):
				btn.remove_meta("slot_data")
			btn.modulate = Color.WHITE

func _on_bag_slot_pressed(index: int) -> void:
	if index < 0 or index >= _bag_buttons.size():
		return
	var btn := _bag_buttons[index]
	if not btn.has_meta("slot_data"):
		_selected_inv_id = -1
		_selected_equip_slot = ""
		_detail_label.text = "空格子"
		_action_button.visible = false
		_render_bag()
		return
	var slot_data: Dictionary = btn.get_meta("slot_data")
	var item: Dictionary = slot_data.get("item", {})
	_selected_inv_id = int(slot_data.get("inventory_id", -1))
	_selected_equip_slot = ""
	_show_item_detail(item, true)
	_render_bag()

func _on_equip_slot_pressed(slot: String) -> void:
	_selected_equip_slot = slot
	_selected_inv_id = -1
	var entry = null
	for e in _equipment:
		if str(e.get("slot", "")) == slot:
			entry = e
			break
	if entry == null or entry.get("item", null) == null:
		_detail_label.text = "该槽位为空"
		_action_button.visible = false
		return
	_show_item_detail(entry["item"], false, true)

func _show_item_detail(item: Dictionary, _from_bag: bool = false, from_equip: bool = false) -> void:
	var item_name := str(item.get("name", "未知"))
	var desc := str(item.get("description", ""))
	var parts: PackedStringArray = []
	for key in ["atk", "def", "hp", "mp", "luck", "dodge", "crit", "re_hp", "re_mp", "magic_res"]:
		var v := int(item.get(key, 0))
		if v != 0:
			parts.append("%s+%d" % [key.to_upper(), v])
	var stats_line := "  ".join(parts) if parts.size() > 0 else "无额外属性"
	_detail_label.text = "%s\n%s\n%s" % [item_name, desc, stats_line]

	var cat := str(item.get("category", ""))
	if from_equip:
		_action_button.text = "卸下"
		_action_button.visible = true
	elif cat == "equipment":
		_action_button.text = "装备"
		_action_button.visible = true
	elif cat == "consumable":
		_action_button.text = "使用"
		_action_button.visible = true
	else:
		_action_button.visible = false

func _on_action_pressed() -> void:
	if Global.token.is_empty() or Global.current_save_slot < 1:
		return
	var headers = Global.auth_headers(["Content-Type: application/json"])
	var slot := Global.current_save_slot
	if _action_button.text == "卸下" and not _selected_equip_slot.is_empty():
		var body := JSON.stringify({"slot": _selected_equip_slot})
		http.request(Global.api_url("/api/saves/%d/equipment/unequip" % slot), headers, HTTPClient.METHOD_POST, body)
		return
	if _selected_inv_id < 0:
		return
	if _action_button.text == "装备":
		var body := JSON.stringify({"inventory_id": _selected_inv_id})
		http.request(Global.api_url("/api/saves/%d/equipment/equip" % slot), headers, HTTPClient.METHOD_POST, body)
	elif _action_button.text == "使用":
		var body := JSON.stringify({"inventory_id": _selected_inv_id})
		http.request(Global.api_url("/api/saves/%d/inventory/use" % slot), headers, HTTPClient.METHOD_POST, body)
