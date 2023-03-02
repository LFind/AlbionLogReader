extends Node
#TODO Меню общих настроек
enum Section {
	TABLE
}

const PATH = "config.ini"

var config:ConfigFile = ConfigFile.new()
 

func _ready():
#	add_child(preload("res://scenes/WindowGlobalSettings.tscn").instantiate())
	load_config()

func save_config(path:String = PATH):
	config.save(path)

func load_config(path:String = PATH):
	config.load(PATH)

func set_value(section: String, key: String, value: Variant):
	section = section.to_upper()
	key = key.to_lower()
	config.set_value(section, key, value)
	Event.update_setting.emit(section, key, value)
	save_config()

func get_value(section: String, key: String, default: Variant = null):
	section = section.to_upper()
	key = key.to_lower()
	if not config.has_section_key(section, key):
		config.set_value(section, key, default)
		save_config()
		return default
	return config.get_value(section, key, default)
