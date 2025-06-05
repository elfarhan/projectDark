extends Camera2D

@onready var player = $".."

@export var h_look_ahead_amount: float = 40.0
@export var v_look_ahead_amount: float = 55.0
@export var ease_speed: float = 10.0

@export var max_shake: float = 10.5
@export var shake_fade: float = 10.0

var _shake_strength: float = 0.0
var shake_offset: Vector2 = Vector2.ZERO
var _current_lookahead_offset: Vector2 = Vector2.ZERO
var target_look_ahead: Vector2 = Vector2.ZERO
var last_direction: int = 1
var direction: int = 1

func trigger_shake() -> void:
	_shake_strength = max_shake

func _physics_process(delta):
	if player == null:
		return

	# Screen shake logic
	shake_offset = Vector2.ZERO
	if _shake_strength != 0:
		_shake_strength = lerp(_shake_strength, 0.0, shake_fade * delta)
		shake_offset = Vector2(
			randf_range(-_shake_strength, _shake_strength),
			randf_range(-_shake_strength, _shake_strength)
		)

	# Lookahead
	var current_direction = player.horizontal_movement_direction
	if current_direction != 0 and current_direction == -last_direction:
		last_direction = current_direction
		direction = current_direction
		target_look_ahead.x = h_look_ahead_amount * direction
	
	target_look_ahead.y = v_look_ahead_amount if player.velocity.y > 100 else 0.0
	
	# Easing
	_current_lookahead_offset.x = ease_in_out_sine(_current_lookahead_offset.x, target_look_ahead.x, delta * ease_speed)
	_current_lookahead_offset.y = ease_in_out_sine(_current_lookahead_offset.y, target_look_ahead.y, delta * ease_speed)

	# Combine effects
	var base_position = global_position
	var size = get_viewport_rect().size
	#var width = 
	#print(size.length())
	var desired_position = base_position + _current_lookahead_offset + shake_offset
	desired_position.x = clamp(desired_position.x, limit_left, limit_right)
	desired_position.y = clamp(desired_position.y, limit_top, limit_bottom)

	#offset = desired_position - base_position

func ease_in_out_sine(start: float, end: float, delta_scaled: float) -> float:
	var t = clamp(delta_scaled, 0.0, 1.0)
	var percentage = -(cos(PI * t) - 1.0) / 2.0
	return lerp(start, end, percentage)

func _on_player_landed() -> void:
	trigger_shake()
