extends Node

const TILE_SIZE = 16
const MAX_ROOM_SIZE = Vector2(15, 15)
const MIN_ROOM_SIZE = Vector2(5, 5)
const WALL_TILE_ID = 2
const LEFT_WALL_TILE_ID = 6
const RIGHT_WALL_TILE_ID = 5
const FLOOR_TILE_ID = 14
const RIGHT_WINDOW_TILE_ID = 8

var rooms = []
var door_scene = preload ("res://Rooms/Furniture and Traps/Door.tscn")
var breakable_torch_scene = preload ("res://Characters/Breakables/Torch/BreakableTorch.tscn")
var clean_light_scene = preload ("res://Characters/Breakables/Torch/CleanLight.tscn")
var god_rays_scene = preload ("res://Godrays/SunGodRays.tscn")

class AdvancedRoom:
	var position: Vector2
	var size: Vector2
	var doors: Array
	var enemies: Array

	func _init(position: Vector2, size: Vector2):
		self.position = position
		self.size = size
		self.doors = []
		self.enemies = []

class BSPNode:
	var position: Vector2
	var size: Vector2
	var left: BSPNode
	var right: BSPNode
	var room: AdvancedRoom

	func _init(position: Vector2, size: Vector2):
		self.position = position
		self.size = size
		self.left = null
		self.right = null
		self.room = null

func generate_random_room() -> DungeonRoom:
	var root = BSPNode.new(Vector2(0, 0), Vector2(50, 50))
	split_space(root)
	var rooms = get_leaf_nodes(root)
	for room_node in rooms:
		room_node.room = create_room(room_node)
	
	# Instancia la primera habitación generada como ejemplo
	return instantiate_room(rooms[0].room)

func split_space(node: BSPNode):
	if node.size.x > MAX_ROOM_SIZE.x * 2 or node.size.y > MAX_ROOM_SIZE.y * 2:
		if node.size.x > node.size.y:
			split_vertically(node)
		else:
			split_horizontally(node)
		split_space(node.left)
		split_space(node.right)

func split_vertically(node: BSPNode):
	var split_x = randi() % int(node.size.x / 2) + int(MIN_ROOM_SIZE.x)
	node.left = BSPNode.new(node.position, Vector2(split_x, node.size.y))
	node.right = BSPNode.new(node.position + Vector2(split_x, 0), Vector2(node.size.x - split_x, node.size.y))

func split_horizontally(node: BSPNode):
	var split_y = randi() % int(node.size.y / 2) + int(MIN_ROOM_SIZE.y)
	node.left = BSPNode.new(node.position, Vector2(node.size.x, split_y))
	node.right = BSPNode.new(node.position + Vector2(0, split_y), Vector2(node.size.x, node.size.y - split_y))

func get_leaf_nodes(node: BSPNode) -> Array:
	if node.left == null and node.right == null:
		return [node]
	else:
		return get_leaf_nodes(node.left) + get_leaf_nodes(node.right)

func create_room(node: BSPNode) -> AdvancedRoom:
	var room_position = node.position + Vector2(randf_range(0, node.size.x - MIN_ROOM_SIZE.x), randf_range(0, node.size.y - MIN_ROOM_SIZE.y))
	var room_size = Vector2(randf_range(MIN_ROOM_SIZE.x, min(MAX_ROOM_SIZE.x, node.size.x)), randf_range(MIN_ROOM_SIZE.y, min(MAX_ROOM_SIZE.y, node.size.y)))
	return AdvancedRoom.new(room_position, room_size)

