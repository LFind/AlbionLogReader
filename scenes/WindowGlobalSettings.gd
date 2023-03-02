extends Window

@onready var content_pane = $Content


func _ready():
	close_requested.connect(_on_close_requested)
	Event.request_window_options.connect(_on_request_window)
	
	min_size = content_pane.size
	content_pane.position = Vector2i.ZERO

func _on_close_requested():
	visible = false
	content_pane._on_close_requested()
	var focused_node:Control = get_viewport().gui_get_focus_owner()
	if focused_node:
		focused_node.release_focus()

func _on_request_window():
	var mode = self.mode
	visible = false
	visible = true
	self.mode = mode
	set_size(content_pane.size)
	
