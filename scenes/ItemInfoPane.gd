@tool
extends Panel

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

var data:Dictionary:
	set(value):
		data = value
		_update()

func _ready():
	var item_lists := []
	var header_group:ButtonGroup = ButtonGroup.new()
	
	for type in columns:
		var column = columns[type]
		var button:Button = column["header"]
		var item_list:ItemList = column["items"]
		button.button_group = header_group
		
		var update_column_size = func():
			item_list.custom_minimum_size.x = button.size.x
		
		button.resized.connect(update_column_size)
		
		item_lists.append(item_list)
		
		item_list.item_selected.connect(func(index:int):
			for l in item_lists:
				if l != item_list:
					l.select(index)
			)
		

func _process(delta):
	header_container.position.x = item_list_container.position.x

func _update():
	player_list.clear()
	for player in LogData.get_unique_players(data):
		player_list.add_item(player)
	
	for column in columns.values():
		column["items"].clear()
	
	for date in data.keys():
		for entry in data[date]:
			columns["date"]["items"].add_item(date)
			columns["player"]["items"].add_item(entry["player"])
			columns["char"]["items"].add_item(str(entry["char"]))
			columns["item"]["items"].add_item(entry["item"])
			columns["quality"]["items"].add_item(str(entry["quality"]))
			columns["countDelta"]["items"].add_item(str(entry["countDelta"]))
			
			

func set_item(item_name:String):
	self.data = LogData.get_entries(item_name)
