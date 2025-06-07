extends Node2D

@onready var player_node = $"../Player"
var goo = Goo.new()
func _ready():
	add_to_group("goo")
	# When added to the scene, set up using own position as anchor
	if player_node == null:
		player_node = get_tree().get_root().get_node("Main/Player")  # Adjust path!
	goo.initialize(player_node, $"../Light", $"../Light".global_position)
	
	add_child(goo)

func _physics_process(delta: float) -> void:
	goo.update_physics(delta)
	

	
func get_goo_force():
	return goo.player_containment_force
