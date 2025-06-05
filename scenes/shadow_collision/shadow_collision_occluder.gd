class_name ShadowCollisionRadius
extends Node2D

var lights;

@onready var body: StaticBody2D = StaticBody2D.new()
@onready var collider: CollisionPolygon2D = CollisionPolygon2D.new()

@onready var start: Vector2 = self.position
@onready var end: Vector2 = self.position + $End.position

func _ready():
	self.add_child(body)
	body.add_child(collider)

func _physics_process(delta):
	self.lights = get_lights()
	if len(lights) == 0:
		push_warning("ShadowCollisionSource without Light2d")
		return
	
	for light in self.lights:
		var origin = light.global_position - self.global_position
		var radius = light.radius
		
		var dir1 
	

func find_lights(node: Node, array := []):
	if node is ShadowCollisionRadius:
		array.push_back(node)
	for child in node.get_children():
		find_lights(child, array)
	return array
	
func get_lights():
	var root = get_tree().get_root()
	var lights = find_lights(root)
	
