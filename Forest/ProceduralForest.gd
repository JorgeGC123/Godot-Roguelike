extends Node2D

const TILE_SIZE: int = 16
const DEEP_WATER_TILE_ID: int = 0
const SHALLOW_WATER_TILE_ID: int = 1
const SAND_TILE_ID: int = 2
const GRASS_TILE_ID: int = 3
const FOREST_TILE_ID: int = 4
const DENSE_FOREST_TILE_ID: int = 5
const MOUNTAIN_TILE_ID: int = 6
const VOID_TILE_ID: int = 9

export var width: int = 20
export var height: int = 20
export var base_noise_scale: float = 0.05
export var detail_noise_scale: float = 0.1
export var moisture_noise_scale: float = 0.07
export var temperature_noise_scale: float = 0.06
export var shape_noise_scale: float = 0.03
export var island_factor: float = 0.7
export var clearing_chance: float = 0.02
export var clearing_size_min: int = 3
export var clearing_size_max: int = 7

onready var tilemap: TileMap = $TileMapBase
onready var player: KinematicBody2D = get_node("Player")

var base_noise: OpenSimplexNoise = OpenSimplexNoise.new()
var detail_noise: OpenSimplexNoise = OpenSimplexNoise.new()
var moisture_noise: OpenSimplexNoise = OpenSimplexNoise.new()
var temperature_noise: OpenSimplexNoise = OpenSimplexNoise.new()
var shape_noise: OpenSimplexNoise = OpenSimplexNoise.new()

func _ready():
	randomize()
	initialize_noise()
	generate_terrain()
	create_rivers()
	create_natural_clearings()
	add_mountain_border()
	place_player_spawn()

func initialize_noise():
	base_noise.seed = randi()
	base_noise.octaves = 4
	base_noise.period = 80.0
	base_noise.persistence = 0.5

	detail_noise.seed = randi()
	detail_noise.octaves = 2
	detail_noise.period = 30.0
	detail_noise.persistence = 0.3

	moisture_noise.seed = randi()
	moisture_noise.octaves = 4
	moisture_noise.period = 60.0
	moisture_noise.persistence = 0.6

	temperature_noise.seed = randi()
	temperature_noise.octaves = 3
	temperature_noise.period = 70.0
	temperature_noise.persistence = 0.5

	shape_noise.seed = randi()
	shape_noise.octaves = 2
	shape_noise.period = 100.0
	shape_noise.persistence = 0.7

func generate_terrain():
	for x in range(width):
		for y in range(height):
			var shape_value = get_shape_value(x, y)
			if shape_value > 0:
				var base_value = base_noise.get_noise_2d(x * base_noise_scale, y * base_noise_scale)
				var detail_value = detail_noise.get_noise_2d(x * detail_noise_scale, y * detail_noise_scale)
				var moisture_value = moisture_noise.get_noise_2d(x * moisture_noise_scale, y * moisture_noise_scale)
				var temperature_value = temperature_noise.get_noise_2d(x * temperature_noise_scale, y * temperature_noise_scale)
				
				var combined_elevation = (base_value + detail_value * 0.5) / 1.5
				set_tile_based_on_noise(x, y, combined_elevation, moisture_value, temperature_value)
			else:
				tilemap.set_cell(x, y, VOID_TILE_ID)
	
	tilemap.update_bitmask_region(Vector2(0, 0), Vector2(width - 1, height - 1))

func set_tile_based_on_noise(x: int, y: int, elevation: float, moisture: float, temperature: float):
	var tile_id: int
	
	if elevation < -0.2:
		tile_id = DEEP_WATER_TILE_ID
	elif elevation < 0:
		tile_id = SHALLOW_WATER_TILE_ID
	elif elevation < 0.1:
		tile_id = SAND_TILE_ID
	elif elevation > 0.6:
		tile_id = MOUNTAIN_TILE_ID
	else:
		if moisture > 0.6 and temperature > 0:
			tile_id = DENSE_FOREST_TILE_ID
		elif moisture > 0.3 or (moisture > 0.2 and temperature > 0.2):
			tile_id = FOREST_TILE_ID
		else:
			tile_id = GRASS_TILE_ID
	
	tilemap.set_cell(x, y, tile_id)

func create_rivers():
	var river_start = Vector2(randi() % width, 0)
	var current_pos = river_start
	
	while current_pos.y < height:
		tilemap.set_cell(current_pos.x, current_pos.y, SHALLOW_WATER_TILE_ID)
		
		var next_pos = current_pos + Vector2(rand_range(-1, 1), 1).round()
		next_pos.x = clamp(next_pos.x, 0, width - 1)
		
		if randf() < 0.1:  # 10% chance to create a tributary
			create_tributary(current_pos)
		
		current_pos = next_pos

