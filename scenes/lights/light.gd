class_name ShadowLight
extends RigidBody2D

@export_range(0, 1024, 8) var radius = 128 
@onready var timer = $Timer
@onready var light = $PointLight2D
@onready var player_marker = get_node("../Player/LightMarker")
@onready var player = get_node("../Player")

var is_carried = false
var original_parent = null

func _init(radius: float = 128):
	self.radius = radius

func _ready():
	# Start the timer when scene loads
	timer.start()
	light.texture_scale = radius / self.scale.x / 256

func _on_timer_timeout():
	light.enabled = false

func _input(event):
	if event.is_action_pressed("Carry_Drop"):
		if is_carried:
			drop_light()
		elif self.global_position.distance_to(player.global_position) < 57:
			carry_light()

func carry_light():
	if is_carried: 
		return
	
	is_carried = true
	
	# Reparent to player marker
	original_parent = self.get_parent()
	self.reparent(player_marker)
	
	# Reset physics properties
	self.position = Vector2.ZERO
	self.freeze = true

func drop_light():
	if !is_carried: 
		return
	is_carried = false
	self.reparent(self.original_parent, true)
	
	# Restore physics properties
	self.freeze = false
	self.linear_velocity = player.velocity*.2#Vector2.ZERO
	self.angular_velocity = 0
