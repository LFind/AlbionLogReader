extends HBoxContainer

const COLOR_MIN:Color = Color("703030")
const COLOR_LOW:Color = Color("823f00")
const COLOR_NORMAL:Color = Color("363636")

const SECTION = "table"
const CONFIG_SHOW_HIDDEN = "show_hidden"

@onready var texture_rect = %TextureRect
@onready var button_name = %ButtonName
@onready var button_count = %ButtonCount
@onready var panel_count = $ButtonCount/Panel

var entries:Dictionary
var item:String:
	set(value):
		item = value
		update.emit()
var count:int
var last_change:Dictionary
var icon:ImageTexture

signal update


func _ready():
	button_name.pressed.connect(func():
		Event.request_window_item_info.emit(self.item)
		)
	Event.update_settings.connect(_update_settings)
	Event.update_item_settings.connect(func(item_name): if item_name == self.item: update.emit())
	panel_count.get_theme_stylebox("panel")
	update.connect(_update)
	_update()

func _update_settings(section, key, value):
	if section != SECTION: return
	match key:
		CONFIG_SHOW_HIDDEN: visible = not ItemData.is_hidden(item) or value

func _update():
	if item != "":
		self.entries = LogData.get_entries(self.item)
		self.count = LogData.get_item_count(self.item)
		self.last_change = LogData.find_latest_date(self.entries, self.item)
		
		tooltip_text = self.item
		button_name.text = self.item
		button_count.text = str(self.count)
		texture_rect.texture =  ItemData.get_icon(self.item)
		
		visible = not ItemData.is_hidden(item) or Settigs.get_value(SECTION, CONFIG_SHOW_HIDDEN, true)
		
		if self.count <= ItemData.get_count_min(self.item):
			panel_count.modulate = COLOR_MIN
		elif self.count <= ItemData.get_count_low(self.item):
			panel_count.modulate = COLOR_LOW
		else:
			panel_count.modulate = COLOR_NORMAL
	

func set_item(item:String):
	self.item = item
	

