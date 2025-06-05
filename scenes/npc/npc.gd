class_name Npc
extends Area2D

@export_range(4, 128, 4) var needs = 16
@export_range(4, 1024, 8) var radius = 128

func fulfill():
	self.needs = 0
	$LightMarker.add_child(Light.create(self.radius, 0))
