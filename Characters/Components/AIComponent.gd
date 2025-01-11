class_name AIComponent
extends Component

var navigation: Navigation2D
var player: KinematicBody2D
var path: PoolVector2Array = []
var movement_component: MovementComponent
var debug_line: Line2D

export var path_update_interval: float = 0.5
export var arrival_threshold: float = 5.0
export var check_distance: float = 16.0 # Distancia entre puntos de comprobación
export var debug_draw_path: bool = true

var nav_agent: RID

var path_update_timer: float = 0.0
var last_valid_position: Vector2 = Vector2.ZERO

# Colores debug
const COLOR_VALID_PATH := Color(0, 0, 1, 0.5)
const COLOR_INVALID_PATH := Color(1, 0, 0, 0.5)

func _init(entity: Node).(entity):
	pass

func initialize():

	player = entity.get_node("/root/Game/Player")
	movement_component = entity.get_component("movement")
	
	nav_agent = Navigation2DServer.agent_create();
	Navigation2DServer.agent_set_map(nav_agent,NavigationManager.nav_map)
	# Configurar debug si está activo
	if debug_draw_path:
		debug_line = Line2D.new()
		debug_line.default_color = COLOR_VALID_PATH
		debug_line.width = 2.0
		add_child(debug_line)
	

func update(delta: float):
	if not player or not movement_component:
		return

	path_update_timer += delta
	if path_update_timer >= path_update_interval:
		path_update_timer = 0.0
		_update_path()

	if not path.empty():
		_follow_path()

	if debug_draw_path:
		_update_debug_line()

func is_point_valid(point: Vector2) -> bool:
	"""
	Verifica si un punto está dentro del área navegable
	"""
	var closest = Navigation2DServer.map_get_closest_point(NavigationManager.nav_map, point)
	var owner_rid = Navigation2DServer.map_get_closest_point_owner(NavigationManager.nav_map, point)
	if owner_rid != RID():
		print("cost")
		print(Navigation2DServer.region_get_travel_cost(owner_rid))
	
	# Un punto es válido si:
	# 1. Está cerca del punto más cercano en el navigation mesh
	# 2. Pertenece a una región válida (owner_rid no es nulo)
	return closest.distance_to(point) < 1.0 and owner_rid != RID()

func find_intermediate_points(start: Vector2, end: Vector2) -> Array:
	"""
	Encuentra puntos intermedios válidos entre dos puntos
	"""
	var points = []
	var diff = end - start
	var distance = diff.length()
	var steps = int(distance / check_distance)
	
	if steps == 0:
		return points
		
	# Añadir puntos en las cuatro direcciones cardinales
	var directions = [
		Vector2(check_distance, 0),
		Vector2(-check_distance, 0),
		Vector2(0, check_distance),
		Vector2(0, -check_distance)
	]
	
	var best_point = null
	var best_distance = INF
	
	for dir in directions:
		var test_point = start + dir
		if is_point_valid(test_point):
			var new_distance = test_point.distance_to(end)
			if new_distance < best_distance and new_distance < distance:
				best_distance = new_distance
				best_point = test_point
	
	if best_point:
		points.append(best_point)
		# Recursivamente encontrar más puntos
		points.append_array(find_intermediate_points(best_point, end))
	
	return points

func calculate_path_with_waypoints(start: Vector2, end: Vector2) -> PoolVector2Array:
	"""
	Calcula un path usando waypoints si es necesario
	"""
	# Intentar primero un path directo
	var direct_path = Navigation2DServer.map_get_path(
		NavigationManager.nav_map,
		start,
		end,
		true,
		1
	)
	
	# Verificar si el path directo es válido
	var is_valid = true
	for i in range(direct_path.size() - 1):
		var segment_start = direct_path[i]
		var segment_end = direct_path[i + 1]
		var diff = segment_end - segment_start
		var steps = int(diff.length() / check_distance)
		
		for step in range(steps):
			var t = float(step) / steps
			var check_point = segment_start.linear_interpolate(segment_end, t)
			if not is_point_valid(check_point):
				is_valid = false
				break
				
		if not is_valid:
			break
	
	if is_valid:
		return direct_path
	
	# Si el path directo no es válido, usar waypoints
	var final_path = PoolVector2Array()
	final_path.append(start)
	
	var waypoints = find_intermediate_points(start, end)
	for point in waypoints:
		final_path.append(point)
	
	final_path.append(end)
	
	# Limpiar el path resultante
	return cleanup_path(final_path)

func cleanup_path(raw_path: PoolVector2Array) -> PoolVector2Array:
	"""
	Limpia el path eliminando puntos innecesarios
	"""
	if raw_path.size() <= 2:
		return raw_path
		
	var cleaned_path = PoolVector2Array()
	cleaned_path.append(raw_path[0])
	
	var i = 1
	while i < raw_path.size() - 1:
		var prev = cleaned_path[cleaned_path.size() - 1]
		var current = raw_path[i]
		var next = raw_path[i + 1]
		
		# Si el punto actual no es necesario para la navegación, lo saltamos
		if not is_waypoint_necessary(prev, current, next):
			i += 1
			continue
			
		cleaned_path.append(current)
		i += 1
	
	cleaned_path.append(raw_path[raw_path.size() - 1])
	return cleaned_path

func is_waypoint_necessary(prev: Vector2, current: Vector2, next: Vector2) -> bool:
	"""
	Determina si un waypoint es necesario para la navegación
	"""
	# Comprobar si podemos ir directamente de prev a next
	var direct_path = Navigation2DServer.map_get_path(
		NavigationManager.nav_map,
		prev,
		next,
		true  # optimize parameter
	)
	if direct_path.size() <= 2:
		return false
		
	# Comprobar si el punto actual está significativamente fuera de la línea
	var line_point = prev.linear_interpolate(next, prev.distance_to(current) / prev.distance_to(next))
	return current.distance_to(line_point) > check_distance

func _update_path():
	"""
	Actualiza el path usando el sistema de waypoints
	"""
	if not is_instance_valid(player):
		return

	var new_path = calculate_path_with_waypoints(
		entity.global_position,
		player.global_position
	)
	
	if new_path.size() >= 2:
		path = new_path
		if debug_draw_path:
			debug_line.default_color = COLOR_VALID_PATH
	else:
		path = PoolVector2Array()
		if debug_draw_path:
			debug_line.default_color = COLOR_INVALID_PATH


func _follow_path():
	if path.empty():
		movement_component.stop()
		return

	var target = path[0]
	var distance = entity.global_position.distance_to(target)
	
	if distance < arrival_threshold:
		path.remove(0)
		if path.empty():
			movement_component.stop()
			return
		target = path[0]
	
	var direction = (target - entity.global_position).normalized()
	var current_velocity = movement_component.get_velocity()
	var target_velocity = direction * movement_component.default_speed
	
	# print("Current velocity: ", current_velocity)
	# print("Setting target velocity: ", target_velocity)
	
	# Movimiento directo como fallback
	movement_component.set_movement_direction(direction)

func _update_debug_line() -> void:
	"""
	Actualiza la visualización del debug
	"""
	var points = PoolVector2Array()
	points.append(entity.global_position)
	
	for point in path:
		points.append(point)
	
	debug_line.points = points
