extends Object
class_name ItemGroup

const PATH = "groups.json"

var _is_saved:bool = false
var items_pattern:Array[Dictionary]
var group_name:String


func _init(group_name:String):
	get_groups().append(self)
	self.group_name = group_name

func add_item(item:String, char:int=-1, quality:int = -1):
	if not has_item(item, char, quality):
		# Добавление предмета если нет
		var item_dict = {
			"item": item,
			"char": char,
			"quality": quality,
		}
		item_dict.make_read_only()
		items_pattern.append(item_dict)
		Event.group_update_items.emit(get_name())

func remove_item(item:String, char:int=-1, quality:int = -1):
	if has_item(item, char, quality):
		var new_items_pattern = items_pattern.duplicate()
		for pattern in items_pattern:
			if pattern["item"] == item and pattern["char"] == char and pattern["quality"] == quality:
				new_items_pattern.erase(pattern)
				break
		items_pattern = new_items_pattern
		Event.group_update_items.emit(get_name())

func clear_items():
	items_pattern.clear()
	Event.group_update_items.emit(get_name())

func has_item(item:String, char:int=-1, quality:int = -1) -> bool:
	return items_pattern.any(func(i):
		# Проверка наличия предемета в группе
		return  i["item"] == item and i["char"] == char and i["quality"] == quality
		)

func get_entries() -> Dictionary:
	var entries = {}
	
	var combine_entries = func(entries1, entries2):
		var merged_entries = {}
	
		# Обходим все даты из первого словаря
		for date in entries1.keys():
			var entries1_list = entries1[date]
			var entries2_list = []
			
			# Если дата есть и во втором словаре, то получаем ее записи
			if entries2.has(date):
				entries2_list = entries2[date]
			
			# Сравниваем число записей в каждом словаре и выбираем дату с наибольшим числом записей
			if entries1_list.size() > entries2_list.size():
				merged_entries[date] = entries1_list
			else:
				merged_entries[date] = entries2_list
		
		# Добавляем все даты из второго словаря, которых нет в первом
		for date in entries2.keys():
			if not merged_entries.has(date):
				merged_entries[date] = entries2[date]
		
		return merged_entries
	
	for item in get_items():
		entries = combine_entries.call(entries, LogData.get_entries(item["item"], "", item["char"], item["quality"]))
	
	return entries

func get_items() -> Array[Dictionary]:
	return items_pattern

func set_name(group_name:String):
	self.group_name = group_name

func get_name() -> String:
	return group_name

func delete():
	ItemData.item_groups.erase(self)
	save_groups()
	Event.group_deleted.emit(self)

func is_saved() -> bool:
	return _is_saved

static func get_group(group_name:String) -> ItemGroup:
	for group in get_groups():
		if group.get_name() == group_name:
			return group
	return null

static func get_groups() -> Array[ItemGroup]:
	return ItemData.item_groups

static func get_group_names() -> Array:
	return get_groups().map(func(group):
		return group.get_name()
		)

static func save_groups():
	var file = FileAccess.open(PATH,FileAccess.WRITE)
	file.store_string(str(groups_to_dict(get_groups())))
	file.flush()
	Event.groups_saved.emit()
	for group in get_groups():
		group._is_saved = true

static func load_groups():
	var groups:Array[ItemGroup]
	ItemData.item_groups.clear()
	if FileAccess.file_exists(PATH):
		var file = FileAccess.open(PATH,FileAccess.READ)
		var text_value = file.get_as_text()
		if text_value:
			groups.append_array(dict_to_groups(str_to_var(text_value)))
		file.flush()
	ItemData.item_groups = groups
	for group in groups:
		group._is_saved = true

static func groups_to_dict(groups:Array[ItemGroup]) -> Dictionary:
	var groups_dict:Dictionary
	for group in groups:
		groups_dict[group.group_name] = group.items_pattern
	return groups_dict

static func dict_to_groups(dict:Dictionary) -> Array[ItemGroup]:
	var groups:Array[ItemGroup]
	for name in dict.keys():
		var group = ItemGroup.new(name)
		var items_pattern:Array[Dictionary]
		items_pattern.append_array(dict[name])
		group.items_pattern = items_pattern
		for item in group.items_pattern:
			item.make_read_only()
		groups.append(group)
	return groups

