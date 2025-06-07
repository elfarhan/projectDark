class_name Goo
extends Node2D

const TWO_PI := 2.0 * PI
const SPRING_CONSTANT := 50#440.0
const DAMPING_COEFF := 1.4
const COM_SPRING_CONSTANT := 600#480.0
const BASE_POINTS := 140.0 # base number of points for the current parameters
const PLAYER_REPULSION_THRESHOLD := 20
const PLAYER_REPULSION_FORCE :=  40.0
const PLAYER_CONTAINMENT_THRESHOLD := 30
const PLAYER_CONTAINMENT_FORCE := 230
const  OCCLUDER_POINT_NUMBER_MULTIPLIER = 20
@export var num_pts := 16
@export var stretched_radius := 220.0
@export var rest_radius := 200.0
var MASS := rest_radius/num_pts*12# 1.0


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
var player_containment_force = Vector2(0.0,0.0)

var scaled_mass: float
var scaled_spring_constant: float
var scaled_com_spring_constant: float
var scaled_player_repulsion: float
var scaled_player_containment: float

func update_scaled_parameters():
	var scale_factor = BASE_POINTS / float(num_pts)
	scaled_mass = MASS * scale_factor
	scaled_spring_constant = SPRING_CONSTANT / scale_factor
	scaled_com_spring_constant = COM_SPRING_CONSTANT * scale_factor
	scaled_player_repulsion = PLAYER_REPULSION_FORCE * scale_factor
	scaled_player_containment = PLAYER_CONTAINMENT_FORCE * scale_factor

func initialize(player: Node2D, anchor: Node2D = null, fixed_anchor_point: Vector2 = Vector2.INF) -> void:
	player_node = player
	update_scaled_parameters()
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
		#_draw()
		for i in range(num_pts):
			velocities[i] = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * delta
		first_step = false

	var hooke_forces = _compute_hooke_forces()
	var drag_force = _compute_com_drag_force()
	var player_force = _compute_player_repulsion_force()
	var damping_forces = _compute_damping_forces()
	player_containment_force = _compute_player_containment_force()
	for i in range(num_pts):
		var total_force = hooke_forces[i] + damping_forces[i] + drag_force[i] + player_force[i]
		var acceleration = total_force / scaled_mass
		velocities[i] += acceleration * delta
		points[i] += velocities[i] * delta

	_update_occluder_polygon()
	#queue_redraw()

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
		var force0 = scaled_spring_constant * (len0 - spring_length) * dir0
		var force1 = scaled_spring_constant * (len1 - spring_length) * dir1
		forces.append(force0 + force1)
	return forces

func _compute_com_drag_force() -> Array:
	var com_local = _get_center_of_mass()
	var com_global = self.to_global(com_local)

	# Make sure anchor_point is in global space
	var displacement = anchor_point - com_global

	var com_force = scaled_com_spring_constant * displacement
	var force_per_point = com_force / num_pts

	var forces := []
	for i in range(num_pts):
		forces.append(force_per_point)
	return forces

	
func _compute_player_repulsion_force() -> Array:
	var forces := []
	var player_pos = player_node.global_position
	var global_points := []
	for pt in points:
		global_points.append(to_global(pt))
	
	var is_inside = _is_point_inside_polygon(player_pos, global_points)
	var SPRING_RANGE = scaled_player_repulsion
	var SPRING_FORCE = PLAYER_REPULSION_THRESHOLD
	
	for i in range(num_pts):
		var current_point = global_points[i]
		var next_point = global_points[(i + 1) % num_pts]
		
		# Find closest point on edge segment
		var edge_vec = next_point - current_point
		var edge_length = edge_vec.length()
		var edge_dir = edge_vec.normalized()
		var player_to_current = player_pos - current_point
		var projection = player_to_current.dot(edge_dir)
		var closest_point = current_point + edge_dir * clamp(projection, 0, edge_length)
		var distance_to_edge = player_pos.distance_to(closest_point)
		
		if distance_to_edge < SPRING_RANGE:
			# Spring calculation (push player away, pull point toward player)
			var displacement = SPRING_RANGE - distance_to_edge
			var force_magnitude = displacement * SPRING_FORCE
			var force_dir = (player_pos - closest_point).normalized()
			
			# Reverse direction if outside
			if !is_inside:
				force_dir = -force_dir
			
			forces.append(-force_dir * force_magnitude) # Point force (opposite direction)
		else:
			forces.append(Vector2.ZERO)
	
	return forces

