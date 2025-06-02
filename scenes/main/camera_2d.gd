extends Camera2D

# Camera settings
@export_range(0, 10)var damping_speed = 5.0
@export_range(0, 150) var look_ahead_amount = 100.0
@export_range(0, 50) var look_ahead_speed = 10.0
@export_range(-200, 200) var vertical_offset = -50  # Negative = show more above player
@export_range(0, 250) var max_shake_intensity = 50.0
@export_range(0, 10) var shake_decay_rate = 5.0

# Internal variables
var player: Node2D
var target_position: Vector2
var look_ahead_target: float = 0.0
var current_look_ahead: float = 0.0
var vertical_lock_position: float = 0.0
var is_vertical_locked: bool = false
var shake_intensity: float = 0.0
var last_player_velocity: Vector2 = Vector2.ZERO

func _ready():
	player = get_parent()
	target_position = player.global_position
	global_position = target_position
	offset.y = vertical_offset
	# Make this camera current automatically
	make_current()
func _physics_process(delta):
	# Update player velocity tracking
	last_player_velocity = player.velocity
	
	# Handle vertical lock for jumping
	if player.is_on_floor():
		if is_vertical_locked:
			# Landed - trigger screenshake based on fall speed
			trigger_screenshake(abs(last_player_velocity.y))
			#pass
		is_vertical_locked = false
	elif not is_vertical_locked:
		# Started jumping - lock vertical position
		is_vertical_locked = true
		vertical_lock_position = global_position.y
	
	# Horizontal look ahead based on facing direction
	var look_direction = sign(player.velocity.x)  # Replace with your facing direction
	look_ahead_target = look_ahead_amount * look_direction
	
	# Smoothly interpolate look ahead position
	current_look_ahead = lerp(current_look_ahead, look_ahead_target, look_ahead_speed * delta)
	
	# Calculate target position
	target_position.x = player.global_position.x + current_look_ahead
	target_position.y = vertical_lock_position if is_vertical_locked else player.global_position.y
	
	# Apply damping to camera movement
	#global_position = global_position.linear_interpolate(target_position, damping_speed * delta)
	
	# Process screenshake
	process_screenshake(delta)

func trigger_screenshake(fall_speed: float):
	# Convert fall speed to shake intensity (clamped)
	shake_intensity = clamp(fall_speed / 10.0, 0.0, max_shake_intensity)

func process_screenshake(delta: float):
	if shake_intensity > 0:
		# Apply random offset
		offset.x = shake_intensity#rand_range(-shake_intensity, shake_intensity)
		offset.y = vertical_offset +shake_intensity#+ rand_range(-shake_intensity, shake_intensity)
		
		# Gradually reduce shake intensity
		shake_intensity = max(shake_intensity - shake_decay_rate * delta, 0.0)
	else:
		# Reset offset when not shaking
		offset.x = 0
		offset.y = vertical_offset
