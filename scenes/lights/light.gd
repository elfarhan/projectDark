class_name Light
extends RigidBody2D

@export_range(0, 2048, 8) var radius = 256 
@export var time_limit = 0
@onready var timer = $Timer
@onready var light = $PointLight2D

func _ready():
	light.enabled = true
	# Start the timer when scene loads
	if self.time_limit > 0:
		$Timer.start(self.time_limit)
	self.rescale_texture()

func rescale_texture():
	light.texture_scale = radius / self.scale.x / 256

func _on_timer_timeout():
	light.enabled = false
