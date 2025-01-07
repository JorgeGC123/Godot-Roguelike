extends Navigation2D

const SPAWN_ROOMS: Array = [preload("res://Rooms/SpawnRoom0.tscn")]
const INTERMEDIATE_ROOMS: Array = [preload("res://Rooms/Room0.tscn"), preload("res://Rooms/Room1.tscn"), preload("res://Rooms/Room2.tscn"), preload("res://Rooms/Room3.tscn"), preload("res://Rooms/Room4.tscn")]
const SPECIAL_ROOMS: Array = [preload("res://Rooms/SpecialRoom0.tscn"), preload("res://Rooms/SpecialRoom1.tscn")]
const END_ROOMS: Array = [preload("res://Rooms/EndRoom0.tscn")]
const SLIME_BOSS_SCENE: PackedScene = preload("res://Rooms/SlimeBossRoom.tscn")
var is_day = rand_range(-10, 10)
const TILE_SIZE: int = 16
const FLOOR_TILE_INDEX: int = 14
const RIGHT_WALL_TILE_INDEX: int = 5
const LEFT_WALL_TILE_INDEX: int = 6
const WALL_TILE_ID = 2
const TOP_WALL_TILE_ID = 1
const BOTTOM_WALL_TILE_ID = 11
const WALKABLE_TILES = [14]

export(int) var num_levels: int = 5

onready var player: KinematicBody2D = get_parent().get_node("Player")
onready var random_room_generator = preload("res://Rooms/RandomDungeonRoom/RandomRoomGenerator.gd").new()
onready var advanced_room_generator = preload("res://Rooms/RandomDungeonRoom/AdvancedRoomGenerator.gd").new()

func _ready() -> void:
	if SavedData.num_floor == 0:
		print("loadeo data")
		SavedData.load_data()
	SavedData.num_floor += 1
	if SavedData.num_floor == 3:
		num_levels = 3
	SavedData.save_data()
	_spawn_rooms()
	
