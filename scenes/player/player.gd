class_name Player
extends CharacterBody2D

# Coyote time
const COYOTE_TIME = 0.2  # seconds
var coyote_time_remaining = 0.0

# Jump buffer (optional)
const JUMP_BUFFER_TIME = .15
var jump_buffer_remaining = 0.0


@export_group("Movement")
@export_range(0, 500) var max_speed := 160.0
@export_range(0, 500) var acceleration := 40.0
@export_range(0, 50) var deceleration := 50.0
@export_range(0, 50) var turn_speed := 500.0

@export_group("jump")
@export_range(0, 5000) var max_jump_height := 300.0
@export_range(0, 5000) var min_jump_height := 200.0
@export_range(0, 500) var jump_duration := 2.5
@onready var jump_speed = -sqrt(2*gravity*min_jump_height)
@onready var jump_acceleration = gravity*(1-min_jump_height/max_jump_height)
@export_range(0, 1000) var gravity := 900.0






func _get_air_movement(delta: float):
	pass


func jump():
	
	velocity.y = jump_speed
	jump_buffer_remaining = 0
	coyote_time_remaining = 0
	$AnimatedSprite2D.play("default") # jump sprite

# Calculates the players movement depending on the context
func _get_movement(decel: float, accel: float, turn: float, delta: float):
	
	## horizontal movements:
	var direction = Input.get_axis("Move_Left", "Move_Right")
	
	if direction: # accelerate
		velocity.x += sign(direction) * accel * delta * 100
	
	if !direction: # decelerate
		velocity.x = move_toward(velocity.x, 0, decel * delta * 100)
		
	if  sign(direction) != sign(velocity.x): # turn mid movement
		velocity.x = move_toward(velocity.x, -velocity.x, turn * delta * 100)
	
	velocity.x = clamp(velocity.x, -max_speed, max_speed)
	


# Flips the player sprite depending on their movemnt direction
func _set_sprite_direction(direction: int) -> void:
	if direction > 0.0:
		$AnimatedSprite2D.flip_h = true

	if direction < 0.0:
		$AnimatedSprite2D.flip_h = false

	if velocity != Vector2.ZERO:
		$AnimatedSprite2D.play("default")
	else:
		$AnimatedSprite2D.play("default")
		


func _physics_process(delta):
	
	if Input.is_action_just_pressed("Jump"):
		if is_on_floor() or coyote_time_remaining > 0:
			jump()
		else:
			jump_buffer_remaining = JUMP_BUFFER_TIME
	
	if Input.is_action_pressed("Jump") and velocity.y < 0:
		velocity.y -= jump_acceleration*delta
		
	if is_on_floor():
		coyote_time_remaining = COYOTE_TIME
		if jump_buffer_remaining > 0:
			jump()
		_set_sprite_direction(sign(velocity.x))
	else:
		velocity.y += gravity * delta
		jump_buffer_remaining -= delta
		coyote_time_remaining -= delta

	#if Input.is_action_just_released("Jump") and velocity.y < jump_cutoff_speed:
	#	velocity.y = jump_cutoff_speed
		
	_get_movement(deceleration, acceleration, turn_speed, delta)
	move_and_slide()
	