func instantiate_room(room: AdvancedRoom) -> DungeonRoom:
	var room_scene = load("res://Rooms/RandomDungeonRoom/RandomDungeonRoom.tscn")
	var room_instance = room_scene.instance()
	var room_tilemap = room_instance.get_node("TileMap") as TileMap
	var l_cuttof = Vector2(5, 3) # en caso de que caiga el random de L

	# Añadir la entrada
	var entrance_node = room_instance.get_node("Entrance")
	var door_x_position = randi() % (int(room.size.x) - 4) + 2
	door_x_position = (3)
	var position2d2 = Marker2D.new()
	position2d2.name = "Position2D2"
	position2d2.position = Vector2(door_x_position * TILE_SIZE, room.size.y * TILE_SIZE)
	entrance_node.add_child(position2d2)

	# Añadir la puerta
	var door_instance = door_scene.instance()
	var doors_node = room_instance.get_node("Doors")
	door_instance.position = Vector2(door_x_position * TILE_SIZE, 0)
	doors_node.add_child(door_instance)

	# Añadir BreakableTorch en una posición aleatoria de la pared superior
	var breakable_torch_instance = breakable_torch_scene.instance()
	var torch_x_position = randi() % (int(room.size.x) - 2) + 1
	while torch_x_position == door_x_position:
		torch_x_position = randi() % (int(room.size.x) - 2) + 1
	breakable_torch_instance.position = Vector2(torch_x_position * TILE_SIZE, 6)
	room_instance.add_child(breakable_torch_instance)

	# Añadir la ventana y los godrays
	var margin = max(1, int(room.size.y / 4))
	var central_range_start = margin
	var central_range_end = int(room.size.y) - margin
	var window_y_position = randi() % (central_range_end - central_range_start) + central_range_start
	window_y_position = clamp(window_y_position, 1, int(room.size.y) - 2)
	var clean_light_instance = clean_light_scene.instance()
	var godray_instance = god_rays_scene.instance()
	var window_world_position = room_tilemap.map_to_local(Vector2(l_cuttof.x, window_y_position))
	clean_light_instance.position = window_world_position
	godray_instance.position = window_world_position
	room_instance.add_child(clean_light_instance)
	room_instance.add_child(godray_instance)

	# Añadir el CollisionShape2D al nodo PlayerDetector
	var player_detector_node = room_instance.get_node("PlayerDetector")
	var collision_shape = CollisionShape2D.new()
	var rectangle_shape = RectangleShape2D.new()
	rectangle_shape.extents = Vector2(TILE_SIZE * 2, TILE_SIZE) / 2
	collision_shape.shape = rectangle_shape
	collision_shape.position = position2d2.position - Vector2(0, TILE_SIZE)
	collision_shape.disabled = false
	player_detector_node.add_child(collision_shape)

	# Generar tiles de la habitación
	var door_position = Vector2(door_x_position, 0)
	var entrance_position = Vector2(door_x_position, int(room.size.y - 1))
	var enemy_positions = generate_enemy_positions(room_instance, room.size, entrance_position,l_cuttof)

	generate_L_room_tiles(room_tilemap, room.size, entrance_position, door_position, enemy_positions, window_y_position, l_cuttof)
	# random entre esto y el generate classic

	rooms.append(room_instance)
	return room_instance

func generate_L_room_tiles(room_tilemap: TileMap, size: Vector2, entrance_pos: Vector2, door_pos: Vector2, enemy_positions: Array, window_y_position, L_cutoff: Vector2) -> void:
	print('generando room en forma de L')
	var room_string = ""
	print('enemy positions ', enemy_positions)

	# Ajustar la entrada para que esté en la esquina izquierda inferior
	#entrance_pos = Vector2(1, size.y - 1) # Posición (1, size.y - 1) para evitar colocarla en una pared
	var tile_map_layer = 0 
	for y in range(size.y):
		var row_string = ""
		for x in range(size.x):
			var current_pos = Vector2(x, y)
			
			# Solo continuar si la posición está dentro de la forma de "L"
			if not is_within_L_shape(current_pos, size, L_cutoff):
				if (x == L_cutoff.x and y == window_y_position):
					room_tilemap.set_cell(tile_map_layer, Vector2i(x,y), RIGHT_WINDOW_TILE_ID)
					row_string += "W"
					continue
				if (x == L_cutoff.x and y > L_cutoff.y):
					room_tilemap.set_cell(tile_map_layer, Vector2i(x,y), RIGHT_WALL_TILE_ID)
					row_string += "FOK" # 'FOK' representa los sueños frustrados
					continue
				if (x == L_cutoff.x and y == L_cutoff.y):
					room_tilemap.set_cell(tile_map_layer, Vector2i(x,y), WALL_TILE_ID)
					row_string += "ESKINA" # 'FOK' representa los sueños frustrados
					continue
				if (x > L_cutoff.x and y > L_cutoff.y):
					#room_tilemap.set_cell(x, y, RIGHT_WALL_TILE_ID)
					row_string += "FOK" # 'FOK' representa los sueños frustrados
					continue
			
			# Colocar paredes en los bordes de la "L"
			if (x == 0 or y == 0 or
				(x == int(size.x) - 1 and y < L_cutoff.y) or
				(y == int(size.y) - 1 and x < L_cutoff.x)):
				# No colocar una pared en la posición de entrada o puerta
				if current_pos == entrance_pos or current_pos == door_pos:
					room_tilemap.set_cell(tile_map_layer, Vector2i(x,y), FLOOR_TILE_ID)
					room_tilemap.set_cell(tile_map_layer, Vector2i(x-1,y), FLOOR_TILE_ID)
					row_string = "F"
				else:
					var tile_id = get_tile_id_for_position(x, y, size, entrance_pos)
					room_tilemap.set_cell(tile_map_layer, Vector2i(x,y), tile_id)
					row_string += str(tile_id)
			else:
				# Comprueba si la posición actual es una posición de enemigo
				if current_pos in enemy_positions:
					row_string += "E" # 'E' representa a un enemigo
					room_tilemap.set_cell(tile_map_layer, Vector2i(x,y), FLOOR_TILE_ID)
				elif current_pos == entrance_pos:
					room_tilemap.set_cell(tile_map_layer, Vector2i(x,y), FLOOR_TILE_ID)
					row_string += "F"
				elif current_pos == door_pos:
					room_tilemap.set_cell(tile_map_layer,Vector2i(x,y), FLOOR_TILE_ID)
					room_tilemap.set_cell(tile_map_layer, Vector2i(x-1,y), FLOOR_TILE_ID)
					row_string += "F"
				elif x == L_cutoff.x and y == window_y_position:
					#room_tilemap.set_cell(x, y, RIGHT_WINDOW_TILE_ID)
					row_string += "W"
				else:
					var tile_id = get_tile_id_for_position(x, y, size, entrance_pos)
					room_tilemap.set_cell(tile_map_layer, Vector2i(x,y), tile_id)
					row_string += str(tile_id)
		room_string += row_string + "\n"
	print(room_string)

