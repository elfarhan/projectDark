extends Control

@onready var pause_menu = $"."
@onready var options_menu = $OptionsMenu
@onready var vbox = $VBox
var options_toggled = false

func _ready():
	# Hide both menus initially
	pause_menu.visible = false
	options_menu.visible = false
	

func pause():
	get_tree().paused = true
	pause_menu.visible = true
	vbox.visible = true 
	options_menu.visible = false  
	options_toggled = false
	$VBox/Resume.grab_focus()

func resume():
	get_tree().paused = false
	pause_menu.visible = false
	options_menu.visible = false
	options_toggled = false

func show_options():
	vbox.visible = false
	options_menu.visible = true
	options_toggled = true

func hide_options():
	vbox.visible = true
	options_menu.visible = false
	options_toggled = false
	$VBox/Resume.grab_focus()

func testesc():
	if Input.is_action_just_pressed("Esc"):
		if get_tree().paused:
			if options_toggled:
				# If in options menu, go back to pause menu
				hide_options()
			else:
				# If in main pause menu, resume game
				resume()
		else:
			# If game is running, pause it
			pause()

func _process(delta):
	testesc()

func _on_resume_pressed() -> void:
	resume()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_options_pressed() -> void:
	show_options()

# Add this function for the options back button
func _on_options_back_pressed() -> void:
	hide_options()

func _on_save_exit_pressed() -> void:
	get_tree().quit()
