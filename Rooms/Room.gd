extends Node2D
class_name DungeonRoom
signal navigation_ready(nav_region)
export(bool) var boss_room: bool = false
var active_breakables: Array = []


const SPAWN_EXPLOSION_SCENE: PackedScene = preload("res://Characters/Enemies/SpawnExplosion.tscn")

const ENEMY_SCENES: Dictionary = {
	"FLYING_CREATURE": preload("res://Characters/Enemies/Flying Creature/FlyingCreature.tscn"),
	"GOBLIN": preload("res://Characters/Enemies/Goblin/Goblin.tscn"), "SLIME_BOSS": preload("res://Characters/Enemies/Bosses/SlimeBoss.tscn")
}

var num_enemies: int

var nav_region: RID
const WALKABLE_TILES = [14]


onready var tilemap: TileMap = get_node("TileMap2")
onready var entrance: Node2D = get_node("Entrance")
onready var door_container: Node2D = get_node("Doors")
onready var enemy_positions_container: Node2D = get_node("EnemyPositions")
onready var player_detector: Area2D = get_node("PlayerDetector")
const BREAKABLE_SCENE: PackedScene = preload("res://Characters/Breakables/Breakable.tscn")  # Asegúrate de cambiar la ruta

var breakable_positions: Array  # Almacena posiciones potenciales para spawnear Breakables

func _ready() -> void:
	num_enemies = enemy_positions_container.get_child_count()
	setup_navigation()
	find_existing_breakables()
	
	# Usar call_deferred para asegurar que la actualización ocurra después de que todo esté inicializado
	call_deferred("initial_navigation_update")

	connect("child_entered_tree", self, "_on_child_entered_tree")
	connect("child_exiting_tree", self, "_on_child_exiting_tree")

	#determine_breakable_positions()
	#spawn_breakables(randi() % 3 + 1)
	
func _on_child_entered_tree(node: Node) -> void:
	if node is Breakable:
		active_breakables.append(node)
		update_navigation_with_all_breakables()

func _on_child_exiting_tree(node: Node) -> void:
	if node is Breakable:
		active_breakables.erase(node)
		update_navigation_with_all_breakables()

func update_navigation_with_all_breakables() -> void:
	if not nav_region:
		push_warning("No hay región de navegación disponible")
		return
		
	print("Actualizando navegación con ", active_breakables.size(), " breakables activos")
	
	var working_navpoly = NavigationPolygon.new()
	var nav_instance = get_node("NavigationPolygonInstance")
	
	# Añadir el outline base
	for i in range(nav_instance.navpoly.get_outline_count()):
		working_navpoly.add_outline(
			nav_instance.navpoly.get_outline(i)
		)
	
	# Añadir obstáculos para cada breakable activo
	for breakable in active_breakables:
		if not breakable.is_orbiting:  # No añadir obstáculo si está siendo llevado
			var local_pos = nav_instance.to_local(breakable.global_position)
			var obstacle_points = create_obstacle_points(local_pos, breakable.obstacle_radius)
			working_navpoly.add_outline(obstacle_points)
			print("Añadido obstáculo para breakable en posición: ", breakable.global_position)
	
	working_navpoly.make_polygons_from_outlines()
	
	if working_navpoly.get_polygon_count() > 0:
		Navigation2DServer.region_set_navpoly(nav_region, working_navpoly)
		Navigation2DServer.map_force_update(NavigationManager.nav_map)
		print("Navegación actualizada exitosamente")
	else:
		push_warning("No se generaron polígonos en la actualización de navegación")

func create_obstacle_points(position: Vector2, radius: float) -> PoolVector2Array:
	var points = PoolVector2Array()
	var num_sides = 8
	
	for i in range(num_sides):
		var angle = -i * 2 * PI / num_sides
		var point = Vector2(
			position.x + cos(angle) * radius,
			position.y + sin(angle) * radius
		)
		points.push_back(point)
	
	return points
	
