@tool
extends Panel

@export var header_max_size:float = 500:
	set(value):
		header_max_size = value
		if is_ready:
			for type in columns:
				var column = columns[type]
				var button:Button = column["header"]
				
				button.resized.emit()

@onready var check_box_date_begin = %CheckBoxDateBegin
@onready var check_box_date_end = %CheckBoxDateEnd

@onready var spin_box_begin_dd = %SpinBoxBeginDD
@onready var spin_box_begin_mm = %SpinBoxBeginMM
@onready var spin_box_begin_yy = %SpinBoxBeginYY
@onready var spin_box_end_dd = %SpinBoxEndDD
@onready var spin_box_end_mm = %SpinBoxEndMM
@onready var spin_box_end_yy = %SpinBoxEndYY

@onready var check_date = %CheckDate
@onready var check_item = %CheckItem
@onready var check_char = %CheckChar
@onready var check_quality = %CheckQuality
@onready var check_count = %CheckCount
@onready var check_player = %CheckPlayer

@onready var player_list = %PlayerList
@onready var item_list_container = %ItemListContainer
@onready var header_container = %HeaderContainer
@onready var table = %Table
@onready var scroll_table = %ScrollTable
@onready var columns:Dictionary = {
	"date": {
			"header": %ButtonDate,
			"items": %ItemDate
		},
	"player": {
			"header": %ButtonPlayer,
			"items": %ItemPlayer,
		},
	"item": {
			"header": %ButtonItem,
			"items": %ItemName,
		},
	"char": {
			"header": %ButtonChar,
			"items": %ItemChar,
		},
	"quality": {
			"header": %ButtonQuality,
			"items": %ItemQuality,
		},
	"countDelta": {
			"header": %ButtonCount,
			"items": %ItemCount,
		}
}

var is_ready:bool

var data:Dictionary:
	set(value):
		data = value
		
		# Выставление заглушек на выборе диапозона дат
		var date_min:Dictionary
		var date_max:Dictionary
		
		for date in data.keys():
			date = LogData.date_to_dict(date)
			if date_max == {} or LogData.compare_datetime(date, date_min):
				date_max = date
			if date_min == {} or not LogData.compare_datetime(date, date_min):
				date_min = date
		
		if date_min != {} and date_min != {}:
			spin_box_begin_dd.get_line_edit().text = str(date_min["day"])
			spin_box_begin_mm.get_line_edit().text = str(date_min["month"])
			spin_box_begin_yy.get_line_edit().text = str(date_min["year"])
			spin_box_end_dd.get_line_edit().text = str(date_max["day"])
			spin_box_end_mm.get_line_edit().text = str(date_max["month"])
			spin_box_end_yy.get_line_edit().text = str(date_max["year"])
			
		_update_table()


func _ready():
	is_ready = true
	var item_lists := []
	var header_group:ButtonGroup = ButtonGroup.new()
	header_container.custom_minimum_size.x = (header_max_size*5)+100
	
	# Логика работы колонок в таблице логов
	for type in columns:
		var column = columns[type]
		var button:Button = column["header"]
		var item_list:ItemList = column["items"]
		button.button_group = header_group
		
		# Растягивание столбцов
		button.resized.connect(func():
			button.size.x = clamp(button.size.x, 0, header_max_size)
			if item_list == columns["date"]["items"]:
				item_list.custom_minimum_size.x = button.size.x + 4
			else:
				item_list.custom_minimum_size.x = button.size.x + 8)
		button.get_parent().dragged.connect(func(offset:int):
			button.get_parent().split_offset = clamp(offset, 0, header_max_size)
			)
		
		item_lists.append(item_list)
		
		item_list.item_selected.connect(func(index:int):
			for l in item_lists:
				if l != item_list:
					l.select(index)
			)
		
		# Отключение столбцов
			
		for check_button in [check_player,check_char,check_count,check_date,check_item,check_quality]:
			var update_columns_visivility = func(button_pressed:bool = true):
				for node in columns[check_button.get_meta("type")].values():
					node.visible = button_pressed
			check_button.toggled.connect(update_columns_visivility)
			update_columns_visivility.call(check_button.button_pressed)
	
	# Логика при работе с диапазоном дат
	for check_box in [check_box_date_begin,check_box_date_end]:
		check_box.pressed.connect(_update_table)
	
	for spin_box in [spin_box_begin_dd,spin_box_begin_mm,spin_box_begin_yy,spin_box_end_dd,spin_box_end_mm,spin_box_end_yy]:
		spin_box.value_changed.connect(func(value):
			_update_table()
			)
	



func _process(delta):
	header_container.position.x = item_list_container.position.x


func _update_table():
	player_list.clear()
	for player in LogData.get_unique_players(data):
		player_list.add_item(player)
	
	for column in columns.values():
		column["items"].clear()
	
	
	
	for date in data.keys():
		var valid_end:bool = true
		
		var valid_begin:bool = true
		if check_box_date_begin.button_pressed:
			valid_begin = LogData.compare_datetime(date,{
				"year": spin_box_begin_yy.value,
				"month": spin_box_begin_mm.value,
				"day": spin_box_begin_dd.value,
				"hour": 0,
				"minute": 0,
				"second": 0
			})
			
		
		if check_box_date_end.button_pressed:
			valid_end = LogData.compare_datetime({
				"year": spin_box_end_yy.value,
				"month": spin_box_end_mm.value,
				"day": spin_box_end_dd.value,
				"hour": 0,
				"minute": 0,
				"second": 0
			},date)
		
		if not (valid_begin and valid_end): continue
		
		for entry in data[date]:
			columns["date"]["items"].add_item(date)
			columns["player"]["items"].add_item(entry["player"])
			columns["char"]["items"].add_item(str(entry["char"]))
			columns["item"]["items"].add_item(entry["item"])
			columns["quality"]["items"].add_item(str(entry["quality"]))
			columns["countDelta"]["items"].add_item(str(entry["countDelta"]))
	
	# Изменение внутренних нод в спинбоксах
	for spin_box in [spin_box_begin_dd,spin_box_begin_mm,spin_box_begin_yy,spin_box_end_dd,spin_box_end_mm,spin_box_end_yy]:
		var spin_textedit:LineEdit
		for node in spin_box.get_children(true):
			if node is LineEdit:
				spin_textedit = node
		spin_textedit.alignment = HORIZONTAL_ALIGNMENT_CENTER
		spin_textedit.size.x = 20
	



func _unhandled_input(event):
	if event.is_action("ui_mouse_left"):
		var focused_node:Control = get_window().gui_get_focus_owner()
		if focused_node:
			focused_node.release_focus()


func set_item(item_name:String):
	self.data = LogData.get_entries(item_name)

