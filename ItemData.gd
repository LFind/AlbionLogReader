extends Node

const UNKNOWN_ICON = "res://textures/unknown_icon.png"
const DIR_ICONS = "./icons/"
const PATH = "items.ini"

const COUNT_MIN = 10
const COUNT_LOW = 20

var items:Array[String]
var items_data:ConfigFile = ConfigFile.new()

func _ready():
	load_data()
	Event.update_logs.connect(func():
		load_data()
		append_items(LogData.get_unique_items(LogData.log_data))
		)

func load_data(path:String = PATH) -> Array[String]:
	var items:Array[String]
	items_data.load(PATH)
	items.clear()
	append_items(items_data.get_sections())
	return items

func save_data(path:String = PATH):
	items_data.save(path)

func append_items(items:Array):
	items.sort()
	for item in items:
		if not item in self.items:
			self.items.append(item)
			set_icon(item, get_icon_filename(item))
			set_hidden(item, is_hidden(item))
			set_category(item, get_category(item))
			set_count_min(item, get_count_min(item))
			set_count_low(item, get_count_low(item))
			set_note(item, get_note(item))
	Event.update_items.emit()
	save_data()

func get_items() -> Array:
	return items

func get_note(item:String):
	return items_data.get_value(item,"note", "").strip_edges()

func set_note(item:String, text:String):
	items_data.set_value(item, "note", text)
	save_data()

func get_count_min(item:String) -> int:
	return items_data.get_value(item, "count_min", COUNT_MIN)

func set_count_min(item:String, count:int):
	items_data.set_value(item, "count_min", count)
	save_data()

func get_count_low(item:String) -> int:
	return items_data.get_value(item, "count_low", COUNT_LOW)

func set_count_low(item:String, count:int):
	items_data.set_value(item, "count_low", count)
	save_data()

func get_icon(item:String, size:Vector2i = Vector2i(32,32)) -> ImageTexture:
	var icon_file:String = items_data.get_value(item,"icon", "").strip_edges()
	var path:String
	var image:ImageTexture
	if icon_file in get_icons():
		image = ImageTexture.create_from_image(Image.load_from_file(DIR_ICONS + icon_file))
	else:
		image = ImageTexture.create_from_image(load(UNKNOWN_ICON).get_image())
	image.set_size_override(size)
	return image

func get_icon_by_filename(filename:String, size:Vector2i = Vector2i(32,32)) -> ImageTexture:
	var path:String = DIR_ICONS + filename if filename in get_icons() else UNKNOWN_ICON
	var image = ImageTexture.create_from_image(Image.load_from_file(path))
	
	if filename in get_icons():
		image = ImageTexture.create_from_image(Image.load_from_file(DIR_ICONS + filename))
	else:
		image = ImageTexture.create_from_image(load(UNKNOWN_ICON).get_image())
	
	image.set_size_override(size)
	return image

func get_icon_filename(item:String) -> String:
	var icon_file:String = items_data.get_value(item,"icon", "").strip_edges()
	return icon_file if icon_file in get_icons() else ""

func set_icon(item:String, filename:String):
	items_data.set_value(item, "icon", filename.strip_edges())
	save_data()

func is_hidden(item:String):
	return items_data.get_value(item,"hidden", false)

func set_hidden(item:String, hide:bool):
	items_data.set_value(item, "hidden", hide)
	save_data()

func get_category(item:String):
	return items_data.get_value(item,"category", "").strip_edges()

func set_category(item:String, category:String):
	items_data.set_value(item, "category", category)
	save_data()

static func get_icons() -> Array:
	DirAccess.make_dir_absolute(DIR_ICONS)
	return Array(DirAccess.open(DIR_ICONS).get_files()).filter(func(file:String):
		return RegEx.create_from_string("\\.(jpg|jpeg|png|svg|bmp)$").search(file) )
