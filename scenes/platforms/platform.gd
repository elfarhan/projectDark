extends StaticBody2D

func _ready():
	var occluder = LightOccluder2D.new()
	occluder.occluder = OccluderPolygon2D.new()
	occluder.occluder.cull_mode = 2
	occluder.occluder.polygon = $CollisionPolygon2D.polygon
	self.add_child(occluder)
