class_name Light
extends RigidBody2D

## current radius of the light
@export_range(0, 2048, 8) var radius = 256 
## radius size change when dropped
@export_range(0, 10, 0.125) var held_factor = 0.75

@export var timeout = 0
@onready var timer = $Timer
@onready var light = $PointLight2D

# TODO: investigate flickering
func _ready():
	light.enabled = true
	# Start the timer when scene loads
	if self.timeout > 0:
		$Timer.start(self.timeout)
	self.rescale_texture()

const scene = preload("res://scenes/lights/Light.tscn")
static func create(radius, timeout, dynamic = true):
	var light = scene.instantiate()
	light.radius = radius
	light.timeout = timeout
	light.set_dynamic(dynamic)
	return light

func set_dynamic(flag):
	if flag:
		self.linear_velocity = Vector2.ZERO
		self.freeze = false
		self.get_node(^"CollisionShape2D").disabled = false
	else:
		self.freeze = true
		self.get_node(^"CollisionShape2D").disabled = true

func shrink(amount):
	self.radius -= amount
	self.rescale_texture()

func resize(radius):
	self.radius = radius
	self.rescale_texture()

func rescale_texture():
	light.texture_scale = radius / self.scale.x / 256

func set_timeout(timeout):
	self.timeout = timeout
	$Timer.start(self.timeout)

func _on_timer_timeout():
	light.enabled = false
