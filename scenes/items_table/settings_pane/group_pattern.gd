extends HBoxContainer

@onready var item_selector = %ItemSelector
@onready var spin_box_char = %SpinBoxChar
@onready var spin_box_quality = %SpinBoxQuality
@onready var button_delete = %ButtonDelete
@onready var warn = %Warn

func _ready():
	for item in ItemData.get_items():
		item_selector.add_item(item)
	item_selector.remove_item(0)
	button_delete.pressed.connect(queue_free)
	item_selector.item_selected.connect(func(_id):
		item_selector.tooltip_text = item_selector.text
		warn.visible = false
		)

func _unhandled_input(event):
	if event.is_action("ui_unlock"):
		# Блокировка кнопки удаления
		button_delete.disabled = not event.is_action_pressed("ui_unlock", true)

func set_item(item:Dictionary):
	warn.visible = false
	item_selector.text = item["item"]
	spin_box_char.value = item["char"]
	spin_box_quality.value = item["quality"]

func get_item_name() -> String:
	return item_selector.text

func get_char() -> int:
	return int(spin_box_char.value)

func get_quality() -> int:
	return int(spin_box_quality.value)

func is_selected() -> bool:
	return item_selector.get_selected_id() != -1 or item_selector.text != ""
