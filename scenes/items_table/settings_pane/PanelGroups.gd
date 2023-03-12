extends Panel

var group_scene = preload("res://scenes/items_table/settings_pane/group.tscn")

@onready var button_create_group = %ButtonCreateGroup
@onready var container_groups = %ContainerGroups
@onready var panel_edit_groups = %PanelEditGroups
@onready var setting_pane = $".."


func _ready():
	button_create_group.pressed.connect(func():
		var last_index = container_groups.get_child_count()-1
		if last_index >= 0:
			if container_groups.get_child(container_groups.get_child_count()-1).get_group():
				_create_group_node()
		else:
			_create_group_node()
		)
	setting_pane.visibility_changed.connect(func():
		if setting_pane.visible:
			_update()
		)
	Event.groups_saved.connect(_update)
	_update()

func _update():
	for node in container_groups.get_children():
		node.queue_free()
	
	for group in ItemGroup.get_groups():
		_create_group_node(group)

func _create_group_node(group:ItemGroup = null):
	var node = group_scene.instantiate()
	container_groups.add_child(node)
	node.set_group(group)
	node.request_edit.connect(_on_request_edit)

func _on_request_edit(group:ItemGroup):
	panel_edit_groups.set_group(group)
	panel_edit_groups.visible = true
	self.visible = false
