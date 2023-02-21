extends Window

var item_info_pane:Control = preload("res://scenes/ItemInfoPane.tscn").instantiate()


func _ready():
	close_requested.connect(_on_close_requested)
	Event.request_window_item_info.connect(_on_request_window_item_info)
	
	add_child(item_info_pane)
	min_size = item_info_pane.size
	item_info_pane.position = Vector2i.ZERO

func _on_close_requested():
	visible = false
	var focused_node:Control = get_viewport().gui_get_focus_owner()
	if focused_node:
		focused_node.release_focus()

func _on_request_window_item_info(item_name:String):
	grab_focus()
	visible = true
	set_size(item_info_pane.size)
	item_info_pane.set_item(item_name)
	title = "Подробности: \"" + item_name + "\""
