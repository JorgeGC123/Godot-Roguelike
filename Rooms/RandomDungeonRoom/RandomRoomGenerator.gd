extends DungeonRoom

const TILE_SIZE = 16
const MAX_ROOM_SIZE = Vector2(15, 15)
const MIN_ROOM_SIZE = Vector2(5, 5)
const WALL_TILE_ID = 2
const LEFT_WALL_TILE_ID = 6
const RIGHT_WALL_TILE_ID = 5
const FLOOR_TILE_ID = 14
const RIGHT_WINDOW_TILE_ID = 8

var rooms = []
var door_scene = preload("res://Rooms/Furniture and Traps/Door.tscn") 
var breakable_torch_scene = preload("res://Characters/Breakables/Torch/BreakableTorch.tscn")
var clean_light_scene = preload("res://Characters/Breakables/Torch/CleanLight.tscn")
var god_rays_scene = preload("res://Godrays/SunGodRays.tscn")

func generate_random_room() -> DungeonRoom:
	var room_scene = load("res://Rooms/RandomDungeonRoom/RandomDungeonRoom.tscn") # Asegúrate de tener el camino correcto a la escena de DungeonRoom.
	var room_instance = room_scene.instance()
	var room_size = Vector2(rand_range(MIN_ROOM_SIZE.x, MAX_ROOM_SIZE.x), rand_range(MIN_ROOM_SIZE.y, MAX_ROOM_SIZE.y) + 1)
	# Instanciar y añadir la puerta
	var door_instance = door_scene.instance()
	var doors_node = room_instance.get_node("Doors")
	var door_x_position = randi() % (int(room_size.x) - 4) + 2
	door_instance.position = Vector2(door_x_position * TILE_SIZE, 0)
	doors_node.add_child(door_instance)  # Añade la puerta al nodo "Doors"
	print("Door position ",door_instance.position)
	#var room_tilemap = room_instance.get_node("TileMap") as TileMap
	# añadir la entrada
	
	var entrance_node = room_instance.get_node("Entrance")
	var position2d2 = Position2D.new()  # Crear una instancia de Position2D
	position2d2.name = "Position2D2"
	position2d2.position = Vector2(door_x_position * TILE_SIZE, room_size.y * TILE_SIZE)
	print(position2d2.position)
	print("entrance position ",position2d2.position)
	entrance_node.add_child(position2d2)
	var position2d = Position2D.new()  # Crear una instancia de Position2D
	position2d.name = "Position2D"
	position2d.position = Vector2(door_x_position * TILE_SIZE-1, room_size.y * TILE_SIZE)
	print(position2d.position)
	print("entrance position ",position2d.position)
	entrance_node.add_child(position2d)

	# Añadir BreakableTorch en una posición aleatoria de la pared superior
	var breakable_torch_instance = breakable_torch_scene.instance()
	var torch_x_position = randi() % (int(room_size.x) - 2) + 1
	while torch_x_position == door_x_position:
		torch_x_position = randi() % (int(room_size.x) - 2) + 1
	breakable_torch_instance.position = Vector2(torch_x_position * TILE_SIZE, 6)
	room_instance.add_child(breakable_torch_instance)

	# Añadir la ventana y los godrays:
	var margin = max(1, int(room_size.y / 4))  # Por ejemplo, excluimos el 25% superior e inferior
	var central_range_start = margin
	var central_range_end = int(room_size.y) - margin
	# Elegir una posición 'y' dentro del rango central
	var window_y_position = randi() % (central_range_end - central_range_start) + central_range_start
	# Asegurarse de que la posición 'y' es válida (por si acaso)
	window_y_position = clamp(window_y_position, 1, int(room_size.y) - 2)
	var clean_light_instance = clean_light_scene.instance()
	var godray_instance = god_rays_scene.instance()
	var window_world_position = room_instance.get_node("TileMap").map_to_world(Vector2(room_size.x - 1, window_y_position))
	clean_light_instance.position = window_world_position
	godray_instance.position = window_world_position
	room_instance.add_child(clean_light_instance)
	room_instance.add_child(godray_instance	)
	# Añadir el CollisionShape2D al nodo PlayerDetector
	var player_detector_node = room_instance.get_node("PlayerDetector")
	var collision_shape = CollisionShape2D.new()
	var rectangle_shape = RectangleShape2D.new()
	rectangle_shape.extents = Vector2(TILE_SIZE * 2, TILE_SIZE) / 2  # El tamaño cubre dos tiles
	collision_shape.shape = rectangle_shape
	collision_shape.position = position2d2.position - Vector2(0, TILE_SIZE)  # Posición encima de entrance_pos
	collision_shape.disabled = false
	player_detector_node.add_child(collision_shape)
	
	print(collision_shape.position)
	
	var door_position = Vector2(door_x_position, 0)  # Puerta siempre en la fila superior
	var entrance_position = Vector2(door_x_position, int(room_size.y - 1)) 
	var enemy_positions = generate_enemy_positions(room_instance, room_size, entrance_position)
	generate_room_tiles(room_instance.get_node("TileMap") as TileMap, room_size, entrance_position, door_position,enemy_positions,window_y_position)

	rooms.append(room_instance)
	return room_instance

