extends Node2D

@export var attach_to_node: Node2D = null
@onready var player_node = $"../Player"
var goo = Goo.new()
func _ready():
	add_to_group("goo")
	# When added to the scene, set up using own position as anchor
	if player_node == null:
		player_node = get_tree().get_root().get_node("Main/Player")  # Adjust path!
	if attach_to_node == null:
		goo.initialize(player_node, attach_to_node, global_position)
	else:
		goo.initialize(player_node, attach_to_node)
	
	add_child(goo)

func _physics_process(delta: float) -> void:
	goo.update_physics(delta)
	

	
func get_goo_force():
	return goo.player_containment_force
