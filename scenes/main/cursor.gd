extends TextureRect

@export var menu_parent_path : NodePath
@export var cursor_offset : Vector2 = Vector2.ZERO

@onready var menu_parent: Node = get_node(menu_parent_path)
@onready var submenu_index = 0
@onready var current_submenu = menu_parent.get_child(submenu_index)

var cursor_index: int = 0

func _ready():
	set_cursor_from_index(0,0)

func _process(delta):
	var input := 0
	
	if Input.is_action_just_pressed("ui_up"):
		input = -1
	elif Input.is_action_just_pressed("ui_down"):
		input = 1

	if input != 0:
		var new_index = cursor_index + input
		
		# Handle movement within current submenu
		if new_index >= 0 and new_index < current_submenu.get_child_count():
			cursor_index = new_index
			set_cursor_from_index(cursor_index, submenu_index)
		else:
			# Handle vertical wrapping between submenus
			if input > 0:  # Moving down from last item
				submenu_index += 1
				new_index = 0
			else:  # Moving up from first item
				submenu_index -= 1
				new_index = -1  # Temporary placeholder
			
			# Clamp submenu index to valid range
			submenu_index = clampi(submenu_index, 0, menu_parent.get_child_count() - 1)
			current_submenu = menu_parent.get_child(submenu_index)
			
			# Handle empty submenu case
			if current_submenu.get_child_count() == 0:
				cursor_index = 0
			else:
				# Adjust index for new submenu
				if new_index == -1:  # Coming from up movement
					cursor_index = current_submenu.get_child_count() - 1
				else:  # Coming from down movement
					cursor_index = new_index
			
			# Ensure cursor index is valid
			cursor_index = clampi(cursor_index, 0, current_submenu.get_child_count() - 1)
			set_cursor_from_index(cursor_index, submenu_index)
	
	if Input.is_action_just_pressed("ui_select"):
		var current_item = get_menu_item_at_index(cursor_index, submenu_index)
		if current_item and current_item.has_method("cursor_select"):
			current_item.cursor_select()

func get_menu_item_at_index(index: int, submenu_index: int) -> Control:
	if not menu_parent or index < 0 or index >= menu_parent.get_child_count():
		return null
	current_submenu = menu_parent.get_child(submenu_index)
	return current_submenu.get_child(index) as Control

func set_cursor_from_index(index: int, submenu_index: int) -> void:
	var menu_item = get_menu_item_at_index(index, submenu_index)
	if not menu_item:
		return
	
	var position = menu_item.global_position
	var size = menu_item.size
	
	# Center vertically, align left with offset
	global_position = Vector2(
		position.x - cursor_offset.x,
		position.y + (size.y / 2.0) - (self.size.y / 2.0) - cursor_offset.y
	)
	
	cursor_index = index
