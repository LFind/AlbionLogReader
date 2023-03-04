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

@onready var search_field_player = %SearchField
@onready var player_list = %PlayerList
@onready var button_clear_player_select = $TablePanel/VBoxLeft/PlayerContainer/HBoxContainer/ButtonClearPlayerSelect

@onready var button_settings = $TablePanel/VBoxLeft/ButtonSettings

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

var players:Array[String]
var players_selected:Array[String]
var item:String:
	set(value):
		item = value
		_update_table()
		
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
			spin_box_begin_dd.value = date_min["day"]
			spin_box_begin_mm.value = date_min["month"]
			spin_box_begin_yy.value = date_min["year"]
			spin_box_end_dd.value = date_max["day"]
			spin_box_end_mm.value = date_max["month"]
			spin_box_end_yy.value = date_max["year"]
		
var is_ready:bool
var count:int
var data:Dictionary


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
	
	# Логика при со списоком игроков
	player_list.item_selected.connect(func(index:int):
		players_selected.clear()
		# FIXME Множественный выбор игроков
		for i in player_list.get_selected_items():
			players_selected.append(player_list.get_item_text(i))
		_update_table()
		)
	button_clear_player_select.pressed.connect(func():
		players_selected.clear()
		player_list.deselect_all()
		_update_table()
		)
	
	search_field_player.text_changed.connect(func(text:String):_update_players())
	button_settings.pressed.connect(_request_window_item_options)
	
	# Изменение визуала внутренних нод в спинбоксах
	for spin_box in [spin_box_begin_dd,spin_box_begin_mm,spin_box_begin_yy,spin_box_end_dd,spin_box_end_mm,spin_box_end_yy]:
		var spin_textedit:LineEdit
		for node in spin_box.get_children(true):
			if node is LineEdit:
				spin_textedit = node
		spin_textedit.alignment = HORIZONTAL_ALIGNMENT_CENTER
		spin_textedit.size.x = 20
	
	Event.removed_all_entries.connect(func(item): if self.item == item: set_item(item))

func _process(delta):
	header_container.position.x = item_list_container.position.x

func _update_players():
	var search_player:String = search_field_player.get_text().strip_edges().to_lower()
	
	player_list.clear()
	for player in players:
		if search_player != "" and not search_player in player.strip_edges().to_lower():
			continue
		player_list.add_item(player)
	
	for i in range(player_list.get_item_count()):
		if player_list.get_item_text(i) in players_selected:
			player_list.select(i,false)
	
	player_list.sort_items_by_text()

func _update_table():
	self.data = LogData.get_entries(item)
	players = LogData.get_unique_players(data)
	
	var data_filtred = data.duplicate(true)
	count = 0
	
	# Выключение выбора диапозона дат
	for spin_box in [spin_box_begin_dd,spin_box_begin_mm,spin_box_begin_yy]:
		spin_box.get_line_edit().editable = check_box_date_begin.button_pressed
	
	for spin_box in [spin_box_end_dd,spin_box_end_mm,spin_box_end_yy]:
		spin_box.get_line_edit().editable = check_box_date_end.button_pressed
	
	# Очистка каждого столбца
	for column in columns.values():
		column["items"].clear()
	
	for date in data_filtred.keys():
		var valid_end:bool = true
		var valid_begin:bool = true
		var valid_player:bool = true
		
		# Проверка на соответствие фильтра начальной даты
		if check_box_date_begin.button_pressed:
			if LogData.compare_datetime({
				"year": spin_box_begin_yy.value,
				"month": spin_box_begin_mm.value,
				"day": spin_box_begin_dd.value,
				"hour": 0,
				"minute": 0,
				"second": 0
			},date): continue
		
		# Проверка на соответствие фильтра конечной даты
		if check_box_date_end.button_pressed:
			if LogData.compare_datetime(date, {
				"year": spin_box_end_yy.value,
				"month": spin_box_end_mm.value,
				"day": spin_box_end_dd.value,
				"hour": 23,
				"minute": 59,
				"second": 59
			}): continue
		
		# Фильтрация по данным записи
		data_filtred[date] = data_filtred[date].filter(func(entry:Dictionary):
			# По игроку
			if players_selected.size() > 0:
				if not entry["player"] in players_selected:
					return false
			return true
			)
		
		# Выставление данных логов
		for entry in data_filtred[date]:
			columns["date"]["items"].add_item(date)
			columns["player"]["items"].add_item(entry["player"])
			columns["char"]["items"].add_item(str(entry["char"]))
			columns["item"]["items"].add_item(entry["item"])
			columns["quality"]["items"].add_item(str(entry["quality"]))
			count += entry["countDelta"]
			columns["countDelta"]["items"].add_item(str(entry["countDelta"]))
	
	_update_players()

func _request_window_item_options():
	Event.request_window_item_options.emit(item)

func _release_focus():
	var focused_node:Control = get_window().gui_get_focus_owner()
	if focused_node:
		search_field_player.release_focus()

func _unhandled_input(event):
	if event.is_action("ui_mouse_left"):
		_release_focus()

func set_item(item:String):
	self.item = item

