extends Control

@onready var options_menu = $Options
var options_toggled = false
@onready var vbox = $VBoxContainer

func _ready() -> void:
	$VBoxContainer/StartGame.grab_focus()
	

func show_options():
	vbox.visible = false
	options_menu.visible = true
	options_toggled = true

func hide_options():
	vbox.visible = true
	options_menu.visible = false
	options_toggled = false
	$VBoxContainer/StartGame.grab_focus()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Esc"):
		if options_toggled:
			# If in options menu, go back to pause menu
			hide_options()


func _on_start_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")


func _on_options_pressed() -> void:
	#get_tree().change_scene_to_file("res://scenes/main/options.tscn")
	show_options()
	pass


func _on_exit_pressed() -> void:
	get_tree().quit()
