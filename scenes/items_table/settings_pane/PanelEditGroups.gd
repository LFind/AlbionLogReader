extends Panel

const TITLE_TEXT = "Изменить группу \"{name}\""
const MIN_CHARS = 3

var pattern_scene = preload("res://scenes/items_table/settings_pane/group_pattern.tscn")

@onready var title = %Title
@onready var line_group_name = %LineGroupName
@onready var container_group_patterns = %ContainerGroupPatterns
@onready var button_save_group = %ButtonSaveGroup
@onready var button_create_pattern = %ButtonCreatePattern
@onready var button_cancel = %ButtonCancel

var group:ItemGroup:
	set(value):
		group = value
		_update()

func _ready():
	button_cancel.pressed.connect(func(): 
		visible = false
		if not group.is_saved():
			group.delete()
		)
	button_save_group.pressed.connect(save_group)
	button_create_pattern.pressed.connect(func():
		var last_index = container_group_patterns.get_child_count()-1
		if last_index >= 0:
			if container_group_patterns.get_child(container_group_patterns.get_child_count()-1).is_selected():
				container_group_patterns.add_child(pattern_scene.instantiate())
		else:
			container_group_patterns.add_child(pattern_scene.instantiate())
		)
	
	line_group_name.text_change_rejected.connect(_on_name_changed)
	line_group_name.text_changed.connect(_on_name_changed)
	line_group_name.text_submitted.connect(_on_name_changed)

func _on_name_changed(text:String):
	text = text.strip_edges()
	title.set_text(TITLE_TEXT.format({"name": text}))
	if text != group.group_name:
		if text.length() < MIN_CHARS:
			button_save_group.disabled = true
			button_save_group.tooltip_text = "Минимальная длина названия: {count} символа".format({"count": MIN_CHARS})
		elif text in ItemGroup.get_group_names():
			button_save_group.disabled = true
			button_save_group.tooltip_text = "Группа уже существует"
		else:
			button_save_group.disabled = false
			button_save_group.tooltip_text = ""
	else:
		button_save_group.disabled = false
		button_save_group.tooltip_text = ""

func set_group(group:ItemGroup):
	if group:
		self.group = group
	else:
		self.group = ItemGroup.new("Новая группа")

func _update():
	_on_name_changed(group.group_name)
	line_group_name.set_text(group.group_name)
	
	for child in container_group_patterns.get_children():
		container_group_patterns.remove_child(child)
	
	for item in group.get_items():
		var node = pattern_scene.instantiate()
		container_group_patterns.add_child(node)
		node.set_item(item)

func _unhandled_input(event):
	if event.is_action("ui_mouse_left"):
		var focused_node:Control = get_viewport().gui_get_focus_owner()
		if focused_node:
			focused_node.release_focus()

func save_group():
	group.clear_items()
	for node in container_group_patterns.get_children():
		if node.is_selected():
			group.add_item(node.get_item_name(),node.get_char(), node.get_quality())
	group.set_name(line_group_name.get_text().strip_edges())
	group.save_groups()
	visible = false