func _compute_player_containment_force() -> Vector2:
	var player_pos = player_node.global_position
	var total_force = Vector2.ZERO
	var global_points := []
	for pt in points:
		global_points.append(to_global(pt))
	
	var is_inside = _is_point_inside_polygon(player_pos, global_points)
	var SPRING_RANGE = PLAYER_CONTAINMENT_THRESHOLD
	var SPRING_FORCE = scaled_player_containment
	
	for i in range(num_pts):
		var current_point = global_points[i]
		var next_point = global_points[(i + 1) % num_pts]
		
		# Find closest point on edge segment
		var edge_vec = next_point - current_point
		var edge_length = edge_vec.length()
		var edge_dir = edge_vec.normalized()
		var player_to_current = player_pos - current_point
		var projection = player_to_current.dot(edge_dir)
		var closest_point = current_point + edge_dir * clamp(projection, 0, edge_length)
		var distance_to_edge = player_pos.distance_to(closest_point)
		
		if distance_to_edge < SPRING_RANGE && is_inside:
			# Spring calculation (push player inward)
			var displacement = SPRING_RANGE - distance_to_edge
			var force_magnitude = displacement * SPRING_FORCE
			var force_dir = -(closest_point - player_pos).normalized() # Inward direction
			total_force += force_dir * force_magnitude
	
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


func _create_occluder_polygon() -> PackedVector2Array:
	var polygon = PackedVector2Array()
	for i in range(num_pts):
		polygon.append(points[i])
	polygon.append(points[0])
	return polygon

func merge(other_band: Goo) -> Goo:
	# Create new merged band
	var merged_band = Goo.new()
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
	var band1 = Goo.new()
	var band2 = Goo.new()

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


#func _update_occluder_polygon() -> void:
	# Reuse the same polygon array by modifying it in-place
#	var polygon = occluder_polygon.polygon
#	polygon.resize(0)  # Clear existing points
#	
#	for i in range(num_pts):
#		polygon.append(points[i])
#	
#	polygon.append(points[0])
#	
#	# Assign back to the polygon
#	occluder_polygon.polygon = polygon

func _update_occluder_polygon() -> void:
	if num_pts < 2:
		return  # Need at least 2 points for a curve
		
	# Create a new empty polygon array
	var new_polygon = PackedVector2Array()
	
	# Parameters for curve resolution
	var curve_steps := OCCLUDER_POINT_NUMBER_MULTIPLIER	# Number of points between original vertices
	var tension := 0.5		# Controls curve tightness (0.0-1.0)
	
	# We'll create a closed cubic Bezier curve
	for i in range(num_pts):
		var p0 = points[(i - 1 + num_pts) % num_pts]
		var p1 = points[i]
		var p2 = points[(i + 1) % num_pts]
		var p3 = points[(i + 2) % num_pts]
		
		# Calculate control points for cubic Bezier
		var cp1 = p1 + (p2 - p0) * tension / 6.0
		var cp2 = p2 - (p3 - p1) * tension / 6.0
		
		# Add points along the curve segment
		for j in range(curve_steps):
			var t = float(j) / curve_steps
			var q = cubic_bezier(p1, cp1, cp2, p2, t)
			new_polygon.append(q)
	
	# Close the polygon by adding the first point again
	if new_polygon.size() > 0:
		new_polygon.append(new_polygon[0])
	
	# Assign the new polygon to the occluder
	occluder_polygon.polygon = new_polygon

# Cubic Bezier curve function
func cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var tt = t * t
	var ttt = tt * t
	var u = 1.0 - t
	var uu = u * u
	var uuu = uu * u
	
	var q = uuu * p0
	q += 3 * uu * t * p1
	q += 3 * u * tt * p2
	q += ttt * p3
	
	return q
