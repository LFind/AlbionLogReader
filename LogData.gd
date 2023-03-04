extends Node

var log_data:Dictionary:
	set(value):
		log_data = sort_by_date(value)
		Event.update_logs.emit()
const PATH:String = "log.json"
var files:Dictionary = {}


func _ready():
	load_log(PATH)

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
	
	self.log_data = merged_logs
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
	save_log(PATH)
	return data


func get_item_count(item_name: String) -> int:
	var count_delta_sum = 0
	
	for entries in log_data.values():
		for entry in entries:
			if entry["item"] == item_name:
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
	
	return entries.duplicate(true)


func get_unique_items(logs:Dictionary) -> Array:
	var existing_items = []
	for entry_list in logs.values():
		for entry in entry_list:
			if entry["item"] not in existing_items:
				existing_items.append(entry["item"])
	return existing_items


func get_unique_players(logs:Dictionary) -> Array[String]:
	var unique_players:Array[String]
	for entries in logs.values():
		for entry in entries:
			if entry["player"] not in unique_players:
				unique_players.append(entry["player"])
	return unique_players


func date_to_dict(datetime:String) -> Dictionary:
	datetime = datetime.strip_edges()
	if datetime == "": return {
		"year": -1,
		"month": -1,
		"day": -1,
		"hour": -1,
		"minute": -1,
		"second": -1
	}
	
	var split_str = datetime.split(" ")
	var date = split_str[0]
	var time = split_str[1]
	var date_split = date.split("/")
	var year = date_split[2].to_int()
	var month = date_split[0].to_int()
	var day = date_split[1].to_int()
	var time_split = time.split(":")
	var hour = time_split[0].to_int()
	var minute = time_split[1].to_int()
	var second = time_split[2].to_int()
	return {
		"year": year,
		"month": month,
		"day": day,
		"hour": hour,
		"minute": minute,
		"second": second
	}

func compare_datetime(date1, date2) -> bool:
	var result:int
	if not date1 is Dictionary:
		date1 = date_to_dict(date1)
	if not date2 is Dictionary:
		date2 = date_to_dict(date2)
	if date1.get("year", 0) == date2.get("year", 0):
		if date1.get("month", 0) == date2.get("month", 0):
			if date1.get("day", 0) == date2.get("day", 0):
				if date1.get("hour", 0) == date2.get("hour", 0):
					if date1.get("minute", 0) == date2.get("minute", 0):
						result = date1.get("second", 0) - date2.get("second", 0)
					else:
						result = date1.get("minute", 0) - date2.get("minute", 0)
				else:
					result = date1.get("hour", 0) - date2.get("hour", 0)
			else:
				result = date1.get("day", 0) - date2.get("day", 0)
		else:
			result = date1.get("month", 0) - date2.get("month", 0)
	else:
		result = date1.get("year", 0) - date2.get("year", 0)
	
	return result > 0
	

func find_latest_date(log_data:Dictionary, item:String = "") -> Dictionary:
	var lastest_datetime: Dictionary = date_to_dict("")
	var last_datetime: Dictionary = lastest_datetime
	for datetime in log_data.keys():
		for entry in log_data[datetime]:
			if item == "" or entry["item"] == item:
				var current_datetime = date_to_dict(datetime)
				if compare_datetime(current_datetime, last_datetime):
					last_datetime = current_datetime
					lastest_datetime = entry
	
	return last_datetime

func remove_all_entries(item:String):
	var log_data = self.log_data.duplicate()
	for date in log_data.keys():
		var entries = log_data[date].filter(func(e): return e["item"] != item)
		
		if entries.size() > 0:
			log_data[date] = entries
		else:
			log_data.erase(date)
		
	
	self.log_data = log_data
	save_log(PATH)
	Event.removed_all_entries.emit(item)

func sort_by_date(logs:Dictionary) -> Dictionary:
	var sorted_logs:Dictionary
	
	var keys_arr = logs.keys()
	
	for key in keys_arr:
		sorted_logs[key] = logs[key]
	
	return sorted_logs
