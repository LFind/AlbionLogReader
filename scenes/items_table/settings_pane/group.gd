extends HBoxContainer

@onready var button_name = %ButtonName
@onready var button_edit = %ButtonEdit
@onready var button_delete = %ButtonDelete
@onready var warn = %Warn

signal request_edit(group:ItemGroup)

var group:ItemGroup:
	set(value):
		group = value
		_update()

func _ready():
	button_name.set_text("Новая группа")
	button_delete.pressed.connect(func():
		if group:
			group.delete()
		queue_free()
		)
	button_edit.pressed.connect(func():
		if not group: group = ItemGroup.new("Новая группа")
		request_edit.emit(group)
		)

func _unhandled_input(event):
	if event.is_action("ui_unlock"):
		# Блокировка кнопки удаления
		button_delete.disabled = not event.is_action_pressed("ui_unlock", true)

func _update():
	warn.visible = group == null
	if not group: return
	button_name.set_text(group.group_name)

func set_group(group:ItemGroup):
	self.group = group

func get_group() -> ItemGroup:
	return group
