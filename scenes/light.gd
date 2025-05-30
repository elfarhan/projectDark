extends Node2D

@onready var timer = $Timer
@onready var light = $RigidBody2D/PointLight2D
@onready var player_marker = get_node("../Player/LightMarker")
@onready var player = get_node("../Player")
@onready var light_body = $RigidBody2D

var is_carried = false
var original_parent = null

func _ready():
	# Start the timer when scene loads
	timer.start()
	light.enabled = true 
	print(player_marker.position)
	
	# Connect timeout signal
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout():
	light.enabled = false

func _physics_process(delta):
	light.energy = max(light.energy-delta*0.001,0)
	#print(light_body.global_position.distance_to(player.global_position))
	
	if is_carried:
		# Keep the light positioned at the marker while carried
		light_body.global_position = player_marker.global_position
		light_body.linear_velocity = Vector2.ZERO
		light_body.angular_velocity = 0

func _input(event):
	if event.is_action_pressed("Carry_Drop"):
		if is_carried:
			drop_light()
		elif light_body.global_position.distance_to(player.global_position) < 57:
			carry_light()

func carry_light():
	if is_carried: 
		return
	
	is_carried = true
	
	# Save original parent and position
	#original_parent = light_body.get_parent()
	
	# Remove from current parent and add to player marker
	#original_parent.remove_child(light_body)
	#player_marker.add_child(light_body)
	
	# Reset physics properties
	light_body.position = Vector2.ZERO
	#light_body.freeze = true
	#light_body.sleeping = true
	light_body.collision_layer = 0
	light_body.collision_mask = 0

func drop_light():
	if !is_carried: 
		return
	is_carried = false
	# Restore physics properties
	light_body.global_position = player_marker.global_position
	#light_body.freeze = false
	#light_body.sleeping = false
	light_body.collision_layer = 1
	light_body.collision_mask = 1
	light_body.linear_velocity = player.velocity*.2#Vector2.ZERO
	light_body.angular_velocity = 0
