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
@onready var sort_option:OptionButton = %SortOption
@onready var button_add_log = %ButtonAddLog
@onready var button_refresh = %ButtonRefresh
@onready var button_settings = %ButtonSettings
@onready var button_show_hidden = %ButtonShowHidden

@onready var link_update = %LinkUpdate

var item_nodes:Array[Node]


func _ready():
	Event.update_logs.connect(_update)
	UpdateChecker.new_release.connect(func():
		link_update.visible = true
		link_update.text = link_update.text.format({"version": UpdateChecker.get_latest_version()})
		link_update.uri = UpdateChecker.get_latest_release_link()
		)
	
	# Кнопка показа скрытых предметов
	var icon_show = preload("res://textures/eye_show1.png")
	var icon_hide = preload("res://textures/eye_hide.png")
	button_show_hidden.button_pressed = Settings.get_show_hidden()
	button_show_hidden.pressed.connect(func():
		if button_show_hidden.button_pressed:
			button_show_hidden.icon = icon_show
		else:
			button_show_hidden.icon = icon_hide
		Settings.set_show_hidden(button_show_hidden.button_pressed)
		)
	
	button_settings.pressed.connect(func(): Event.request_window_settings.emit())
	
	button_refresh.pressed.connect(reload)
	
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
	sort_option.set_item_text(Sort.NAME_UP, "По предмету (Возр.)")
	sort_option.set_item_text(Sort.NAME_DOWN, "По предмету (Убыв.)")
	sort_option.set_item_text(Sort.COUNT_UP, "По количеству (Возр.)")
	sort_option.set_item_text(Sort.COUNT_DOWN, "По количеству (Убыв.)")
	sort_option.set_item_text(Sort.DATE_OLDEST, "По изменению (Возр.)")
	sort_option.set_item_text(Sort.DATE_LATEST, "По изменению (Убыв.)")
	
	sort_option.item_selected.connect(func(_index:int):_sort())
	
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
		sort_option.get_item_metadata(Sort.NAME_DOWN).call()
		clear_item_nodes.call()
		item_nodes.sort_custom(func(a, b) -> bool:
			return LogData.compare_datetime(a.last_change, b.last_change))
		if reverse:
			item_nodes.reverse()
		add_item_nodes.call()
		)
	sort_option.set_item_metadata(Sort.COUNT_DOWN, func(reverse:bool = false):
		sort_option.get_item_metadata(Sort.NAME_DOWN).call()
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
	
	_update()

func _unhandled_input(event):
	if event.is_action("ui_mouse_left"):
		var focused_node:Control = get_viewport().gui_get_focus_owner()
		if focused_node:
			focused_node.release_focus()

func reload():
	LogData.load_log(LogData.PATH)
	var focused_node:Control = get_viewport().gui_get_focus_owner()
	if focused_node:
		focused_node.release_focus()

func _input(event):
	if event.is_action("reload"):
		reload()

func _update():
	for node in container_items.get_children():
		node.queue_free()
	item_nodes.clear()
	
	var item_tscn = preload("res://scenes/items_table/elements/table_item.tscn")
	
	for item in ItemData.get_items():
		var scene = item_tscn.instantiate()
		scene.set_item(item)
		item_nodes.append(scene)
	
	_sort()

func _sort():
	sort_option.get_selected_metadata().call()
