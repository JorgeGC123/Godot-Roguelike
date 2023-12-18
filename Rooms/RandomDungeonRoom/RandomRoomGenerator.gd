extends DungeonRoom

const TILE_SIZE = 16
const MAX_ROOM_SIZE = Vector2(15, 15)
const MIN_ROOM_SIZE = Vector2(5, 5)
const WALL_TILE_ID = 2
const FLOOR_TILE_ID = 14

var rooms = []
var door_scene = preload("res://Rooms/Furniture and Traps/Door.tscn") # Asegúrate de tener el camino correcto a la escena de la puerta.

func generate_random_room() -> DungeonRoom:
	var room_scene = load("res://Rooms/RandomDungeonRoom/RandomDungeonRoom.tscn") # Asegúrate de tener el camino correcto a la escena de DungeonRoom.
	var room_instance = room_scene.instance()
	var room_size = Vector2(rand_range(MIN_ROOM_SIZE.x, MAX_ROOM_SIZE.x), rand_range(MIN_ROOM_SIZE.y, MAX_ROOM_SIZE.y))
	# Instanciar y añadir la puerta
	var door_instance = door_scene.instance()
	var doors_node = room_instance.get_node("Doors")
	var door_x_position = randi() % (int(room_size.x) - 4) + 2
	door_instance.position = Vector2(door_x_position * TILE_SIZE, 0)
	doors_node.add_child(door_instance)  # Añade la puerta al nodo "Doors"
	print("Door position ",door_instance.position)
	var room_tilemap = room_instance.get_node("TileMap") as TileMap
	# añadir la entrada
	
	var entrance_node = room_instance.get_node("Entrance")
	var position2d = Position2D.new()  # Crear una instancia de Position2D
	position2d.name = "Position2D2"
	position2d.position = Vector2(door_x_position * TILE_SIZE, room_size.y * TILE_SIZE)
	print(position2d.position)
	print("entrance position ",position2d.position)
	entrance_node.add_child(position2d)
	# Añadir el CollisionShape2D al nodo PlayerDetector
	var player_detector_node = room_instance.get_node("PlayerDetector")

	var collision_shape = CollisionShape2D.new()
	var rectangle_shape = RectangleShape2D.new()
	rectangle_shape.extents = Vector2(TILE_SIZE * 2, TILE_SIZE) / 2  # El tamaño cubre dos tiles
	collision_shape.shape = rectangle_shape
	collision_shape.position = position2d.position - Vector2(0, TILE_SIZE)  # Posición encima de entrance_pos
	collision_shape.disabled = false
	player_detector_node.add_child(collision_shape)
	
	print(collision_shape.position)
	
	var door_position = Vector2(door_x_position, 0)  # Puerta siempre en la fila superior
	var entrance_position = Vector2(door_x_position, int(room_size.y - 1))  # Suponiendo que la entrada está siempre en la fila inferior
	generate_room_tiles(room_instance.get_node("TileMap") as TileMap, room_size, entrance_position, door_position)
	rooms.append(room_instance)
	return room_instance

func generate_room_tiles(room_tilemap: TileMap, size: Vector2, entrance_pos: Vector2, door_pos: Vector2) -> void:
	print('generando room')
	var room_string = ""
	for y in range(size.y):
		var row_string = ""
		for x in range(size.x):
			var current_pos = Vector2(x, y)
			# Comprobar si la posición actual es donde debe estar el CollisionShape2D
			if current_pos == entrance_pos - Vector2(0, 1) or current_pos == entrance_pos - Vector2(1, 1):
				row_string += "C"
			elif current_pos == door_pos or current_pos == entrance_pos:
				# Establecer tile de suelo para puerta y entrada, y su adyacente
				room_tilemap.set_cell(x, y, FLOOR_TILE_ID)
				room_tilemap.set_cell(x-1, y, FLOOR_TILE_ID)
				if x == 0:
					row_string += str(FLOOR_TILE_ID)  # Solo si la puerta/entrada está al principio
				elif x > 0 and len(row_string) > 0:
					# Aquí ajustamos el string de la fila para los dos tiles de suelo
					row_string = row_string.substr(0, row_string.length() - 1) + str(FLOOR_TILE_ID) + str(FLOOR_TILE_ID)
			else:
				var tile_id = get_tile_id_for_position(x, y, size, entrance_pos)
				room_tilemap.set_cell(x, y, tile_id)
				row_string += str(tile_id)
		room_string += row_string + "\n"
	print(room_string)


func get_tile_id_for_position(x: int, y: int, size: Vector2, entrance: Vector2) -> int:
	if x == 0 or y == 0 or x == int(size.x)-1 or y == int(size.y)-1:
		return WALL_TILE_ID
	else:
		return FLOOR_TILE_ID
