class_name AIComponent
extends Component

var navigation: Navigation2D
var player: KinematicBody2D
var path: PoolVector2Array
var path_update_timer: float = 0.0
var path_update_interval: float = 0.2
var stuck_timer: float = 0.0
var stuck_threshold: float = 1.0  # Time before considering we're stuck
var progress_check_distance: float = 20.0  # Distance to check if we're making progress

var movement_component: MovementComponent
var corner_handler: CornerHandlerComponent
var current_path_index: int = 0
var path_point_threshold: float = 10.0
var last_position: Vector2
var wall_influence: float = 0.5  # How much wall sliding affects path following

func _init(entity: Node).(entity):
	pass

func initialize():
	navigation = entity.get_node("/root/Game/Rooms")
	player = entity.get_node("/root/Game/Player")
	
	yield(entity.get_tree(), "idle_frame")
	movement_component = entity.get_component("movement")
	corner_handler = entity.get_component("corner_handler")
	last_position = entity.global_position

func update(delta: float):
	if not player or not navigation:
		return
	
	check_progress(delta)
	
	path_update_timer += delta
	if path_update_timer >= path_update_interval:
		path_update_timer = 0.0
		update_path()
	
	if path and path.size() > 0:
		follow_path(delta)

func check_progress(delta: float):
	# Check if we're making progress towards our goal
	var current_pos = entity.global_position
	var distance_moved = current_pos.distance_to(last_position)
	
	if distance_moved < 1.0:  # If barely moving
		stuck_timer += delta
		if stuck_timer > stuck_threshold:
			# Force path update and increase path update frequency temporarily
			path_update_interval = 0.1
			update_path()
	else:
		stuck_timer = 0.0
		path_update_interval = 0.2
	
	last_position = current_pos

func update_path():
	if player:
		# Add some randomization to pathfinding target when stuck
		var target_pos = player.global_position
		if stuck_timer > stuck_threshold:
			# Add random offset to break from local minima
			target_pos += Vector2(rand_range(-50, 50), rand_range(-50, 50))
		
		var new_path = navigation.get_simple_path(entity.global_position, target_pos, true)
		if new_path.size() > 0:
			path = smooth_path(new_path)
			current_path_index = 0

func smooth_path(original_path: PoolVector2Array) -> PoolVector2Array:
	if original_path.size() <= 2:
		return original_path
	
	var smoothed_path = PoolVector2Array()
	smoothed_path.append(original_path[0])
	
	for i in range(1, original_path.size() - 1):
		var prev = original_path[i - 1]
		var current = original_path[i]
		var next = original_path[i + 1]
		
		# Calculate midpoints for smoother corners
		var mid1 = prev.linear_interpolate(current, 0.75)
		var mid2 = current.linear_interpolate(next, 0.25)
		
		smoothed_path.append(mid1)
		smoothed_path.append(current)
		smoothed_path.append(mid2)
	
	smoothed_path.append(original_path[original_path.size() - 1])
	return smoothed_path

func follow_path(delta: float):
	if current_path_index >= path.size():
		return
	
	var target = path[current_path_index]
	var distance = entity.global_position.distance_to(target)
	
	# Handle wall influence
	var near_wall = corner_handler and corner_handler.get_wall_status()
	
	# Move to next path point if close enough
	if distance < path_point_threshold:
		current_path_index += 1
		if current_path_index >= path.size():
			return
		target = path[current_path_index]
	
	var path_direction = (target - entity.global_position).normalized()
	
	# If near a wall, blend path following with wall sliding
	if near_wall:
		# Let the wall sliding handle most of the movement
		var slide_influence = wall_influence
		path_direction = path_direction * (1.0 - slide_influence)
	
	# Apply the movement
	movement_component.set_movement_direction(path_direction)
