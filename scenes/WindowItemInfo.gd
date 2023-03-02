extends Window

@onready var item_info_pane = $ItemInfoPane
@onready var window_item_options = $WindowItemOptions
@onready var panel_background = %PanelBackground


func _ready():
	close_requested.connect(_on_close_requested)
	Event.request_window_item_info.connect(_on_request_window)
	min_size = item_info_pane.size
	item_info_pane.position = Vector2i.ZERO

func _process(delta):
	window_item_options.position.x = clamp(window_item_options.position.x, 8, size.x - (window_item_options.size.x + 8))
	window_item_options.position.y = clamp(window_item_options.position.y, 32, size.y - (window_item_options.size.y + 8))
	if window_item_options.visible:
		panel_background.modulate.a = lerp(panel_background.modulate.a, 0.9, 0.1)
		window_item_options.position.x = lerp(window_item_options.position.x, self.size.x/2 - window_item_options.size.x/2, 0.1)
		window_item_options.position.y = lerp(window_item_options.position.y, self.size.y/2 - window_item_options.size.y/2 + 24, 0.1)
	else:
		window_item_options.position = self.size/2 - window_item_options.size/2
		panel_background.modulate.a = lerp(panel_background.modulate.a, 0.0, 0.25)
	
	panel_background.visible = panel_background.modulate.a > 0.1

func _on_close_requested():
	window_item_options.close_requested.emit()
	visible = false
	var focused_node:Control = get_viewport().gui_get_focus_owner()
	if focused_node:
		focused_node.release_focus()

func _on_request_window(item_name:String):
	var mode = self.mode
	visible = false
	visible = true
	self.mode = mode
	set_size(item_info_pane.size)
	item_info_pane.set_item(item_name)
	title = "Подробности: \"" + item_name + "\""
