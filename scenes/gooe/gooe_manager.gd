extends Node2D

@export var initial_bands := 2
@onready var player = $Player
@onready var light = $light

var rubber_bands: Array = []
var merge_threshold_factor := 1.0

func _ready():
	# Create initial bands
	#for i in range(initial_bands):
	#	create_rubber_band(Vector2(randi_range(0, 900), randi_range(0, 500)))
	#create_rubber_band(player)
	var offset = Vector2(1800, 40)  # Adjust distance as needed
	#create_rubber_band(player)
	create_rubber_band(null, offset+player.global_position)
	create_rubber_band(player)
	# Rubber band anchored to platform2 node
	#create_rubber_band($Platform4)

func create_rubber_band(anchor_node: Node2D = null, anchor_pos: Vector2 = Vector2.INF) -> void:
	var band = Gooe.new()
	add_child(band)
	band.position = anchor_pos if anchor_node == null else anchor_node.position
	band.initialize(player, anchor_node, anchor_pos)
	rubber_bands.append(band)

func _physics_process(delta):
	# Update physics for all bands
	for band in rubber_bands:
		band.update_physics(delta)
	
	# Check for merges
	var bands_to_remove = []
	var bands_to_add = []
	
	for i in range(rubber_bands.size()):
		for j in range(i + 1, rubber_bands.size()):
			var band1 = rubber_bands[i]
			var band2 = rubber_bands[j]
			
			if band1 in bands_to_remove || band2 in bands_to_remove:
				continue
				
			if should_merge(band1, band2):
				var new_band = band1.merge(band2)
				bands_to_add.append(new_band)
				bands_to_remove.append(band1)
				bands_to_remove.append(band2)
	
	# Check for splits
	for band in rubber_bands:
		if band in bands_to_remove:
			continue
			
		if band.should_split():
			var new_bands = band.split()
			bands_to_add.append_array(new_bands)
			bands_to_remove.append(band)
	
	# Update band list
	for band in bands_to_remove:
		rubber_bands.erase(band)
		band.queue_free()
	
	for band in bands_to_add:
		add_child(band)
		rubber_bands.append(band)

func should_merge(band1: Gooe, band2: Gooe) -> bool:
	var com1 = band1.to_global(band1._get_center_of_mass())
	var com2 = band2.to_global(band2._get_center_of_mass())
	var distance = com1.distance_to(com2)
	var threshold = (band1.get_bounding_radius() + band2.get_bounding_radius()) * 0.1  # More lenient
	return distance < threshold



func compute_total_containment_force() -> Vector2:
	var total_force := Vector2.ZERO

	for band in rubber_bands:
		if band.has_method("_compute_player_containment_force"):
			total_force += band._compute_player_containment_force()
	
	return total_force