func _spawn_rooms() -> void:
	var previous_room: Node2D
	var special_room_spawned: bool = false
	
	for i in num_levels:
		var room: Node2D
		
		if i == 0:
			room = SPAWN_ROOMS[randi() % SPAWN_ROOMS.size()].instance()
			player.position = room.get_node("PlayerSpawnPos").position
		else:
			if i == num_levels - 1:
				room = END_ROOMS[randi() % END_ROOMS.size()].instance()
			else:
				if SavedData.num_floor == 3:
					room = SLIME_BOSS_SCENE.instance()
				else:
					if (randi() % 3 == 0 and not special_room_spawned) or (i == num_levels - 2 and not special_room_spawned):
						room = SPECIAL_ROOMS[randi() % SPECIAL_ROOMS.size()].instance()
						special_room_spawned = true
					else:
						#room = random_room_generator.generate_random_room() # este genera habitaciones cuadradas básicas
						#room = advanced_room_generator.generate_random_room() # este habitaciones con forma de L 
						room = INTERMEDIATE_ROOMS[randi() % INTERMEDIATE_ROOMS.size()].instance() # este inyecta habitaciones prefabricadas
						
			var previous_room_tilemap: TileMap = previous_room.get_node("TileMap")
			var previous_room_tilemap2: TileMap = previous_room.get_node("TileMap2")
			var previous_room_door: StaticBody2D = null
			var is_lateral = false
			if previous_room.has_node("Doors/Door"):
				previous_room_door = previous_room.get_node("Doors/Door")
			elif previous_room.has_node("Doors/LateralDoor"):
				is_lateral = true
				previous_room_door = previous_room.get_node("Doors/LateralDoor")

			var exit_tile_pos: Vector2 = previous_room_tilemap.world_to_map(previous_room_door.position) + Vector2.UP * 2
			
			var corridor_length: int = randi() % 10 + 2
			var corridor_height: int = randi() % 10 + 2

			if !is_lateral:
				for y in corridor_height:
					# chapucilla para conectar bien las habitaciones con los pasillos
					previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(-2, -y), LEFT_WALL_TILE_INDEX)
					previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(-2, -y + 1), LEFT_WALL_TILE_INDEX)
					previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(-1, -y), FLOOR_TILE_INDEX)
					previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(0, -y), FLOOR_TILE_INDEX)
					previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(-1, -y + 1), FLOOR_TILE_INDEX)
					previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(0, -y + 1), FLOOR_TILE_INDEX)
					previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(1, -y), RIGHT_WALL_TILE_INDEX)
					previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(1, -y + 1), RIGHT_WALL_TILE_INDEX)
					
				previous_room_tilemap2.set_cellv(exit_tile_pos + Vector2(1, 1), TOP_WALL_TILE_ID)
				previous_room_tilemap2.set_cellv(exit_tile_pos + Vector2(-2, 1), TOP_WALL_TILE_ID)
			else:
				for x in range(corridor_length):
					# Conexión de habitaciones y pasillos laterales
					previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(x - 1, 1), TOP_WALL_TILE_ID)
					previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(x - 1, 2), FLOOR_TILE_INDEX)
					previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(x - 1, 3), FLOOR_TILE_INDEX)
					previous_room_tilemap2.set_cellv(exit_tile_pos + Vector2(x - 1, 3), BOTTOM_WALL_TILE_ID)

				for y in range(corridor_height):
					# ajuste paredes
					previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(corridor_length - 2, -y + 1), LEFT_WALL_TILE_INDEX)
					previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(corridor_length - 2, -y), LEFT_WALL_TILE_INDEX)
					previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(corridor_length + 1, -y + 1), RIGHT_WALL_TILE_INDEX)
					previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(corridor_length + 1, -y), RIGHT_WALL_TILE_INDEX)
					# ajuste suelos
					previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(corridor_length - 1, -y + 1), FLOOR_TILE_INDEX)
					previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(corridor_length - 1, -y), FLOOR_TILE_INDEX)
					previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(corridor_length, -y), FLOOR_TILE_INDEX)
					previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(corridor_length, -y + 1), FLOOR_TILE_INDEX)
					previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(corridor_length - 1, -y + 2), FLOOR_TILE_INDEX)
					previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(corridor_length, -y + 2), FLOOR_TILE_INDEX)
					previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(corridor_length - 1, -y + 3), FLOOR_TILE_INDEX)
					previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(corridor_length, -y + 3), FLOOR_TILE_INDEX)

				previous_room_tilemap2.set_cellv(exit_tile_pos + Vector2(corridor_length - 2, + 1), TOP_WALL_TILE_ID)
				previous_room_tilemap2.set_cellv(exit_tile_pos + Vector2(corridor_length, + 3), BOTTOM_WALL_TILE_ID)
				previous_room_tilemap2.set_cellv(exit_tile_pos + Vector2(corridor_length - 1, + 3), BOTTOM_WALL_TILE_ID)
				previous_room_tilemap2.set_cellv(exit_tile_pos + Vector2(corridor_length - 1, + 3), BOTTOM_WALL_TILE_ID)
				previous_room_tilemap2.set_cellv(exit_tile_pos + Vector2(corridor_length + 1, + 3), RIGHT_WALL_TILE_INDEX)
				previous_room_tilemap2.set_cellv(exit_tile_pos + Vector2(corridor_length + 1, + 2), RIGHT_WALL_TILE_INDEX)

			var room_tilemap: TileMap = room.get_node("TileMap")
			if !is_lateral:
				room.position = previous_room_door.global_position + Vector2.UP * room_tilemap.get_used_rect().size.y * TILE_SIZE + Vector2.UP * (1 + corridor_height) * TILE_SIZE + Vector2.LEFT * room_tilemap.world_to_map(room.get_node("Entrance/Position2D2").position).x * TILE_SIZE
			else:
				room.position = previous_room_door.global_position + Vector2.UP * room_tilemap.get_used_rect().size.y * TILE_SIZE + Vector2.UP * (1 + corridor_height) * TILE_SIZE + Vector2.LEFT + Vector2(corridor_length, 0) * TILE_SIZE + Vector2.LEFT * room_tilemap.world_to_map(room.get_node("Entrance/Position2D2").position).x * TILE_SIZE

			print(room.position)

		add_child(room)
		previous_room = room
		 # Create navigation polygon for the room we just added
		var navpoly = NavigationPolygon.new()
		var outline = _generate_room_outline(room)
		
		if not outline.empty():
			navpoly.add_outline(outline)
			navpoly.make_polygons_from_outlines()
			
			var navpoly_instance = NavigationPolygonInstance.new()
			navpoly_instance.navpoly = navpoly
			room.add_child(navpoly_instance)
			
			# Debug visualization (optional)
			_debug_draw_outline(outline)

func _generate_room_outline(room: Node2D) -> PoolVector2Array:
	var tilemap: TileMap = room.get_node("TileMap")
	var tilemap2: TileMap = room.get_node("TileMap2")
	var cells = tilemap.get_used_cells()
	var walkable_positions = []
	
	# Check both tilemaps for walkable cells
	for cell in cells:
		if _is_walkable_tile(tilemap.get_cellv(cell)):
			var world_pos = tilemap.map_to_world(cell)
			walkable_positions.append(world_pos)
			
	# If room has corridors, they'll be included in the tilemap cells
	
	return _create_outline_from_cells(walkable_positions)

func _is_walkable_tile(tile_id: int) -> bool:
	# Update this list with all your walkable tile IDs
	return tile_id == FLOOR_TILE_INDEX

func _create_outline_from_cells(positions: Array) -> PoolVector2Array:
	if positions.empty():
		return PoolVector2Array()
	
	# Find bounds
	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF
	
	for pos in positions:
		min_x = min(min_x, pos.x)
		min_y = min(min_y, pos.y)
		max_x = max(max_x, pos.x + TILE_SIZE)
		max_y = max(max_y, pos.y + TILE_SIZE)
	
	# Create outline vertices
	var outline = PoolVector2Array([
		Vector2(min_x, min_y),           # Top-left
		Vector2(max_x, min_y),           # Top-right
		Vector2(max_x, max_y),           # Bottom-right
		Vector2(min_x, max_y)            # Bottom-left
	])
	
	return outline

func _debug_draw_outline(outline: PoolVector2Array) -> void:
	if not Engine.editor_hint:
		var debug_line = Line2D.new()
		debug_line.points = outline
		debug_line.default_color = Color.green
		debug_line.width = 2.0
		add_child(debug_line)
