@tool
class_name Light
extends RigidBody2D

## current radius of the light
@export_range(0, 2048, 8) var radius = 256:
	set(new_radius):
		radius = new_radius
		if self.is_node_ready():
			rescale_texture()
@export var timeout = 0:
	set(new_timeout):
		timeout = new_timeout
		$Timer.start(self.timeout)

## radius size change when dropped
@export_range(0, 10, 0.125) var held_factor = 0.75

@onready var timer = $Timer
@onready var light = $PointLight2D

# TODO: investigate flickering
const blur_width: float = 20

func _ready():
	light.enabled = true
	# Start the timer when scene loads
	if self.timeout > 0:
		$Timer.start(self.timeout)
	self.rescale_texture()

const scene = preload("res://scenes/lights/Light.tscn")
static func create(radius, timeout, dynamic = true):
	var out = scene.instantiate()
	out.radius = radius
	out.timeout = timeout
	out.set_dynamic(dynamic)
	return out

func set_dynamic(flag):
	if flag:
		self.linear_velocity = Vector2.ZERO
		self.freeze = false
		self.get_node(^"CollisionShape2D").disabled = false
	else:
		self.freeze = true
		self.get_node(^"CollisionShape2D").disabled = true

func rescale_texture():
	light.texture_scale = radius / self.scale.x / 256

func _on_timer_timeout():
	light.enabled = false
