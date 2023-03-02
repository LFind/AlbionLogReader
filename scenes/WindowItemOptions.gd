extends Window

@onready var item_options_pane = $ItemOptionsPane


func _ready():
	visible = false
	close_requested.connect(_on_close_requested)
	Event.request_window_item_options.connect(_on_request_window)
	
	min_size = item_options_pane.size
	item_options_pane.position = Vector2i.ZERO

func _on_close_requested():
	visible = false
	item_options_pane._on_close_requested()
	var focused_node:Control = get_viewport().gui_get_focus_owner()
	if focused_node:
		focused_node.release_focus()

func _on_request_window(item_name:String):
	var mode = self.mode
	visible = false
	visible = true
	self.mode = mode
	grab_focus()
	set_size(item_options_pane.size)
	title = "Настройки предмета: \"" + item_name + "\""
	item_options_pane.set_item(item_name)
	
