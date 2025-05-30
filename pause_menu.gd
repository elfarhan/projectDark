extends Control

@onready var pause_menu = $"."

func _ready():
	# Hide pause menu initially when game starts
	pause_menu.visible = false
	
func pause():
	get_tree().paused = true
	pause_menu.visible = true
	
func resume():
	get_tree().paused = false
	pause_menu.visible = false
	
	
func testesc():
	if Input.is_action_just_pressed("Esc") and get_tree().paused == false:
		pause()
	elif Input.is_action_just_pressed("Esc") and get_tree().paused == true:
		resume()
		
func _process(delta):
	testesc()


func _on_resume_pressed() -> void:
	resume()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
	#resume()


func _on_options_pressed() -> void:
	pass # Replace with function body.


func _on_save_exit_pressed() -> void:
	# add save before exit bro
	get_tree().quit()