func create_tributary(start_pos: Vector2):
	var current_pos = start_pos
	var length = randi() % 5 + 3
	
	for _i in range(length):
		var next_pos = current_pos + Vector2(rand_range(-1, 1), rand_range(-1, 1)).round()
		next_pos.x = clamp(next_pos.x, 0, width - 1)
		next_pos.y = clamp(next_pos.y, 0, height - 1)
		
		tilemap.set_cell(next_pos.x, next_pos.y, SHALLOW_WATER_TILE_ID)
		current_pos = next_pos

func create_clearings():
	var num_clearings = randi() % 3 + 2
	for _i in range(num_clearings):
		var center = Vector2(randi() % width, randi() % height)
		var radius = randi() % 3 + 2
		
		for x in range(center.x - radius, center.x + radius + 1):
			for y in range(center.y - radius, center.y + radius + 1):
				if x >= 0 and x < width and y >= 0 and y < height:
					var distance = center.distance_to(Vector2(x, y))
					if distance <= radius and tilemap.get_cell(x, y) in [FOREST_TILE_ID, DENSE_FOREST_TILE_ID]:
						tilemap.set_cell(x, y, GRASS_TILE_ID)

func get_shape_value(x: int, y: int) -> float:
	var nx = float(x) / width - 0.5
	var ny = float(y) / height - 0.5
	var d = 2 * max(abs(nx), abs(ny))
	var gradient_value = 1 - d
	var noise_value = shape_noise.get_noise_2d(x * shape_noise_scale, y * shape_noise_scale)
	return gradient_value + noise_value * island_factor - (1 - island_factor)

func get_tile_type(x: int, y: int) -> int:
	return tilemap.get_cell(x, y)

func is_position_walkable(x: int, y: int) -> bool:
	var tile_type = get_tile_type(x, y)
	return tile_type in [SAND_TILE_ID, GRASS_TILE_ID, FOREST_TILE_ID]

func place_player_spawn():
	var center_x = width / 2
	var center_y = height / 2
	var spawn_pos = find_valid_spawn_position(center_x, center_y)
	
	var player_spawn = Position2D.new()
	player_spawn.name = "PlayerSpawnPos"
	player_spawn.position = Vector2(spawn_pos.x * TILE_SIZE, spawn_pos.y * TILE_SIZE)
	add_child(player_spawn)
	player.position = Vector2(spawn_pos.x * TILE_SIZE, spawn_pos.y * TILE_SIZE)

func find_valid_spawn_position(start_x: int, start_y: int) -> Vector2:
	var checked = {}
	var queue = []
	queue.push_back(Vector2(start_x, start_y))
	
	while not queue.empty():
		var pos = queue.pop_front()
		if checked.has(pos):
			continue
		
		checked[pos] = true
		
		if is_position_walkable(pos.x, pos.y):
			return pos
		
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				var new_pos = Vector2(pos.x + dx, pos.y + dy)
				if new_pos.x >= 0 and new_pos.x < width and new_pos.y >= 0 and new_pos.y < height:
					queue.push_back(new_pos)
	
	# Si no se encuentra una posición válida, retornamos el centro del mapa
	return Vector2(start_x, start_y)

func create_natural_clearings():
	for x in range(1, width - 1):
		for y in range(1, height - 1):
			if randf() < clearing_chance and is_forest_tile(x, y):
				create_clearing(x, y)

func is_forest_tile(x: int, y: int) -> bool:
	var tile = tilemap.get_cell(x, y)
	return tile == FOREST_TILE_ID or tile == DENSE_FOREST_TILE_ID

func create_clearing(center_x: int, center_y: int):
	var size = randi() % (clearing_size_max - clearing_size_min + 1) + clearing_size_min
	var shape = OpenSimplexNoise.new()
	shape.seed = randi()
	shape.octaves = 2
	shape.period = 10.0

	for x in range(center_x - size, center_x + size + 1):
		for y in range(center_y - size, center_y + size + 1):
			if x >= 0 and x < width and y >= 0 and y < height:
				var distance = Vector2(x - center_x, y - center_y).length()
				var noise_value = shape.get_noise_2d(x, y) * 0.5 + 0.5
				if distance < size * noise_value and is_forest_tile(x, y):
					tilemap.set_cell(x, y, GRASS_TILE_ID)

func add_mountain_border():
	for x in range(width):
		tilemap.set_cell(x, 0, MOUNTAIN_TILE_ID)
		tilemap.set_cell(x, height - 1, MOUNTAIN_TILE_ID)
	
	for y in range(height):
		tilemap.set_cell(0, y, MOUNTAIN_TILE_ID)
		tilemap.set_cell(width - 1, y, MOUNTAIN_TILE_ID)
