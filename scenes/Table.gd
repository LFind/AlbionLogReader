extends Control

@onready var container_items:Control = %ItemsContainer
@onready var search_field = %SearchField
@onready var button_add_log = %ButtonAddLog


var items:Dictionary

func _ready():
	DisplayServer.window_set_size(Vector2i(size))
	DisplayServer.window_can_draw()
	Event.items_update.connect(_update)
	
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
	
	for item in LogData.get_existing_items(LogData.log_data):
		create_item(item)

func create_item(item:String) -> Control:
	var scene = preload("res://scenes/elements/table_item.tscn").instantiate()
	container_items.add_child(scene)
	scene.set_item(item)
	return scene
