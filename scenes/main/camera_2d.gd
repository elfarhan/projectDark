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
	pass
func _physics_process(delta):
	pass
