class_name Gooe
extends Node2D

const TWO_PI := 2.0 * PI
const SPRING_CONSTANT := 440.0
const DAMPING_COEFF := 1.4
const COM_SPRING_CONSTANT := 480.0
const MASS := 1.0
const PLAYER_REPULSION_THRESHOLD := 0.1
const PLAYER_REPULSION_FORCE :=  4350.0

@export var num_pts := 146
@export var stretched_radius := 160.0
@export var rest_radius := 150.0


var points = []
var velocities = []
var spring_length = 0.0
var first_step := true

var occluder_polygon: OccluderPolygon2D
var light_occluder: LightOccluder2D
var player_node : Node2D
var anchor_node: Node2D = null
var anchor_point: Vector2
var follow_anchor_node := false

func initialize(player: Node2D, anchor: Node2D = null, fixed_anchor_point: Vector2 = Vector2.INF) -> void:
	player_node = player
	if anchor != null:
		anchor_node = anchor
		follow_anchor_node = true
		anchor_point = anchor.global_position
	elif fixed_anchor_point != Vector2.INF:
		follow_anchor_node = false
		anchor_point = fixed_anchor_point

	# Compute rest length of each spring
	spring_length = (TWO_PI * rest_radius) / num_pts
	velocities.resize(num_pts)
	points.resize(num_pts)
	var theta_step = TWO_PI / num_pts
	for i in range(num_pts):
		var angle = i * theta_step
		var r = stretched_radius + randf_range(-5, 5)  # simulate Gaussian randomness
		var pos = Vector2(r * cos(angle), r * sin(angle))
		points[i] = pos
		velocities[i] = Vector2.ZERO

	# Set up occluder
	occluder_polygon = OccluderPolygon2D.new()
	occluder_polygon.polygon = _create_occluder_polygon()
	occluder_polygon.closed = true
	occluder_polygon.cull_mode = OccluderPolygon2D.CULL_DISABLED

	light_occluder = LightOccluder2D.new()
	light_occluder.occluder = occluder_polygon
	add_child(light_occluder)

func update_physics(delta: float) -> void:
	if follow_anchor_node and anchor_node:
		anchor_point = anchor_node.global_position

	if first_step:
		_draw()
		for i in range(num_pts):
			velocities[i] = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * delta
		first_step = false

	var hooke_forces = _compute_hooke_forces()
	var drag_force = _compute_com_drag_force()
	var player_force = _compute_player_repulsion_force()
	var damping_forces = _compute_damping_forces()
	for i in range(num_pts):
		var total_force = hooke_forces[i] + damping_forces[i] + drag_force[i] + player_force[i]
		var acceleration = total_force / MASS
		velocities[i] += acceleration * delta
		points[i] += velocities[i] * delta

	_update_occluder_polygon()
	queue_redraw()

func _compute_damping_forces() -> Array:
	var damping_forces = []
	for i in range(num_pts):
		damping_forces.append(-DAMPING_COEFF * velocities[i])
	return damping_forces
	
func _compute_hooke_forces() -> Array:
	var forces = []
	for i in range(num_pts):
		var prev_i = (i - 1 + num_pts) % num_pts
		var next_i = (i + 1) % num_pts
		var point = points[i]
		var prev_pt = points[prev_i]
		var next_pt = points[next_i]

		var dir0 = prev_pt - point
		var len0 = dir0.length()
		dir0 = dir0.normalized()

		var dir1 = next_pt - point
		var len1 = dir1.length()
		dir1 = dir1.normalized()

		spring_length = (TWO_PI * rest_radius) / num_pts
		var force0 = SPRING_CONSTANT * (len0 - spring_length) * dir0
		var force1 = SPRING_CONSTANT * (len1 - spring_length) * dir1
		forces.append(force0 + force1)
	return forces

func _compute_com_drag_force() -> Array:
	var com_local = _get_center_of_mass()
	var com_global = self.to_global(com_local)

	# Make sure anchor_point is in global space
	var displacement = anchor_point - com_global

	var com_force = COM_SPRING_CONSTANT * displacement
	var force_per_point = com_force / num_pts

	var forces := []
	for i in range(num_pts):
		forces.append(force_per_point)
	return forces

	
func _compute_player_repulsion_force() -> Array:
	var forces := []
	var player_pos = player_node.global_position
	var com_local = _get_center_of_mass()
	var com_global = self.to_global(com_local)

	for i in range(num_pts):
		var point_local = points[i]
		var point_global = self.to_global(point_local)

		var to_player = player_pos - point_global
		var distance_to_player = to_player.length()
		var distance_point_to_com = point_global.distance_to(com_global)

		var activation_threshold = distance_point_to_com * 0.99

		if abs(distance_to_player) / abs(distance_point_to_com) < 0.2:
			var proximity_ratio = clamp(1.0 - (distance_to_player / activation_threshold), 0.0, 1.0)
			var force_magnitude = PLAYER_REPULSION_FORCE * proximity_ratio
			forces.append(-to_player.normalized() * force_magnitude)  # push outward
		else:
			forces.append(Vector2.ZERO)

	return forces

