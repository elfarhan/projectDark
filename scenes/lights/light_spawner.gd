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
	$SpawnTimer.stop()
	add_child(Light.create(self.light_radius, self.light_time_limit))

func mark_picked_up():
	if self.respawn:
		$SpawnTimer.start(self.delay)
