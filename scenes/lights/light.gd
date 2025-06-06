@tool
class_name Light
extends RigidBody2D

# maximum binding force
const bind_force: float = 8000
# radius at which half the maximum binding force is applied
const bind_radius: float = 10
# how much to reduce bind force by depending on velocity
const bind_smooth: float = 0.01

# how much to track player velocity if held
const bind_track: float = 0.5
const bind_track_radius: float = 30

const repell_force: float = 20
const repell_range: float = 50
const damp: float = 0.3

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

var anchor = null

# TODO: investigate flickering
const blur_width: float = 20

func _ready():
	light.enabled = true
	# Start the timer when scene loads
	if self.timeout > 0:
		$Timer.start(self.timeout)
	self.rescale_texture()

const scene = preload("res://scenes/lights/Light.tscn")
static func create(radius, timeout):
	var out = scene.instantiate()
	out.radius = radius
	out.timeout = timeout
	return out

func rescale_texture():
	light.texture_scale = radius / self.scale.x / 256

func _on_timer_timeout():
	light.enabled = false

func _physics_process(delta):
	self.linear_velocity *= self.damp ** delta
	if self.anchor is LightMarker:
		# bind strongly to light marker
		var direction = (self.anchor.global_position - self.global_position
			- self.linear_velocity * self.bind_smooth)
		var distance = direction.length()
		direction = direction.normalized()
		var force = self.bind_force - self.bind_force * 0.5 ** (distance / self.bind_radius)
		print(force)
		self.apply_central_force(direction * force)

		if distance < bind_track_radius and self.anchor.get_parent() is Player:
			var factor = self.bind_track ** delta
			self.linear_velocity *= (1 - factor)
			self.linear_velocity += self.anchor.get_parent().velocity * factor

	for body in $RepellArea.get_overlapping_bodies():
		pass
