class_name CornerHandlerComponent
extends Component

export var wall_check_distance: float = 50.0  # Increased from previous value
export var slide_force_multiplier: float = 1.5
export var wall_approach_threshold: float = 30.0
export var num_feelers: int = 8  # More raycasts for better detection

var raycasts: Array = []
var movement_component: MovementComponent
var is_near_wall: bool = false
var wall_normal: Vector2 = Vector2.ZERO

func _init(entity: Node).(entity):
	pass

func initialize():
	# Setup raycasts in a semicircle
	for i in range(num_feelers):
		var raycast = RayCast2D.new()
		raycast.enabled = true
		raycast.collision_mask = 1
		entity.add_child(raycast)
		raycasts.append(raycast)
	
	# Wait one frame to ensure other components are initialized
	yield(entity.get_tree(), "idle_frame")
	movement_component = entity.get_component("movement")
	
	if not movement_component:
		push_error("CornerHandler: MovementComponent not found!")

func update(_delta: float):
	if not movement_component:
		return
		
	var movement_direction = movement_component.get_movement_direction()
	if movement_direction == Vector2.ZERO:
		return
	
	update_wall_detection(movement_direction)
	
	if is_near_wall:
		handle_wall_sliding(movement_direction)

func update_wall_detection(movement_direction: Vector2):
	is_near_wall = false
	wall_normal = Vector2.ZERO
	var closest_distance = wall_check_distance
	
	# Cast rays in a semicircle in front of movement direction
	for i in range(num_feelers):
		var angle = (float(i) / (num_feelers - 1)) * PI - PI/2
		var ray_direction = movement_direction.rotated(angle)
		var raycast = raycasts[i]
		
		raycast.cast_to = ray_direction * wall_check_distance
		raycast.force_raycast_update()
		
		if raycast.is_colliding():
			var collision_point = raycast.get_collision_point()
			var distance = entity.global_position.distance_to(collision_point)
			
			if distance < closest_distance:
				closest_distance = distance
				is_near_wall = true
				wall_normal = raycast.get_collision_normal()

func handle_wall_sliding(movement_direction: Vector2):
	if wall_normal == Vector2.ZERO:
		return
	
	# Calculate slide direction along the wall
	var slide_direction = movement_direction.slide(wall_normal)
	
	# Calculate distance factor (closer to wall = stronger slide force)
	var distance_to_wall = get_closest_wall_distance()
	var distance_factor = 1.0 - clamp(distance_to_wall / wall_approach_threshold, 0.0, 1.0)
	
	# Calculate final slide force
	var slide_force = slide_direction * movement_component.acceleration * slide_force_multiplier * (1.0 + distance_factor)
	
	# Add some "bounce" force to prevent getting too close to the wall
	var bounce_force = wall_normal * movement_component.acceleration * distance_factor
	
	# Apply combined forces
	movement_component.apply_force(slide_force + bounce_force, MovementComponent.PRIORITY_HIGH)
	
	# Adjust movement speed based on how parallel we are to the wall
	var parallel_factor = abs(movement_direction.dot(wall_normal))
	movement_component.multiplier = lerp(1.0, 0.7, parallel_factor)

func get_closest_wall_distance() -> float:
	var min_distance = wall_check_distance
	
	for raycast in raycasts:
		if raycast.is_colliding():
			var distance = entity.global_position.distance_to(raycast.get_collision_point())
			min_distance = min(min_distance, distance)
	
	return min_distance

func get_wall_status() -> bool:
	return is_near_wall

