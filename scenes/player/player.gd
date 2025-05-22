class_name Player
extends CharacterBody2D

@onready var coyote_timer = $CoyoteTimer
@onready var jump_buffer_timer = $JumpBufferTimer




@export_group("Movement")
@export_range(0, 500) var max_speed := 160.0
@export_range(0, 500) var acceleration := 40.0
@export_range(0, 50) var deceleration := 50.0
@export_range(0, 50) var turn_speed := 500.0

@export_group("jump")
@export_range(0, 5000) var jump_height := 900.0
@export_range(0, 500) var jump_duration := 2.5
var jump_speed = -2*jump_height/jump_duration
var jump_cutoff_speed = jump_speed/4
@export_range(0, 1000) var gravity := 900.0






func _get_air_movement(delta: float):
	pass


func jump():
	velocity.y = jump_speed

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
	if not is_on_floor():
		velocity.y += gravity* delta

	else:
		velocity.y = 0
		if Input.is_action_just_pressed("Jump"):
			jump()
			$AnimatedSprite2D.play("default") # jump sprite
	if Input.is_action_just_released("Jump") and velocity.y < jump_cutoff_speed:
		velocity.y = jump_cutoff_speed
	_set_sprite_direction(sign(velocity.x))
	

	if velocity != Vector2.ZERO:
		$AnimatedSprite2D.play("default")
	else:
		$AnimatedSprite2D.play("default")
		
	_get_movement(deceleration, acceleration, turn_speed, delta)
	move_and_slide()
	
