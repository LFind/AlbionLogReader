extends Node
#TODO Меню общих настроек
enum Key {
	SHOW_HIDDEN,
	SEARCH_UPDATE_ON_LAUNCH,
	DOWNLOAD_UPDATE,
	COLOR_MIN,
	COLOR_LOW,
	COLOR_DEFAULT,
}

const TITLE = "AlbionLogReader"
const VERSION = "0.8b"
const PATH = "config.ini"

var config:ConfigFile = ConfigFile.new()
 

func _ready():
	load_config()
	get_window().title = "{title} v.{version}".format({"title":TITLE, "version":VERSION})

func save_config(path:String = PATH):
	config.save(path)

func load_config(path:String = PATH):
	config.load(PATH)

func set_value(key: String, value):
	key = key.to_lower()
	config.set_value("", key, value)
	save_config()

func get_value(key: String, default = null):
	key = key.to_lower()
	if not config.has_section_key("", key):
		config.set_value("", key, default)
		save_config()
		return default
	return config.get_value("", key, default)

func get_color_default() -> Color:
	var color_str = "363636"
	return Color.from_string(get_value("color_default", color_str), Color(color_str))

func set_color_default(value:Color):
	set_value("color_default", value.to_html(true))
	Event.update_settings.emit(Key.COLOR_DEFAULT, value)

func get_color_low() -> Color:
	var color_str = "823f00"
	return Color.from_string(get_value("color_low", color_str), Color(color_str))

func set_color_low(value:Color):
	set_value("color_low", value.to_html(true))
	Event.update_settings.emit(Key.COLOR_LOW, value)

func get_color_min() -> Color:
	var color_str = "703030"
	return Color.from_string(get_value("color_min", color_str), Color(color_str))

func set_color_min(value:Color):
	set_value("color_min", value.to_html(true))
	Event.update_settings.emit(Key.COLOR_MIN, value)

func get_download_update() -> bool:
	return get_value("download_update", false)

func set_download_update(value:bool):
	set_value("download_update", value)
	Event.update_settings.emit(Key.DOWNLOAD_UPDATE, value)

func get_search_update_on_launch() -> bool:
	return get_value("search_update_on_launch", false)

func set_search_update_on_launch(value:bool):
	set_value("search_update_on_launch", value)
	Event.update_settings.emit(Key.SEARCH_UPDATE_ON_LAUNCH, value)

func get_show_hidden() -> bool:
	return get_value("show_hidden", false)

func set_show_hidden(value:bool):
	set_value("show_hidden", value)
	Event.update_settings.emit(Key.SHOW_HIDDEN, value)