func determine_breakable_positions() -> void:
	breakable_positions = []
	for cell in tilemap.get_used_cells():
		# TODO: mapear el tilemap
		if tilemap.tile_set.tile_get_name(tilemap.get_cellv(cell)) == "full tilemap.png 10":
			breakable_positions.append(tilemap.map_to_world(cell))

func spawn_breakables(count: int) -> void:

	for _i in range(count):
		if breakable_positions.size() == 0:
			return  # No hay más posiciones disponibles

		var position_index = randi() % breakable_positions.size()
		var breakable = BREAKABLE_SCENE.instance()
		breakable.position = breakable_positions[position_index]
		add_child(breakable)
		breakable_positions.remove(position_index)  # Eliminar la posición para evitar spawns superpuestos	
	
func _on_enemy_killed() -> void:
	num_enemies -= 1
	# if num_enemies == 0:
	# 	_open_doors()
	
	
func _open_doors() -> void:
	print('damn')
	for door in door_container.get_children():
		print(door)
		door.open()
		
		
func _close_entrance() -> void:
	for entry_position in entrance.get_children():
		tilemap.set_cellv(tilemap.world_to_map(entry_position.position), 1)
		tilemap.set_cellv(tilemap.world_to_map(entry_position.position) + Vector2.DOWN, 2)
		
		
func _spawn_enemies() -> void:
	for enemy_position in enemy_positions_container.get_children():
		var enemy: KinematicBody2D
		if boss_room:
			enemy = ENEMY_SCENES.SLIME_BOSS.instance()
			num_enemies = 15
		else:
			if randi() % 2 == 0:
				enemy = ENEMY_SCENES.FLYING_CREATURE.instance()
			else:
				enemy = ENEMY_SCENES.GOBLIN.instance()
		enemy.position = enemy_position.position
		call_deferred("add_child", enemy)
		
		var spawn_explosion: AnimatedSprite = SPAWN_EXPLOSION_SCENE.instance()
		spawn_explosion.position = enemy_position.position
		call_deferred("add_child", spawn_explosion)



func _on_PlayerDetector_body_entered(_body: KinematicBody2D) -> void:
	print('damn')
	player_detector.queue_free()
	if num_enemies > 0:
		_close_entrance()
		_spawn_enemies()
	else:
		_close_entrance()
		_open_doors()

func setup_navigation():
	print("Configurando navegación para room")
	
	# Obtener el nodo NavigationPolygonInstance y su polígono
	var navigation_instance = get_node("NavigationPolygonInstance")
	if not navigation_instance:
		push_error("No se encontró el nodo NavigationPolygonInstance en la room")
		return
	
	var nav_poly = navigation_instance.navpoly
	if not nav_poly:
		push_error("No se encontró NavigationPolygon en el nodo NavigationPolygonInstance")
		return
		
	# Crear región y asignar el polígono existente
	nav_region = Navigation2DServer.region_create()
	Navigation2DServer.region_set_map(nav_region, NavigationManager.nav_map)
	Navigation2DServer.region_set_navpoly(nav_region, nav_poly)
	Navigation2DServer.region_set_transform(nav_region, navigation_instance.global_transform)
	Navigation2DServer.region_set_navigation_layers(nav_region, 1)
	Navigation2DServer.region_set_travel_cost(nav_region, 1)
	Navigation2DServer.map_force_update(NavigationManager.nav_map)
	print("Emitiendo señal navigation_ready con región: ", nav_region)
	emit_signal("navigation_ready", nav_region)

func _exit_tree():
	if nav_region:
		Navigation2DServer.free_rid(nav_region)

func initial_navigation_update() -> void:
	# Asegurarse de que la navegación esté configurada
	if nav_region:
		print("Actualizando navegación inicial con ", active_breakables.size(), " breakables")
		update_navigation_with_all_breakables()
	else:
		push_warning("Navigation no está lista durante la actualización inicial")

func find_existing_breakables() -> void:
	# Buscar todos los breakables que ya existen en la escena
	for child in get_children():
		if child is Breakable:
			if not active_breakables.has(child):  # Evitar duplicados
				active_breakables.append(child)
				print("Breakable encontrado y registrado: ", child.name)