func _compute_player_containment_force() -> Vector2:
	var player_pos = player_node.global_position
	var total_force = Vector2.ZERO

	# Convert local points to global for the polygon check
	var global_points := []
	for pt in points:
		global_points.append(to_global(pt))
	
	# Check if player is inside the shape in global space
	if !_is_point_inside_polygon(player_pos, global_points):
		return Vector2.ZERO

	var com_global = to_global(_get_center_of_mass())
	var avg_distance_to_com = 0.0

	for pt in global_points:
		avg_distance_to_com += pt.distance_to(com_global)
	avg_distance_to_com /= num_pts

	for i in range(num_pts):
		var point_global = global_points[i]
		var to_player = player_pos - point_global
		var distance_to_player = to_player.length()
		
		var threshold = avg_distance_to_com * 0.2

		if distance_to_player < threshold:
			var t = distance_to_player / threshold
			var force_magnitude = PLAYER_REPULSION_FORCE * (1.0 - t)
			total_force += to_player.normalized() * force_magnitude
		else:
			# Optional: gentle center pull can be added here
			var to_center = com_global - player_pos
			var force_magnitude = PLAYER_REPULSION_FORCE * 0.2
			total_force += to_center.normalized() * force_magnitude
	
	return total_force

func _is_point_inside_polygon(point: Vector2, polygon: Array) -> bool:
	var inside = false
	var n = polygon.size()
	
	for i in range(n):
		var j = (i + 1) % n
		if ((polygon[i].y > point.y) != (polygon[j].y > point.y)):
			var intersect = (polygon[j].x - polygon[i].x) * (point.y - polygon[i].y) / (polygon[j].y - polygon[i].y) + polygon[i].x
			if point.x < intersect:
				inside = !inside
				
	return inside


func _get_center_of_mass() -> Vector2:
	var com = Vector2.ZERO
	for pt in points:
		com += pt
	return com / num_pts

func _draw():
	if points.is_empty():
		return
	for pt in points:
		draw_circle(pt, 2.0, Color.WHITE)
	for i in range(num_pts):
		var next_i = (i + 1) % num_pts
		draw_line(points[i], points[next_i], Color.GREEN, 1.5)

func _create_occluder_polygon() -> PackedVector2Array:
	var polygon = PackedVector2Array()
	for i in range(num_pts):
		polygon.append(points[i])
	polygon.append(points[0])
	return polygon

func merge(other_band: Gooe) -> Gooe:
	# Create new merged band
	var merged_band = Gooe.new()
	print("merging")
	
	# Average properties
	merged_band.num_pts = (num_pts + other_band.num_pts) / 2
	merged_band.rest_radius = (rest_radius + other_band.rest_radius) * 0.75
	merged_band.stretched_radius = (stretched_radius + other_band.stretched_radius) * 0.75
	
	# Calculate midpoint in global space
	var global_midpoint = (global_position + other_band.global_position) * 0.5
	
	# Determine anchor inheritance - prioritize anchored bands
	var new_anchor_node = null
	var new_anchor_point = Vector2.INF
	
	if anchor_node != null:
		new_anchor_node = anchor_node
	elif other_band.anchor_node != null:
		new_anchor_node = other_band.anchor_node
	else:
		new_anchor_point = global_midpoint
	
	# Initialize with proper parameters BEFORE adding to scene
	merged_band.initialize(player_node, new_anchor_node, new_anchor_point)
	
	# Add to scene and set position
	get_parent().add_child(merged_band)
	merged_band.global_position = global_midpoint
	
	# Blend velocities for smoother transition
	for i in range(min(points.size(), merged_band.points.size())):
		merged_band.velocities[i] = (velocities[i] + other_band.velocities[i]) * 0.5
	
	return merged_band


func should_split() -> bool:
	var com = _get_center_of_mass()
	var max_distance = 0.0
	var avg_distance = 0.0

	for pt in points:
		var dist = pt.distance_to(com)
		avg_distance += dist
		if dist > max_distance:
			max_distance = dist

	avg_distance /= num_pts
	return max_distance > avg_distance * 2.0

func split() -> Array:
	# Create two new bands
	var band1 = Gooe.new()
	var band2 = Gooe.new()

	# Configure new bands
	for band in [band1, band2]:
		band.num_pts = num_pts / 2
		band.rest_radius = rest_radius * 0.7
		band.stretched_radius = stretched_radius * 0.7
		band.player_node = player_node
		band.initialize(player_node)

	# Position near original
	band1.position = position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
	band2.position = position + Vector2(randf_range(-30, 30), randf_range(-30, 30))

	return [band1, band2]

func get_bounding_radius() -> float:
	var com = _get_center_of_mass()
	var max_distance = 0.0
	for pt in points:
		var dist = pt.distance_to(com)
		if dist > max_distance:
			max_distance = dist
	return max_distance


func _update_occluder_polygon() -> void:
	# Reuse the same polygon array by modifying it in-place
	var polygon = occluder_polygon.polygon
	polygon.resize(0)  # Clear existing points
	
	for i in range(num_pts):
		polygon.append(points[i])
	
	polygon.append(points[0])
	
	# Assign back to the polygon
	occluder_polygon.polygon = polygon
