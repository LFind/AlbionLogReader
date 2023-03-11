extends HBoxContainer

const SECTION = "table"
const CONFIG_SHOW_HIDDEN = "show_hidden"

@onready var texture_rect = %TextureRect
@onready var button_name = %ButtonName
@onready var button_count = %ButtonCount
@onready var panel_count = $ButtonCount/Panel

@onready var color_min:Color = Settings.get_color_min()
@onready var color_low:Color = Settings.get_color_low()
@onready var color_default:Color = Settings.get_color_default()

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

func _update_settings(key,value):
	if key == Settings.Key.SHOW_HIDDEN:
		_update_visibility()
	elif visible:
		if key == Settings.Key.COLOR_LOW:
			color_low = Settings.get_color_low()
			_update()
		elif key == Settings.Key.COLOR_DEFAULT:
			color_default = Settings.get_color_default()
			_update()
		elif key == Settings.Key.COLOR_MIN:
			color_min = Settings.get_color_min()
			_update()

func _update_visibility():
	visible = item != "" and (not ItemData.is_hidden(item) or Settings.get_show_hidden())
	if visible:
		var hidden_a = 0.7
		modulate.a = hidden_a if ItemData.is_hidden(item) else 1.0

func _update():
	_update_visibility()
	if item != "" and visible:
		self.entries = LogData.get_entries(self.item)
		self.count = LogData.get_item_count(self.item)
		self.last_change = LogData.find_latest_date(self.entries, self.item)
		
		tooltip_text = self.item
		button_name.text = self.item
		button_count.text = str(self.count)
		texture_rect.texture =  ItemData.get_icon(self.item)
		
		if self.count <= ItemData.get_count_min(self.item):
			panel_count.modulate = color_min
		elif self.count <= ItemData.get_count_low(self.item):
			panel_count.modulate = color_low
		else:
			panel_count.modulate = color_default


func set_item(item:String):
	self.item = item
	