# Función auxiliar para determinar si una posición está dentro de la forma de "L"
func is_within_L_shape(pos: Vector2, size: Vector2, L_cutoff: Vector2) -> bool:
	return (pos.x < L_cutoff.x or pos.y < L_cutoff.y)

func old_adjust_floor_tiles_in_string(row_string: String, x: int) -> String:
	if x == 0:
		return str(FLOOR_TILE_ID)
	elif x > 0 and len(row_string) > 0:
		return row_string.substr(0, row_string.length() - 1) + str(FLOOR_TILE_ID) + str(FLOOR_TILE_ID)
	return row_string

func get_tile_id_for_position(x: int, y: int, size: Vector2, entrance: Vector2) -> int:
	if y == 0:
		if x == 0:
			return LEFT_WALL_TILE_ID
		elif x == int(size.x) - 1:
			return RIGHT_WALL_TILE_ID
		else:
			return WALL_TILE_ID
	elif y == int(size.y) - 1:
		if x == 0:
			return LEFT_WALL_TILE_ID
		elif x == int(size.x) - 1:
			return RIGHT_WALL_TILE_ID
		else:
			return WALL_TILE_ID
	elif x == 0:
		return LEFT_WALL_TILE_ID
	elif x == int(size.x) - 1:
		return RIGHT_WALL_TILE_ID
	else:
		return FLOOR_TILE_ID

func generate_enemy_positions(room_instance: DungeonRoom, room_size: Vector2, entrance_pos: Vector2, l_cuttof: Vector2) -> Array:
	var enemy_positions_node = room_instance.get_node("EnemyPositions")
	var num_enemy_positions = int(randf_range(1, 4))
	var margin = 4
	var enemy_positions = []
	var available_positions = generate_available_positions(room_size, entrance_pos, margin, l_cuttof)

	for _i in range(num_enemy_positions):
		if available_positions.is_empty():
			break
		
		var position_index = randi() % available_positions.size()
		var chosen_position = available_positions[position_index]
		
		var position = Marker2D.new()
		position.position = chosen_position * TILE_SIZE
		enemy_positions_node.add_child(position)
		enemy_positions.append(chosen_position)
		
		available_positions = remove_nearby_positions(available_positions, chosen_position, 2)

	return enemy_positions

func generate_available_positions(room_size: Vector2, entrance_pos: Vector2, margin: int, l_cuttof: Vector2) -> Array:
	var available_positions = []
	for x in range(1, int(room_size.x) - l_cuttof.x):
		print('x',x)
		for y in range(1, int(room_size.y) - 1):
			var pos = Vector2(x, y)
			if pos.distance_to(entrance_pos) > margin:
				available_positions.append(pos)
	return available_positions

func remove_nearby_positions(positions: Array, center: Vector2, radius: int) -> Array:
	var new_positions = []
	for pos in positions:
		if pos.distance_to(center) > radius:
			new_positions.append(pos)
	return new_positions
