class_name LightSpawner
extends Node2D

@export_range(0, 2048, 8) var light_radius = 256
@export var respawn = true
@export_range(0, 300) var delay = 0
@export var light_time_limit = 0

const light_scene: PackedScene = preload("res://scenes/lights/Light.tscn")

func _ready():
	$SpawnTimer.start(0.1)

func _on_spawn_timer_timeout():
	print("light spawned")
	$SpawnTimer.stop()
	var light = light_scene.instantiate()
	light.radius = self.light_radius
	light.time_limit = self.light_time_limit
	add_child(light)

func mark_picked_up():
	if self.respawn:
		print("light respawn timer started")
		$SpawnTimer.start(self.delay)
