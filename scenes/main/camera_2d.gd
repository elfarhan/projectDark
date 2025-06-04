extends Camera2D

# Camera settings

@onready var player = $".."
@export var look_ahead_amount: float = 550.0
@export var ease_duration: float = 1.5
var ease_timer: float = 0.0
var target_look_ahead: Vector2
var last_direction: int = 1  # Track last facing direction
var is_easing: bool = false          # Whether we're currently easing
var direction: int = 1               # Current movement direction
var returning: bool = false 
@onready var previous_direction = player.horizontal_movement_direction

func get_player_direction():
	if player.horizontal_movement_direction == 0.0 or player.horizontal_movement_direction == 1.0:
		return 1
	elif player.horizontal_movement_direction == -1.0:
		return -1	 
	else:
		print("error")
		return 0
	return player.horizontal_movement_direction
func _physics_process(delta):
	# Handle look ahead when player starts moving
	if  is_equal_approx(global_position.x, target_look_ahead.x):
		ease_timer = 0.0
		is_easing = true
		target_look_ahead = player.global_position
		target_look_ahead.x += get_player_direction() * look_ahead_amount
		
	if is_equal_approx(global_position.x, target_look_ahead.x):
		is_easing = false
	# Update easing timer if active
	if is_easing:
		ease_timer += delta
		if ease_timer >= ease_duration:
			is_easing = false
	
	# Calculate interpolation factor (s)
	var s = ease_timer / ease_duration if ease_duration > 0 else 1.0
	
	# Apply easing to camera position
	global_position.x = ease_in_out_sine(global_position.x, target_look_ahead.x, s)
	global_position.y = player.global_position.y
	#print(is_equal_approx(global_position.x, target_look_ahead.x))
	
	previous_direction = get_player_direction()
	#print(previous_direction)

func ease_in_out_sine(lower_bound:float,  upper_bound: float, x: float) -> float:
	var percentage = -(cos(PI * x) - 1.0) / 2.0
	if x <= 1:
		return  (upper_bound-lower_bound)*percentage + lower_bound
	else:
		return upper_bound
