class_name Player
extends CharacterBody2D

signal landed
@export_group("Movement")
@export_range(0, 500) var max_speed := 280.0
@export_range(0, 500) var acceleration := 140.0
@export_range(0, 50) var deceleration := 150.0
@export_range(0, 50) var turn_speed := 90.0
var horizontal_movement_direction = 1

@export_group("jump")
@onready var jump_height_timer = $JumpHeightTimer
@onready var jump_buffer_timer = $JumpBufferTimer
@onready var jump_coyote_timer = $CoyoteTimer
@onready var ray_cast_right = $Raycasts/Right
@onready var ray_cast_left= $Raycasts/Left
@onready var ray_cast_center = $Raycasts/Center
@onready var ray_cast_horizontal = $Raycasts/horizontal
@onready var ray_cast_horizantal_buttom = $Raycasts/buttom
@onready var ray_cast_horizantal_top = $Raycasts/top


var buffered_jump = false
var coyote_jump = false
var was_on_floor = true
@export_range(0, 5000) var max_jump_height := 160.0
@export_range(0, 5000) var min_jump_height := 40.0
@export_range(0, 500) var jump_duration := 2.5
@onready var jump_speed = -sqrt(2*gravity*max_jump_height)
@onready var jump_speed_cutoff = -sqrt(2*gravity*min_jump_height)
@onready var jump_acceleration = gravity*(1-min_jump_height/max_jump_height)
@export_range(0, 1000) var gravity := 1000.0
@onready var fall_gravity = gravity * 2.0
@export_range(1000, 2500) var fall_speed_cutoff := 1800.0

var carried_light
var direction = 1
func _get_gravity(velocity: Vector2):
	if velocity.y <0:
		return gravity
	elif  velocity.y >= fall_speed_cutoff:
		return 0
	else:
		return fall_gravity

# Calculates the players movement depending on the context
func _get_movement(decel: float, accel: float, turn: float, delta: float):
	
	## horizontal movements:
	direction = Input.get_axis("Move_Left", "Move_Right")
	horizontal_movement_direction = sign(direction)
	if direction: # accelerate
		velocity.x += sign(direction) * accel * delta * 100
	
	if !direction: # decelerate
		velocity.x = move_toward(velocity.x, 0, decel * delta * 100)
		
	if  sign(direction) != sign(velocity.x): # turn mid movement
		velocity.x = move_toward(velocity.x, -velocity.x, turn * delta * 100)
	
	velocity.x = clamp(velocity.x, -max_speed, max_speed)

func _ready() -> void:
	$AnimatedSprite2D.play("default")
	$AnimatedSprite2D.flip_h = false

func jump():
	velocity.y = jump_speed
	$AnimatedSprite2D.play("default") # jump sprite

# variable jump height
func _on_jump_height_timer_timeout() -> void:
	if !Input.is_action_pressed("Jump"):
		if velocity.y < jump_speed_cutoff:
			velocity.y = jump_speed_cutoff
	else:
		pass

# coyote jump
func _on_coyote_timer_timeout() -> void:
	coyote_jump = false

# buffer jump
func _on_jump_buffer_timer_timeout() -> void:
	buffered_jump = false

func _physics_process(delta):
	if Input.is_action_just_pressed("Jump"):
		jump_height_timer.start()
		if is_on_floor(): 
			jump()
		else:
			jump_buffer_timer.start()
			if !buffered_jump:
				buffered_jump = true
			if coyote_jump:
				jump()
				coyote_jump = false
	# fall with gravity
	if !is_on_floor():
		velocity.y += _get_gravity(velocity) * delta
		# handle quality of life vertical jumps
		if velocity.y <0:
			if !ray_cast_center.is_colliding() and ray_cast_left.is_colliding() and velocity.x>=0:
				global_position.x += 900*delta
				velocity.x += 900
			elif !ray_cast_center.is_colliding() and ray_cast_right.is_colliding() and velocity.x<=0:
				global_position.x +=  -900*delta
				velocity.x += -900
		if ray_cast_horizontal.is_colliding() and !ray_cast_horizantal_buttom.is_colliding():
			#global_position.y = -9*delta
			velocity.y -= 9*delta
			
		#elif  ray_cast_horizontal.is_colliding() and !ray_cast_horizantal_top.is_colliding():
			#global_position.y = 900*delta
		#	velocity.y -= 900*delta
	was_on_floor = is_on_floor()
	# handle horizontal movement
	if is_on_floor():
		_get_movement(deceleration, acceleration, turn_speed, delta) # ground movement speed
	else:
		_get_movement(deceleration*0.5, acceleration*.5, turn_speed*.01, delta) # air movement speed
	var previous_velocity_y = velocity.y
	_set_sprite_direction(direction)
	move_and_slide()
	# buffered jumps
	if !was_on_floor and is_on_floor():
		if previous_velocity_y >= fall_speed_cutoff:
			emit_signal("landed")
			print("shake!")
		if buffered_jump:
			jump()
	# coyote jumps
	if was_on_floor and !is_on_floor() and velocity.y >=0:
		jump_coyote_timer.start()
		coyote_jump = true

# Flips the player sprite depending on their movemnt direction
func _set_sprite_direction(direction: int) -> void:
	if direction < 0.0:
		$AnimatedSprite2D.flip_h = true

	if direction > 0.0:
		$AnimatedSprite2D.flip_h = false

	if velocity != Vector2.ZERO:
		$AnimatedSprite2D.play("default")
	else:
		$AnimatedSprite2D.play("default")
		

# handle light pickup
func _input(event):
	if event.is_action_pressed("Carry_Drop"):
		if self.carried_light != null:
			drop_light()
		else:
			for body in $InteractionShape.get_overlapping_bodies():
				if body is Light:
					carry_light(body)
					break
	if event.is_action_pressed("Interact"):
		if self.carried_light != null:
			for area in $InteractionShape.get_overlapping_areas():
				if area is Npc:
					if area.needs > 0 and self.carried_light.radius >= area.needs:
						self.carried_light.shrink(area.needs)
						area.fulfill()

func carry_light(light):
	self.carried_light = light
	
	# inform spawner
	if light.get_parent() is LightSpawner:
		light.get_parent().mark_picked_up(light)
	
	# Reparent to player marker
	light.reparent($LightMarker)
	light.position = Vector2.ZERO
	light.set_dynamic(false)

	# update light radius
	light.radius *= light.held_factor

func drop_light():
	self.carried_light.reparent(self.get_parent(), true)
	
	# Restore physics properties
	self.carried_light.set_dynamic(true)
	
	# update light radius
	self.carried_light.radius /= self.carried_light.held_factor
	
	self.carried_light = null
