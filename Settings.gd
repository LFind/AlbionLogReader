extends Node
#TODO Меню общих настроек
enum Key {
	SHOW_HIDDEN
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

func get_show_hidden() -> bool:
	return get_value("show_hidden", false)

func set_show_hidden(value:bool):
	set_value("show_hidden", value)
	Event.update_settings.emit(Key.SHOW_HIDDEN, value)
