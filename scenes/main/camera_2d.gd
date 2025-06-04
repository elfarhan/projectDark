extends Camera2D

# Camera settings

@onready var player = $".."
@export var look_ahead_amount: float = 20.0
@export var ease_duration: float = 1.5
var ease_timer: float = 0.0
var target_look_ahead: Vector2
var last_direction: int = 1  # Track last facing direction
var is_easing: bool = false          # Whether we're currently easing
var direction: int = 1               # Current movement direction
var returning: bool = false 
@onready var previous_direction = player.horizontal_movement_direction
@export var max_shake: float = 10.5
@export var shake_fade: float = 10.0
var _shake_strength: float = 0.0

func trigger_shake() -> void:
	_shake_strength = max_shake

func _physics_process(delta):
	# handle screen_shake
	if _shake_strength != 0:
		_shake_strength = lerp(_shake_strength, 0.0, shake_fade * delta)
		offset = Vector2(randf_range(-_shake_strength, _shake_strength), randf_range(-_shake_strength, _shake_strength))
		
	# Handle look ahead when player starts moving
	var current_direction = player.horizontal_movement_direction

	if current_direction != 0 and current_direction != last_direction:
		last_direction = current_direction
		direction = current_direction
		ease_timer = 0.0
		target_look_ahead = Vector2(look_ahead_amount * direction, 0.0)
		is_easing = true

	if is_easing:
		ease_timer += delta
		if ease_timer >= ease_duration:
			is_easing = false

	var s = ease_timer / ease_duration if ease_duration > 0 else 1.0

	offset.x = ease_in_out_sine(0.0, target_look_ahead.x, s)
	offset.y = randf_range(-_shake_strength, _shake_strength) if _shake_strength > 0 else 0.0


func ease_in_out_sine(lower_bound:float,  upper_bound: float, x: float) -> float:
	var percentage = -(cos(PI * x) - 1.0) / 2.0
	if x <= 1:
		return  (upper_bound-lower_bound)*percentage + lower_bound
	else:
		return upper_bound


func _on_player_landed() -> void:
	trigger_shake()
