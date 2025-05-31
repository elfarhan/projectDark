extends Label


@onready var time = 0
 
func _physics_process(delta):
	time = float(time) + delta
	update_ui()
	
func update_ui():
	var total_seconds = time
	var hours = int(floor(total_seconds) / 3600)
	var minutes = int(int(floor(total_seconds)) / 60)% 60
	var seconds = int(floor(total_seconds)) % 60
	var hundredths = floor((total_seconds - floor(total_seconds)) * 100)
	var formatted_time = "%02d:%02d.%02d" % [minutes, seconds, hundredths]
	if hours > 0:
		formatted_time = "%02d:%02d:%02d.%02d" % [hours, minutes, seconds, hundredths]
	$".".text = formatted_time


 
