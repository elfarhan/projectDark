extends Control

# Settings file path
const SETTINGS_PATH = "user://settings.cfg"
@onready var speedrun_timer = get_node_or_null("../../Speedrun_timer")

# Settings keys
const SPEEDRUN_TIMER_KEY = "speedrun_timer"
const SOUNDS_VOLUME_KEY = "sounds_volume"
const MUSIC_VOLUME_KEY = "music_volume"
const VSYNC_KEY = "vsync"
const FULLSCREEN_KEY = "fullscreen"

# References to UI elements
@onready var speedrun_timer_button = $Panel/Container/VBoxContainer/speedruntimer/CheckButton
@onready var sounds_slider = $Panel/Container/auditory/sounds/HSlider
@onready var music_slider = $Panel/Container/auditory/music/HSlider
@onready var vsync_button = $Panel/Container/visual/vsync/CheckButton
@onready var fullscreen_button = $Panel/Container/visual/fullscreen/CheckButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_settings()
	apply_settings()
	#speedrun_timer_button.toggled.connect(_on_speedrun_timer_button_toggled)
	sounds_slider.value_changed.connect(_on_sounds_slider_value_changed)
	music_slider.value_changed.connect(_on_music_slider_value_changed)
	vsync_button.toggled.connect(_on_vsync_button_toggled)
	fullscreen_button.toggled.connect(_on_fullscreen_button_toggled)





func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)
	
	if err == OK:
		speedrun_timer_button.button_pressed = config.get_value("settings", SPEEDRUN_TIMER_KEY, false)
		sounds_slider.value = config.get_value("settings", SOUNDS_VOLUME_KEY, 80.0)
		music_slider.value = config.get_value("settings", MUSIC_VOLUME_KEY, 80.0)
		vsync_button.button_pressed = config.get_value("settings", VSYNC_KEY, true)
		fullscreen_button.button_pressed = config.get_value("settings", FULLSCREEN_KEY, true)

func save_settings() -> void:
	var config = ConfigFile.new()
	
	config.set_value("settings", SPEEDRUN_TIMER_KEY, speedrun_timer_button.button_pressed)
	config.set_value("settings", SOUNDS_VOLUME_KEY, sounds_slider.value)
	config.set_value("settings", MUSIC_VOLUME_KEY, music_slider.value)
	config.set_value("settings", VSYNC_KEY, vsync_button.button_pressed)
	config.set_value("settings", FULLSCREEN_KEY, fullscreen_button.button_pressed)
	
	config.save(SETTINGS_PATH)
	
func apply_settings() -> void:
	# Apply audio settings
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sounds"), linear_to_db(sounds_slider.value / 100.0))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music_slider.value / 100.0))
	
	# Apply display settings
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync_button.button_pressed 
		else DisplayServer.VSYNC_DISABLED
	)
	
	# Apply fullscreen
	if fullscreen_button.button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	save_settings()

func _on_sounds_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sounds"), linear_to_db(value / 100.0))
	print("sound") # Replace with function body.
	save_settings()


func _on_music_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value / 100.0))
	print("music") # Replace with function body.
	save_settings()


func _on_vsync_button_toggled(toggled: bool) -> void:
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if toggled 
		else DisplayServer.VSYNC_DISABLED
		
	)
	save_settings()


func _on_fullscreen_button_toggled(toggled: bool) -> void:
	if toggled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	save_settings()


func _on_speedrum_timer_button_toggled(toggled: bool) -> void:
	if speedrun_timer:
		speedrun_timer.visible = toggled
	save_settings()
