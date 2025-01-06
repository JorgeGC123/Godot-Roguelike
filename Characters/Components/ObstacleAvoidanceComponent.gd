class_name ObstacleAvoidanceComponent
extends Component

export var avoid_distance: float = 60.0
export var avoid_force: float = 60.0
export var num_rays: int = 16
export var ray_angle: float = PI * 1.5
export var memory_duration: float = 20.0 # How long to remember obstacles
export var stuck_threshold: float = 0.5 # Distance to consider entity as stuck
export var stuck_time_threshold: float = 1 # Time before considering entity as stuck
export var unstuck_force: float = 200.0 # Force to apply when stuck

var raycast: RayCast2D
var movement_component: MovementComponent
var detection_component: DetectionComponent
var health_component: HealthComponent
var influence_reduction_timer: Timer
var current_influence: float = 1.0
var obstacle_memory: Array = []
var last_position: Vector2
var stuck_time: float = 0.0
var last_velocity: Vector2 = Vector2.ZERO

# Dynamic ray length properties
var min_ray_length: float = 30.0
var max_ray_length: float = 90.0
var velocity_ray_scale: float = 0.5 # How much velocity affects ray length

# optimizacion
export var processing_range: float = 200.0
export var reduced_rays_distance: float = 150.0
export var reduced_rays_count: int = 8

func _init(entity: Node).(entity):
	pass

func initialize():
	raycast = RayCast2D.new()
	raycast.enabled = true
	entity.add_child(raycast)

	detection_component = entity.get_component("detection")
	movement_component = entity.get_component("movement")
	health_component = entity.get_component("health")
	last_position = entity.global_position
	
	influence_reduction_timer = Timer.new()
	influence_reduction_timer.one_shot = true
	influence_reduction_timer.connect("timeout", self, "_on_influence_reduction_timeout")
	add_child(influence_reduction_timer)
	
	if health_component:
		health_component.connect("stun_started", self, "_on_stun_started")

func update(delta: float):
	if health_component.is_stunned:
		return

	var current_velocity = movement_component.get_velocity()
	var current_position = entity.global_position
	
	# Early return if no detection component or player
	if not detection_component or not detection_component.get_player():
		return

	# Get distance to player
	var distance_to_player = entity.global_position.distance_to(detection_component.get_player().global_position)
	
	# Skip processing if too far
	if distance_to_player > processing_range:
		return

	# Update stuck detection
	if current_position.distance_to(last_position) < stuck_threshold:
		stuck_time += delta
	else:
		stuck_time = 0.0
	
	# Calculate steering forces
	var ray_count = _get_dynamic_ray_count(distance_to_player)
	var steering = calculate_avoidance_forces(current_velocity, ray_count)
	
	# Handle stuck state
	if stuck_time > stuck_time_threshold:
		steering += calculate_unstuck_force()
	
	# Apply final steering force
	if steering.length() > 0:
		movement_component.apply_force(steering * current_influence, MovementComponent.PRIORITY_HIGH)
	
	# Update memory and position
	update_obstacle_memory(delta)
	last_position = current_position
	last_velocity = current_velocity

func _get_dynamic_ray_count(distance: float) -> int:
	var count = num_rays
	if distance > reduced_rays_distance:
		count = reduced_rays_count
	return int(clamp(count, 4, 16))  # Cast to int

func calculate_avoidance_forces(current_velocity: Vector2, ray_count: int) -> Vector2:
	var steering = Vector2.ZERO
	var obstacle_count = 0
	var forward_direction = current_velocity.normalized()
	if forward_direction == Vector2.ZERO:
		forward_direction = Vector2.RIGHT # Default direction if not moving

	# Calculate base ray length based on velocity
	var base_ray_length = clamp(
		min_ray_length + current_velocity.length() * velocity_ray_scale,
		min_ray_length,
		max_ray_length
	)

	# Cast rays in a dynamic arc
	for i in range(ray_count):
		var angle = (float(i) / ray_count) * ray_angle - ray_angle / 2
		var ray_direction = forward_direction.rotated(angle)
		var ray_length = base_ray_length * (1.0 - 0.3 * abs(angle) / (ray_angle / 2))
		
		raycast.cast_to = ray_direction * ray_length
		raycast.force_raycast_update()

		if raycast.is_colliding():
			var collision_point = raycast.get_collision_point()
			var avoid_vector = entity.global_position - collision_point
			var distance = avoid_vector.length()
			var weight = 1.0 - (distance / ray_length) # Higher weight for closer obstacles
			steering += avoid_vector.normalized() * avoid_force * weight
			remember_obstacle(collision_point)
			obstacle_count += 1

	# Consider remembered obstacles
	for obstacle in obstacle_memory:
		var avoid_vector = entity.global_position - obstacle.position
		var distance = avoid_vector.length()
		if distance < avoid_distance:
			var weight = (1.0 - distance / avoid_distance) * obstacle.influence
			steering += avoid_vector.normalized() * avoid_force * weight * 0.5

	if obstacle_count > 0:
		steering = steering.normalized() * avoid_force

	return steering

func calculate_unstuck_force() -> Vector2:
	# Try different directions to get unstuck
	var test_directions = [
		Vector2.UP,
		Vector2.UP + Vector2.RIGHT,
		Vector2.UP + Vector2.LEFT,
		Vector2.RIGHT,
		Vector2.LEFT
	]
	
	for direction in test_directions:
		raycast.cast_to = direction.normalized() * avoid_distance
		raycast.force_raycast_update()
		
		if !raycast.is_colliding():
			return direction.normalized() * unstuck_force
	
	# If all directions are blocked, try to move away from the nearest obstacle
	var nearest_obstacle_dir = Vector2.ZERO
	var nearest_distance = INF
	
	for obstacle in obstacle_memory:
		var distance = entity.global_position.distance_to(obstacle.position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_obstacle_dir = (entity.global_position - obstacle.position).normalized()
	
	return nearest_obstacle_dir * unstuck_force

func remember_obstacle(position: Vector2):
	var obstacle = {
		"position": position,
		"time": OS.get_ticks_msec() / 1000.0,
		"influence": 1.0
	}
	obstacle_memory.append(obstacle)

func update_obstacle_memory(delta: float):
	var current_time = OS.get_ticks_msec() / 1000.0
	var updated_memory = []
	
	for obstacle in obstacle_memory:
		var age = current_time - obstacle.time
		if age < memory_duration:
			# Reduce influence over time
			obstacle.influence = 1.0 - (age / memory_duration)
			updated_memory.append(obstacle)
	
	obstacle_memory = updated_memory

func _on_stun_started(duration: float):
	current_influence = 0.1 # Reduce the influence to 10%
	influence_reduction_timer.start(duration + 0.5)

func _on_influence_reduction_timeout():
	current_influence = 1.0 # Restore full influence

func is_obstacle_to_player() -> bool:
	var player = entity.get_component("detection").get_player()
	if not player:
		return false
	
	var direction_to_player = (player.global_position - entity.global_position).normalized()
	raycast.cast_to = direction_to_player * avoid_distance
	raycast.force_raycast_update()
	
	return raycast.is_colliding() and not raycast.get_collider().is_in_group("player")

func _exit_tree():
	if is_instance_valid(raycast):
		raycast.queue_free()
	if is_instance_valid(influence_reduction_timer):
		influence_reduction_timer.queue_free()
