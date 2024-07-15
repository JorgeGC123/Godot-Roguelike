extends Navigation2D

const SPAWN_ROOMS: Array = [ preload ("res://Rooms/SpawnRoom2.tscn")]
const INTERMEDIATE_ROOMS: Array = [ preload ("res://Rooms/Room0.tscn"), preload ("res://Rooms/Room1.tscn"), preload ("res://Rooms/Room2.tscn"), preload ("res://Rooms/Room3.tscn"), preload ("res://Rooms/Room4.tscn")]
const SPECIAL_ROOMS: Array = [ preload ("res://Rooms/SpecialRoom0.tscn"), preload ("res://Rooms/SpecialRoom1.tscn")]
const END_ROOMS: Array = [ preload ("res://Rooms/EndRoom0.tscn")]
const SLIME_BOSS_SCENE: PackedScene = preload ("res://Rooms/SlimeBossRoom.tscn")
var is_day = rand_range( - 10, 10)
const TILE_SIZE: int = 16
const FLOOR_TILE_INDEX: int = 14
const RIGHT_WALL_TILE_INDEX: int = 5
const LEFT_WALL_TILE_INDEX: int = 6
const WALL_TILE_ID = 2
const TOP_WALL_TILE_ID = 1
const BOTTOM_WALL_TILE_ID = 11

export(int) var num_levels: int = 5

onready var player: KinematicBody2D = get_parent().get_node("Player")
onready var random_room_generator = preload ("res://Rooms/RandomDungeonRoom/RandomRoomGenerator.gd").new()
onready var advanced_room_generator = preload ("res://Rooms/RandomDungeonRoom/AdvancedRoomGenerator.gd").new()

func _ready() -> void:
	SavedData.num_floor += 1
	if SavedData.num_floor == 3:
		num_levels = 3
	_recursive_spawn_rooms()

func _recursive_spawn_rooms() -> void:
	var iteration = 1
	var special_room_spawned: bool = false
	var spawn_room: Node2D = SPAWN_ROOMS[randi() % SPAWN_ROOMS.size()].instance()
	#player.position = spawn_room.get_node("PlayerSpawnPos").position
	add_child(spawn_room)
	_spawn_next_room(spawn_room, 1, special_room_spawned, iteration, false)

func _spawn_next_room(previous_room: Node2D, current_level: int, special_room_spawned: bool, iteration: int, was_lateral: bool) -> void:
	if current_level >= num_levels:
		return
	
	var room: Node2D
	if current_level == num_levels - 1:
		room = END_ROOMS[randi() % END_ROOMS.size()].instance()
	elif SavedData.num_floor == 3 and current_level == num_levels - 2:
		room = SLIME_BOSS_SCENE.instance()
	elif (randi() % 3 == 0 and not special_room_spawned) or (current_level == num_levels - 2 and not special_room_spawned):
		room = SPECIAL_ROOMS[randi() % SPECIAL_ROOMS.size()].instance()
		special_room_spawned = true
	else:
		room = INTERMEDIATE_ROOMS[randi() % INTERMEDIATE_ROOMS.size()].instance()
	
	if previous_room.has_node("Doors/Door"):
		_spawn_corridor(previous_room, previous_room.get_node("Doors/Door"), room, false, current_level, special_room_spawned, iteration, was_lateral)
	# if previous_room.has_node("Doors/LateralDoor"):
	# 	_spawn_corridor(previous_room, previous_room.get_node("Doors/LateralDoor"), room, true, current_level, special_room_spawned, iteration, was_lateral)

