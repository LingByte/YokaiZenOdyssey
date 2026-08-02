extends Object
class_name BackpackLevelHelper
## 关卡内统一安装 / 开关可交互背包

const BACKPACK_SCENE := preload("res://scenes/ui/BackpackPanel.tscn")

static func install(host: Node) -> Control:
	var canvas := host.get_node_or_null("CanvasLayer") as CanvasLayer
	if canvas == null:
		push_warning("BackpackLevelHelper: 场景缺少 CanvasLayer")
		return null

	var existing := canvas.get_node_or_null("Panel")
	if existing and existing.has_method("refresh_if_needed"):
		existing.visible = false
		return existing as Control

	if existing:
		existing.name = "PanelLegacy"
		existing.queue_free()

	var panel: Control = BACKPACK_SCENE.instantiate()
	panel.name = "Panel"
	panel.visible = false
	canvas.add_child(panel)
	print("背包面板已安装（可交互）")
	return panel

static func toggle(panel: Control) -> Control:
	if panel == null or not is_instance_valid(panel):
		return null
	panel.visible = not panel.visible
	if panel.visible and panel.has_method("refresh_if_needed"):
		panel.refresh_if_needed()
	print("背包面板状态: ", panel.visible)
	return panel
