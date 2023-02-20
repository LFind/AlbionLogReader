extends Control

@onready var container_items:Control = %ItemsContainer
@onready var search_field = %SearchField
@onready var button_add_log = %ButtonAddLog
@onready var window_item_info = $WindowItemInfo


var items:Dictionary

func _ready():
	DisplayServer.window_set_size(Vector2i(size))
	DisplayServer.window_can_draw()
	Event.request_window_item_info.connect(_on_request_window_item_info)
	Event.items_update.connect(_update)
	
	window_item_info.close_requested.connect(func():
		window_item_info.visible = false
		)
	
	button_add_log.pressed.connect(func():
		LogData.append_logs(LogData.parse(DisplayServer.clipboard_get()))
		)
	
	search_field.gui_input.connect(func(event:InputEvent):
		if event.is_action("ui_text_completion_accept"):
			search_field.release_focus()
		)
	
	search_field.text_changed.connect(func(new_text:String):
		for node in container_items.get_children():
			node.visible = true
			if new_text != "":
				node.visible = new_text.to_lower() in node.entry["item"].to_lower()
		)
	
	
	search_field.clear()
	LogData.load_log(LogData.PATH)
	
	pass


func _unhandled_input(event):
	if event.is_action("ui_mouse_left"):
		var focused_node:Control = get_viewport().gui_get_focus_owner()
		if focused_node:
			focused_node.release_focus()


func _input(event):
	if event.is_action("reload"):
		LogData.load_log(LogData.PATH)


func _update():
	for node in container_items.get_children():
		node.queue_free()
	var merged_logs = LogData.merge_logs(LogData.log_data)
	for entry in merged_logs:
		create_item(entry)


func _on_request_window_item_info(item_name:String):
	window_item_info.grab_focus()
	window_item_info.visible = true


func create_item(entry:Dictionary) -> Control:
	var scene = preload("res://table_item.tscn").instantiate()
	container_items.add_child(scene)
	scene.set_entry(entry)
	return scene
