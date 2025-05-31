extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#$Panel/Container/visual/fullscreen/CheckButton.grab_focus()
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_speedrun_timer_button_pressed() -> void:
	print("speedrun") # Replace with function body.


func _on_sounds_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sounds"), linear_to_db(value / 100.0))
	print("sound") # Replace with function body.


func _on_music_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value / 100.0))
	print("music") # Replace with function body.


func _on_vsync_button_toggled(toggled: bool) -> void:
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if toggled 
		else DisplayServer.VSYNC_DISABLED
		
	)


func _on_fullscreen_button_toggled(toggled: bool) -> void:
	if toggled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