func generate_room_tiles(room_tilemap: TileMap, size: Vector2, entrance_pos: Vector2, door_pos: Vector2, enemy_positions: Array,window_y_position) -> void:
	print('generando room')
	var room_string = ""
	print('enemy positions ',enemy_positions)
	# Ajustar la fila superior de la pared
	for x in range(size.x):
		if x == 0:
			room_tilemap.set_cell(x, 0, WALL_TILE_ID)  # Esquina superior izquierda
		elif x == int(size.x) - 1:
			room_tilemap.set_cell(x, 0, WALL_TILE_ID)  # Esquina superior derecha
		else:
			room_tilemap.set_cell(x, 0, WALL_TILE_ID)  # Pared superior
	for y in range(size.y):
		var row_string = ""
		for x in range(size.x):
			var current_pos = Vector2(x, y)
			# Comprueba si la posición actual es una posición de enemigo
			if current_pos in enemy_positions:
				row_string += "E"  # 'E' representa a un enemigo
				room_tilemap.set_cell(x, y, 14)
			elif current_pos == entrance_pos - Vector2(0, 1) or current_pos == entrance_pos - Vector2(1, 1):
				row_string += "C"
				room_tilemap.set_cell(x, y, 14)
			# Tratar door_pos
			elif current_pos == door_pos:
				# Establecer tile de suelo para la puerta y su adyacente
				room_tilemap.set_cell(x, y, FLOOR_TILE_ID)
				room_tilemap.set_cell(x-1, y, FLOOR_TILE_ID)
				# Ajustar el string de la fila para los dos tiles de suelo
				row_string = adjust_floor_tiles_in_string(row_string, x)
			# Tratar entrance_pos
			elif current_pos == entrance_pos:
				# Establecer tile de suelo para la entrada y su adyacente
				room_tilemap.set_cell(x, y, FLOOR_TILE_ID)
				room_tilemap.set_cell(x-1, y, FLOOR_TILE_ID)
				# Ajustar el string de la fila para los dos tiles de suelo
				row_string = adjust_floor_tiles_in_string(row_string, x)
			elif x == int(size.x) - 1 and y == window_y_position:
				room_tilemap.set_cell(x, y, RIGHT_WINDOW_TILE_ID)
			else:
				# Otros tiles
				var tile_id = get_tile_id_for_position(x, y, size, entrance_pos)
				room_tilemap.set_cell(x, y, tile_id)
				row_string += str(tile_id)
		room_string += row_string + "\n"
	print(room_string)

func adjust_floor_tiles_in_string(row_string: String, x: int) -> String:
	# Esta función ajusta la cadena de la fila para incluir dos tiles de suelo
	if x == 0:
		return str(FLOOR_TILE_ID)  # Solo si la puerta/entrada está al principio
	elif x > 0 and len(row_string) > 0:
		return row_string.substr(0, row_string.length() - 1) + str(FLOOR_TILE_ID) + str(FLOOR_TILE_ID)
	return row_string


func get_tile_id_for_position(x: int, y: int, size: Vector2, entrance: Vector2) -> int:
	if y == 0:
		if x == 0:
			return LEFT_WALL_TILE_ID  # Esquina superior izquierda
		elif x == int(size.x) - 1:
			return RIGHT_WALL_TILE_ID  # Esquina superior derecha
		else:
			return WALL_TILE_ID  # Pared superior
	elif y == int(size.y) - 1:
		if x == 0:
			return LEFT_WALL_TILE_ID  # Esquina inferior izquierda
		elif x == int(size.x) - 1:
			return RIGHT_WALL_TILE_ID  # Esquina inferior derecha
		else:
			return WALL_TILE_ID  # Pared inferior
	elif x == 0:
		return LEFT_WALL_TILE_ID  # Pared izquierda
	elif x == int(size.x) - 1:
		return RIGHT_WALL_TILE_ID  # Pared derecha
	else:
		return FLOOR_TILE_ID  # Suelo
	

func generate_enemy_positions(room_instance: DungeonRoom, room_size: Vector2, entrance_pos: Vector2) -> Array:
	var enemy_positions_node = room_instance.get_node("EnemyPositions")
	var num_enemy_positions = rand_range(1, 3)
	var margin = 4
	var enemy_positions = []

	for _i in range(num_enemy_positions):
		var position_valid = false
		var potential_position = Vector2()

		while not position_valid:
			potential_position.x = rand_range(1, room_size.x - 2)
			potential_position.y = rand_range(1, room_size.y - 2)
			
			position_valid = true
			for mx in range(-margin, margin + 1):
				for my in range(-margin, margin + 1):
					if potential_position == entrance_pos + Vector2(mx, my):
						position_valid = false
						break
				if not position_valid:
					break

		if position_valid:
			var position = Position2D.new()
			# Redondear las posiciones a enteros
			var rounded_x = int(potential_position.x)
			var rounded_y = int(potential_position.y)
			position.position = Vector2(rounded_x, rounded_y) * TILE_SIZE
			enemy_positions_node.add_child(position)
			enemy_positions.append(Vector2(rounded_x, rounded_y))

	return enemy_positions
		
