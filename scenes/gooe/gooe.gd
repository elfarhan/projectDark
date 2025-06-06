extends Node2D

const TWO_PI := 2.0 * PI
const SPRING_CONSTANT := 440.0
const DAMPING_COEFF := 1.4
const COM_SPRING_CONSTANT := 480.0
const MASS := 1.0
const PLAYER_REPULSION_THRESHOLD := 0.1
const PLAYER_REPULSION_FORCE :=  1950.0

@export var num_pts := 146
@export var stretched_radius := 260.0
@export var rest_radius := 250.0
@onready var anchor_point = $"../Player".position

var points = []
var velocities = []
var spring_length = 0.0
var first_step := true

var occluder_polygon = OccluderPolygon2D.new()
var light_occluder = LightOccluder2D.new()

func _ready():
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
	occluder_polygon.polygon = _create_occluder_polygon()
	occluder_polygon.closed = true
	occluder_polygon.cull_mode = OccluderPolygon2D.CULL_DISABLED
	
	light_occluder.occluder = occluder_polygon
	add_child(light_occluder)

func _physics_process(delta):
	anchor_point = $"../Player".position
	#rest_radius =-delta
	if first_step:
		for i in range(num_pts):
			velocities[i] = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * delta
		first_step = false

	var hooke_forces = _compute_hooke_forces()
	var drag_force = _compute_com_drag_force()
	var player_force = _compute_player_repulsion_force()
	var damping_forces = []
	for i in range(num_pts):
		damping_forces.append(-DAMPING_COEFF * velocities[i])

	for i in range(num_pts):
		var total_force = hooke_forces[i] + damping_forces[i] + drag_force[i] + player_force[i]
		var acceleration = total_force / MASS
		velocities[i] += acceleration * delta
		points[i] += velocities[i] * delta
	
	occluder_polygon.polygon = _create_occluder_polygon()
	queue_redraw()

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
	var com = Vector2.ZERO
	for pt in points:
		com += pt
	com /= num_pts
	var displacement = anchor_point - com
	var com_force = COM_SPRING_CONSTANT * displacement
	var force_per_point = com_force / num_pts
	
	var forces := []
	for i in range(num_pts):
		forces.append(force_per_point)
	return forces

func _compute_player_repulsion_force() -> Array:
	var forces := []
	var player_pos = $"../Player".position
	var com = _get_center_of_mass()
	#print(com-player_pos)
	
	for i in range(num_pts):
		var point = points[i]
		var to_player = player_pos - point
		var distance_to_player = to_player.length()
		var distance_point_to_com = point.distance_to(com)

		var activation_threshold = distance_point_to_com * 0.99

		if abs(distance_to_player) / abs(distance_point_to_com) < 0.2:
			print(abs(distance_to_player) / abs(distance_point_to_com))
			var proximity_ratio = clamp(1.0 - (distance_to_player / activation_threshold), 0.0, 1.0)
			var force_magnitude = PLAYER_REPULSION_FORCE * proximity_ratio
			forces.append(-to_player.normalized() * force_magnitude)  # push outward
		else:
			forces.append(Vector2.ZERO)

	return forces




func _get_center_of_mass() -> Vector2:
	var com = Vector2.ZERO
	for pt in points:
		com += pt
	return com / num_pts

func _draw():
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

func _compute_player_containment_force() -> Vector2:
	var player_pos = $"../Player".position
	var total_force = Vector2.ZERO
	
	# First check if player is inside the polygon
	if !_is_point_inside_polygon(player_pos, points):
		return Vector2.ZERO
	
	var com = _get_center_of_mass()
	var avg_distance_to_com = 0.0
	
	# Calculate average distance to COM for scaling
	for pt in points:
		avg_distance_to_com += pt.distance_to(com)
	avg_distance_to_com /= num_pts
	
	for i in range(num_pts):
		var point = points[i]
		var to_player = player_pos - point
		var distance_to_player = to_player.length()
		
		# Use 10% of average COM distance as threshold
		var threshold = avg_distance_to_com * 0.2
		
		if abs(distance_to_player) / abs(avg_distance_to_com) < 0.1:
			# Strong repulsion when very close to edge
			print("force")
			var t = distance_to_player / threshold
			var force_magnitude = PLAYER_REPULSION_FORCE * (1.0 - t)
			total_force += to_player.normalized() *20000
		else:
			# Gentle push toward center when deeper inside
			var to_center = com - player_pos
			var force_magnitude = PLAYER_REPULSION_FORCE * 0.5  # Weaker force
			total_force += to_center.normalized() * 0
	
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
	

func _update_occluder_polygon() -> void:
	# Reuse the same polygon array by modifying it in-place
	var polygon = occluder_polygon.polygon
	polygon.resize(0)  # Clear existing points
	
	for i in range(num_pts):
		polygon.append(points[i])
	
	polygon.append(points[0])
	
	# Assign back to the polygon
	occluder_polygon.polygon = polygon