func _spawn_corridor(previous_room: Node2D, previous_room_door: StaticBody2D, room: Node2D, is_lateral: bool, current_level: int, special_room_spawned: bool, iteration: int, was_lateral: bool) -> void:
	var previous_room_tilemap: TileMap = previous_room.get_node("TileMap")
	var previous_room_tilemap2: TileMap = previous_room.get_node("TileMap2")

	var exit_tile_pos: Vector2 = previous_room_tilemap.world_to_map(previous_room_door.position) + Vector2.UP * 2
	print('exit tile anterior: ', exit_tile_pos)
	var corridor_length: int = randi() % 10 + 20
	var corridor_height: int = randi() % 10 + 2
	var lateral_corridor_height: int = randi() % 10 + 2

	if !is_lateral:
		for y in corridor_height:
			previous_room_tilemap.set_cellv(exit_tile_pos + Vector2( - 2, -y), LEFT_WALL_TILE_INDEX)
			previous_room_tilemap.set_cellv(exit_tile_pos + Vector2( - 2, -y + 1), LEFT_WALL_TILE_INDEX)
			previous_room_tilemap.set_cellv(exit_tile_pos + Vector2( - 1, -y), FLOOR_TILE_INDEX)
			previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(0, -y), FLOOR_TILE_INDEX)
			previous_room_tilemap.set_cellv(exit_tile_pos + Vector2( - 1, -y + 1), FLOOR_TILE_INDEX)
			previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(0, -y + 1), FLOOR_TILE_INDEX)
			previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(1, -y), RIGHT_WALL_TILE_INDEX)
			previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(1, -y + 1), RIGHT_WALL_TILE_INDEX)
	else:
		for x in range(corridor_length):
			previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(x - 1, 1), TOP_WALL_TILE_ID)
			previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(x - 1, 2), FLOOR_TILE_INDEX)
			previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(x - 1, 3), FLOOR_TILE_INDEX)
			previous_room_tilemap2.set_cellv(exit_tile_pos + Vector2(x - 1, 3), BOTTOM_WALL_TILE_ID)
		for y in range(lateral_corridor_height):
			previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(corridor_length - 2, -y + 1), LEFT_WALL_TILE_INDEX)
			previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(corridor_length - 2, -y), LEFT_WALL_TILE_INDEX)
			previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(corridor_length + 1, -y + 1), RIGHT_WALL_TILE_INDEX)
			previous_room_tilemap.set_cellv(exit_tile_pos + Vector2(corridor_length + 1, -y), RIGHT_WALL_TILE_INDEX)
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
		previous_room_tilemap2.set_cellv(exit_tile_pos + Vector2(corridor_length + 1, + 3), RIGHT_WALL_TILE_INDEX)
		previous_room_tilemap2.set_cellv(exit_tile_pos + Vector2(corridor_length + 1, + 2), RIGHT_WALL_TILE_INDEX)

	var room_tilemap: TileMap = room.get_node("TileMap")
	print('door entrance de esta room: ', exit_tile_pos)
	
	if !is_lateral:
		if iteration == 2:
			var entrance_node: Position2D = room.get_node("Entrance/Position2D2")
			var previous_room_door_global_position: Vector2 = previous_room_door.global_position
			var entrance_global_position: Vector2 = entrance_node.global_position
			var room_offset: Vector2 = previous_room_door_global_position - entrance_global_position
			room.position = exit_tile_pos + room_offset
			print("First room alignment: ")
			print("previous_room_door_global_position: ", previous_room_door_global_position)
			print("entrance_global_position: ", entrance_global_position)
			print("room_offset: ", room_offset)
			print("room.position: ", room.position)
			print("room.global_position: ", room.global_position)
		else:
			room.position = previous_room_door.global_position + Vector2.UP * room_tilemap.get_used_rect().size.y * TILE_SIZE + Vector2.UP * (1 + corridor_height) * TILE_SIZE + Vector2.LEFT * room_tilemap.world_to_map(room.get_node("Entrance/Position2D2").position).x * TILE_SIZE
	else:
		room.position = previous_room_door.global_position + Vector2.UP * room_tilemap.get_used_rect().size.y * TILE_SIZE + Vector2.UP * (1 + lateral_corridor_height - 6) * TILE_SIZE + Vector2.LEFT + Vector2(corridor_length, 0) * TILE_SIZE + Vector2.LEFT * room_tilemap.world_to_map(room.get_node("Entrance/Position2D2").position).x * TILE_SIZE

	add_child(room)
	print(iteration)
	print(room.position)
	print('was lateral: ', was_lateral)

	_spawn_next_room(room, current_level + 1, special_room_spawned, iteration, is_lateral)
