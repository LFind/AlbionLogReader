extends Control

@onready var icon_texture = %IconTexture
@onready var icon_list_popup = %IconListPopup
@onready var icon_file_field = %IconFileField

@onready var text_note = %TextNote

@onready var check_hide = %CheckHide

@onready var spin_box_low = %SpinBoxLow
@onready var spin_box_min = %SpinBoxMin

@onready var button_clear_entries = %ButtonClearEntries

var data:Dictionary
var item:String
var icon_filename:Dictionary
var icon_unknown = ImageTexture.create_from_image(Image.load_from_file(ItemData.UNKNOWN_ICON))

func _ready():
	icon_unknown.set_size_override(Vector2i(64,64))
	icon_texture.set_texture(icon_unknown)
	icon_file_field.clear()
	icon_list_popup.clear()
	
	text_note.clear()
	
	spin_box_low.value = 0
	spin_box_min.value = 0
	spin_box_low.apply()
	spin_box_min.apply()
	
	icon_file_field.text_submitted.connect(func(text:String):
		icon_file_field.text = icon_file_field.text.strip_edges()
		
		if icon_file_field.text in icon_filename.keys(): return
		icon_file_field.clear()
		)
	icon_file_field.focus_exited.connect(func():
		_update_icons_popup()
		icon_file_field.text = icon_file_field.text.strip_edges()
		
		if icon_file_field.text in icon_filename.keys(): return
		icon_file_field.clear()
		)	
	icon_file_field.focus_entered.connect(_update_icons_popup)
	icon_file_field.text_changed.connect(func(text:String):
		set_icon_preview(text)
		_update_icons_popup()
		)
	icon_list_popup.item_selected.connect(func(index:int):
		var filename = icon_list_popup.get_item_text(index)
		icon_file_field.text = filename
		set_icon_preview(filename)
		)
	
	button_clear_entries.pressed.connect(_remove_item_entries)

func _remove_item_entries():
	LogData.remove_all_entries(item)

func set_icon_preview(filename:String):
	icon_texture.texture = icon_filename.get(filename, icon_unknown)

func _update_icons_popup():
	var text = icon_file_field.text.strip_edges()
	icon_list_popup.deselect_all()
	if text != "" and icon_file_field.has_focus():
		var icons_found:Array
		
		if text != "":
			for file in icon_filename.keys():
				if text in file:
					icons_found.append(file)
		
		icon_list_popup.visible = icons_found.size() > 0
		if icon_list_popup.visible:
			icon_list_popup.clear()
			for file in icons_found:
				icon_list_popup.add_item(file, icon_filename[file])
	elif icon_file_field.has_focus():
		icon_list_popup.visible = true
		icon_list_popup.clear()
		for file in icon_filename.keys():
			icon_list_popup.add_item(file, icon_filename[file])
	else:
		icon_list_popup.visible = false
	
	if icon_list_popup.visible:
		icon_list_popup.size.y = clamp((icon_list_popup.item_count + 0.5) * 32, 32, 224)
		icon_list_popup.size.x = icon_file_field.size.x
		icon_list_popup.position.x = icon_file_field.get_global_transform().origin.x
		icon_list_popup.position.y = icon_file_field.get_global_transform().origin.y + icon_file_field.size.y

func _update():
	icon_texture.set_texture(ItemData.get_icon(item, Vector2i(64,64)))
	icon_file_field.set_text(ItemData.get_icon_filename(item))
	
	icon_filename.clear()
	for filename in ItemData.get_icons():
		icon_filename[filename] = ItemData.get_icon_by_filename(filename, Vector2i(64,64))
	
	spin_box_low.set_value(ItemData.get_count_low(item))
	spin_box_min.set_value(ItemData.get_count_min(item))
	
	check_hide.button_pressed = ItemData.is_hidden(item)
	text_note.text = ItemData.get_note(item)

func _release_focus():
	var focused_node:Control = get_window().gui_get_focus_owner()
	if focused_node:
		focused_node.release_focus()
	
	if focused_node == icon_file_field:
		_update_icons_popup()

func _unhandled_input(event):
	if event.is_action("ui_mouse_left"):
		_release_focus()

func _on_close_requested():
	
	ItemData.set_icon(item, icon_file_field.text if icon_file_field.text.strip_edges() in icon_filename.keys() else "")
	ItemData.set_count_low(item, spin_box_low.value)
	ItemData.set_count_min(item, spin_box_min.value)
	ItemData.set_note(item, text_note.text)
	ItemData.set_hidden(item, check_hide.button_pressed)
	
	Event.update_item_settings.emit(item)

func set_item(item:String):
	self.data = LogData.get_entries(item)
	self.item = item
	_update()
