extends Control

enum Sort {
	NAME_UP,
	NAME_DOWN,
	COUNT_UP,
	COUNT_DOWN,
	DATE_OLDEST,
	DATE_LATEST,
}

@onready var container_items:Control = %ItemsContainer
@onready var search_field = %SearchField
@onready var button_add_log = %ButtonAddLog
@onready var sort_option = %SortOption


var item_nodes:Array[Node]
var sorter:Sort

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
				node.visible = new_text.to_lower() in node.item.to_lower()
		)
	
	
	sort_option.clear()
	for i in Sort.values(): sort_option.add_item("")
	sort_option.set_item_text(Sort.NAME_UP, "По предмету (Возв.)")
	sort_option.set_item_text(Sort.NAME_DOWN, "По предмету (Убыв.)")
	sort_option.set_item_text(Sort.COUNT_UP, "По количеству (Возв.)")
	sort_option.set_item_text(Sort.COUNT_DOWN, "По количеству (Убыв.)")
	sort_option.set_item_text(Sort.DATE_OLDEST, "По изменению (Возв.)")
	sort_option.set_item_text(Sort.DATE_LATEST, "По изменению (Убыв.)")
	
	sort_option.item_selected.connect(func(index:int): _sort())
	
	var clear_item_nodes = func():
		for node in container_items.get_children():
			container_items.remove_child(node)
	var add_item_nodes = func():
		for node in item_nodes:
			container_items.add_child(node)
	
	sort_option.set_item_metadata(Sort.NAME_DOWN, func(reverse:bool = false):
		clear_item_nodes.call()
		item_nodes.sort_custom(func(a, b) -> bool:
			var result = 0
			if a.item < b.item:
				result = -1
			elif a.item > b.item:
				result = 1
			return result > 0)
		if reverse:
			item_nodes.reverse()
		add_item_nodes.call()
		)
	sort_option.set_item_metadata(Sort.DATE_LATEST, func(reverse:bool = false):
		clear_item_nodes.call()
		item_nodes.sort_custom(func(a, b) -> bool:
			return LogData.compare_datetime(a.last_change, b.last_change))
		if reverse:
			item_nodes.reverse()
		add_item_nodes.call()
		)
	sort_option.set_item_metadata(Sort.COUNT_DOWN, func(reverse:bool = false):
		clear_item_nodes.call()
		item_nodes.sort_custom(func(a, b) -> bool:
			var result = 0
			if a.count < b.count:
				result = -1
			elif a.count > b.count:
				result = 1
			return result > 0)
		if reverse:
			item_nodes.reverse()
		add_item_nodes.call()
		)
	
	sort_option.set_item_metadata(Sort.NAME_UP, sort_option.get_item_metadata(Sort.NAME_DOWN).bind(true))
	sort_option.set_item_metadata(Sort.DATE_OLDEST, sort_option.get_item_metadata(Sort.DATE_LATEST).bind(true))
	sort_option.set_item_metadata(Sort.COUNT_UP, sort_option.get_item_metadata(Sort.COUNT_DOWN).bind(true))
	
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
		var scene = preload("res://scenes/elements/table_item.tscn").instantiate()
		scene.set_item(item)
		item_nodes.append(scene)
	_sort()

func _sort():
	sort_option.get_selected_metadata().call()
