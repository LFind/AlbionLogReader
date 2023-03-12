extends Control

const LABEL_VERSION_TEXT_DEFAULT = "Текущая версия: v{version}"
const LABEL_VERSION_TEXT_LATEST = "Установлена последняя версия: v{version}"
const LABEL_VERSION_TEXT_OLD = "Доступна новая версия: v{version}"
const LABEL_VERSION_TEXT_ERROR = "Ошибка обновления.\nСервер вернул код {response}"

@onready var miss_click_block = %MissClickBlock

@onready var check_search_updates = %CheckSearch
@onready var check_install_updates = %CheckInstall
@onready var button_updates_check = %ButtonSearchUpdates
@onready var label_version = %LabelVersion

@onready var color_picker_default = %ColorPickerDefault
@onready var color_picker_low = %ColorPickerLow
@onready var color_picker_min = %ColorPickerMin

@onready var button_close = %ButtonClose
@onready var button_clear_data = %ButtonClearData

@onready var panel_edit_groups = %PanelEditGroups
@onready var panel_groups = %PanelGroups

const DELAY = 0.15

var data:Dictionary
var item:String
var icon_filename:Dictionary
var icon_unknown = ImageTexture.create_from_image(Image.load_from_file(ItemData.UNKNOWN_ICON))
var timer_delay = Timer.new()

#TODO меню настроек
func _ready():
	visible = false
	panel_edit_groups.visible = false
	panel_groups.visible = true
	
	# Открытие и закрытие панели
	Event.request_window_settings.connect(_on_window_request)
	button_close.pressed.connect(_on_close_requested)
	
	# Проверка обновлений
	UpdateChecker.search_start.connect(_on_search_updates_start)
	UpdateChecker.search_end.connect(_on_search_updates_end)
	check_search_updates.toggled.connect(Settings.set_search_update_on_launch)
	check_install_updates.toggled.connect(Settings.set_download_update)
	button_updates_check.pressed.connect(UpdateChecker.check_updates)
	label_version.text = LABEL_VERSION_TEXT_DEFAULT.format({
		"version": Settings.VERSION
	})
	
	# Выбор цветов для предметов
	color_picker_default.popup_closed.connect(func(): Settings.set_color_default(color_picker_default.color))
	color_picker_low.popup_closed.connect(func(): Settings.set_color_low(color_picker_low.color))
	color_picker_min.popup_closed.connect(func(): Settings.set_color_min(color_picker_min.color))
	
	# Защита от случайного удаления логов
	button_clear_data.disabled = true
	button_clear_data.pressed.connect(LogData.clear_log)
	
	# Защита от мисскликов при открытии
	add_child(timer_delay)
	timer_delay.autostart = false
	timer_delay.timeout.connect(miss_click_block.set_visible.bind(false))
	
	# Обработка открытия редактора группы
	panel_edit_groups.visibility_changed.connect(func():
		var visible = panel_edit_groups.visible
		button_close.visible = !visible
		button_clear_data.visible = !visible
		panel_groups.visible = !visible
		)

func _on_search_updates_start():
	button_updates_check.disabled = true

func _on_search_updates_end():
	match UpdateChecker.get_status():
		UpdateChecker.STATUS_LATEST:
			label_version.text = LABEL_VERSION_TEXT_LATEST.format({
				"version": Settings.VERSION
			})
		UpdateChecker.STATUS_OLD:
			label_version.text = LABEL_VERSION_TEXT_OLD.format({
				"version": UpdateChecker.get_latest_version()
			})
		UpdateChecker.STATUS_UNKNOWN:
			label_version.text = LABEL_VERSION_TEXT_OLD.format({
				"response": UpdateChecker.get_response()
			})
	
	button_updates_check.disabled = false

func _update():
	pass

func _release_focus():
	var focused_node:Control = get_window().gui_get_focus_owner()
	if focused_node:
		focused_node.release_focus()

func _on_window_request():
	set_visible(true)
	miss_click_block.set_visible(true)
	timer_delay.start(DELAY)
	
	color_picker_default.color = Settings.get_color_default()
	color_picker_low.color = Settings.get_color_low()
	color_picker_min.color = Settings.get_color_min()
	
	check_search_updates.button_pressed = Settings.get_search_update_on_launch()
	check_install_updates.button_pressed = Settings.get_download_update()

func _unhandled_input(event):
	if event.is_action("ui_mouse_left"):
		_release_focus()
	if event.is_action("ui_unlock"):
		# Блокировка кнопки удаления
		button_clear_data.disabled = not event.is_action_pressed("ui_unlock", true)

func _on_close_requested():
	set_visible(false)
