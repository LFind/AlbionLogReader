extends Node



var config:ConfigFile = ConfigFile.new()

func _ready():
	if config.load("config.ini") != OK:
		config.set_value("ItemInfo", "")
	config.set_value()
