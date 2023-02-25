extends Node

const DIR_ICONS = "icons/"
const PATH = "items.ini"
var items:Array[String]
var items_data:ConfigFile = ConfigFile.new()

func _ready():
	load_items(PATH)
	Event.update_logs.connect(func():
		append_items(LogData.get_unique_items(LogData.log_data))
		)

func load_items(path:String) -> Array[String]:
	var items:Array[String]
	items_data.load(PATH)
	items.clear()
	append_items(items_data.get_sections())
	return items

func save_items(path:String):
	items_data.save(path)

func append_items(items:Array):
	items.sort()
	for item in items:
		if not item in self.items:
			self.items.append(item)
			items_data.set_value(item,"icon", items_data.get_value(item, "icon", ""))
			items_data.set_value(item,"hidden", items_data.get_value(item, "hidden", false))
			items_data.set_value(item,"category", items_data.get_value(item, "category", ""))
			items_data.set_value(item,"count_min", items_data.get_value(item, "category", ""))
			items_data.set_value(item,"count_max", items_data.get_value(item, "category", ""))
#			items_data.set_value(item,"color_minimum", items_data.get_value(item, "color_minimum", "703030"))
#			items_data.set_value(item,"color_low", items_data.get_value(item, "color_minimum", "823f00"))
	Event.update_items.emit()
	save_items(PATH)

func get_icon(item:String) -> String:
	var path:String = items_data.get_value(item,"icon", "").strip_edges()
	if path != "":
		return DIR_ICONS + path
	else:
		return "res://textures/unknown_icon.png"

func get_visibility(item:String):
	return items_data.get_value(item,"hidden", false)
	
func get_category(item:String):
	return items_data.get_value(item,"category", "").strip_edges()
	
	
