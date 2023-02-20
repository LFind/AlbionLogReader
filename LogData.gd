extends Node

var log_data:Dictionary:
	set(value):
		log_data = value
		Event.items_update.emit()
const PATH:String = "log.json"
var files:Dictionary = {}


func is_valid_log_string(log_string: String) -> bool:
	var parts := log_string.split("\t")
	RegEx.create_from_string("").search("").get_string()
	if parts.size() != 6:
		return false
	if not RegEx.create_from_string("[0-9]{2}/[0-9]{2}/[0-9]{4} [0-9]{2}:[0-9]{2}:[0-9]{2}").search(parts[0]):
		return false
	if len(parts[1]) == 0:
		return false
	if len(parts[2]) == 0:
		return false
	if not RegEx.create_from_string("^[0-9]+$").search(str(int(parts[3]))):
		return false
	if not RegEx.create_from_string("^[1-9]+$").search(str(int(parts[4]))):
		return false
	if not RegEx.create_from_string("^-?[0-9]+$").search(str(int(parts[5]))):
		return false
	return true


func parse(logString: String) -> Dictionary:
	var logs = {}
	
	# Разделяем строку на строки по символу переноса строки
	var logs_lines = logString.split("\n")
	
	# Обходим все строки логов и создаем словари для каждой даты
	for line in logs_lines:
		
		# Игнорирование всего, что не является строкой логов
		if not is_valid_log_string(line):
			continue
		
		# Разделяем строку на поля
		var fields = []
		
		# Игнорируем пустые строки или строки без нужного числа полей

		
		for field in  line.split("\t"):
			field.strip_escapes()
			if field[0] == "\"" and field[-1]  == "\"":
				field = field.rstrip("\"").lstrip("\"")
			fields.append(field)
		
		if fields.size() != 6:
			continue
		
		var date = fields[0]
		
		# Если для текущей даты еще нет словаря в списке логов, то создаем его
		if not logs.has(date):
			logs[date] = []
		
		# Добавляем текущую строку в словарь логов для текущей даты
		logs[date].append({
			"player": fields[1],
			"item": fields[2],
			"char": int(fields[3]),
			"quality": int(fields[4]),
			"countDelta": int(fields[5])
		})
	return logs

func append_logs(logs_new: Dictionary) -> Dictionary:
	var merged_logs = {}
	
	# Обходим все даты из первого словаря
	for date in log_data.keys():
		var log_data_entries = log_data[date]
		var logs_new_entries = []
		
		# Если дата есть и во втором словаре, то получаем ее записи
		if logs_new.has(date):
			logs_new_entries = logs_new[date]
		
		# Сравниваем число записей в каждом словаре и выбираем дату с наибольшим числом записей
		if log_data_entries.size() > logs_new_entries.size():
			merged_logs[date] = log_data_entries
		else:
			merged_logs[date] = logs_new_entries
	
	# Добавляем все даты из второго словаря, которых нет в первом
	for date in logs_new.keys():
		if not merged_logs.has(date):
			merged_logs[date] = logs_new[date]
	
	log_data = merged_logs
	Event.items_update.emit()
	save_log(PATH)
	return merged_logs


func save_log(path:String):
	var file = FileAccess.open(path,FileAccess.WRITE)
	file.store_string(str(log_data))
	file.flush()


func load_log(path:String) -> Dictionary:
	var data:Dictionary = {}
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path,FileAccess.READ)
		var text_value = file.get_as_text()
		if text_value:
			data = str_to_var(text_value)
		file.flush()
	self.log_data = data
	return data


func get_item_count(item_name: String, char: int = 0) -> int:
	var count_delta_sum = 0
	
	# Обходим все записи в словаре
	for date in log_data.keys():
		for entry in log_data[date]:
			if entry["item"] == item_name:
				if char > 0:
					if entry["char"] == char:
						count_delta_sum += entry["countDelta"]
				else:
					count_delta_sum += entry["countDelta"]
	
	return count_delta_sum


func get_entries(item_name: String, player: String = "", char: int = -1, quality: int = -1) -> Dictionary:
	var entries = {}
	
	# Обходим все записи в словаре
	for date in log_data.keys():
		var date_entries = log_data[date]
		for entry in date_entries:
			if entry["item"] == item_name:
				# Проверяем, удовлетворяет ли запись запрошенным параметрам
				if player != "" and entry["player"] != player:
					continue
				if char > -1 and entry["char"] != char:
					continue
				if quality > -1 and entry["quality"] != quality:
					continue
				
				# Добавляем запись в словарь
				if date not in entries:
					entries[date] = [entry]
				else:
					entries[date].append(entry)
	
	return entries


func merge_logs(logs: Dictionary) -> Array:
	var merged = {}
	
	for date in logs:
		for entry in logs[date]:
			var player = entry["player"]
			var quality = entry["quality"]
			var char = entry["char"]
			var item =  entry["item"]
			var key = str(player) + str(quality) + str(char) + str(item)
		
			if not merged.has(key):
				merged[key] = {
					"player": player,
					"item": item,
					"char": char,
					"quality": quality,
					"countDelta": entry["countDelta"]
				}
			else:
				merged[key]["countDelta"] += entry["countDelta"]
	
	return merged.values()


func get_existing_items(logs:Dictionary) -> Array:
	var existing_items = []
	for entry_list in logs.values():
		for entry in entry_list:
			if entry["item"] not in existing_items:
				existing_items.append(entry["item"])
	return existing_items
