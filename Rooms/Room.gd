extends Node2D
class_name DungeonRoom

"""
TODO + Known issue: cuando placeas 1 breakable fuera de una zona navegable (una parte sin navpoly del mapa) el breakable no se toma en cuenta y el npc puede chocar
"""

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
const BREAKABLE_SCENE: PackedScene = preload("res://Characters/Breakables/Breakable.tscn") 

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
	
	print("Iniciando actualización de navegación con ", active_breakables.size(), " breakables")
	
	var working_navpoly = NavigationPolygon.new()
	var nav_instance = get_node("NavigationPolygonInstance")
	
	# Obtener y añadir TODOS los outlines originales
	var original_outline_count = nav_instance.navpoly.get_outline_count()
	for i in range(original_outline_count):
		var outline = nav_instance.navpoly.get_outline(i)
		working_navpoly.add_outline(outline)
		if i == 0:
			print("Añadido outline base con ", outline.size(), " puntos")
		else:
			print("Añadido hueco original #", i, " con ", outline.size(), " puntos")
	
	# Agrupar breakables cercanos
	var breakable_groups = group_nearby_breakables(active_breakables, nav_instance)
	print("Creados ", breakable_groups.size(), " grupos de breakables")
	
	# Obtener el outline base para validación
	var base_outline = nav_instance.navpoly.get_outline(0)
	
	# Crear un outline para cada grupo
	var outlines_added = 0
	for group in breakable_groups:
		print("Procesando grupo con ", group.size(), " breakables")
		var obstacle_outline = create_merged_obstacle(group, nav_instance)
		if obstacle_outline.size() > 0:
			# Verificar que el outline está en una zona válida
			var valid_position = true
			for point in obstacle_outline:
				if not is_point_in_navigable_area(point, nav_instance.navpoly):
					valid_position = false
					break
			
			if valid_position:
				working_navpoly.add_outline(obstacle_outline)
				outlines_added += 1
				print("Añadido outline para grupo con ", obstacle_outline.size(), " puntos")
			else:
				print("Outline descartado - puntos en zona no navegable")
	
	print("Total de outlines añadidos: ", outlines_added)
	working_navpoly.make_polygons_from_outlines()
	
	if working_navpoly.get_polygon_count() > 0:
		print("Polígonos generados: ", working_navpoly.get_polygon_count())
		Navigation2DServer.region_set_navpoly(nav_region, working_navpoly)
	else:
		push_error("Fallo al generar polígonos de navegación")
		restore_base_navigation()

func is_point_in_navigable_area(point: Vector2, navpoly: NavigationPolygon) -> bool:
	# Primero verificar si está dentro del outline base
	if not Geometry.is_point_in_polygon(point, navpoly.get_outline(0)):
		return false
		
	# Luego verificar que no está dentro de ningún hueco original
	for i in range(1, navpoly.get_outline_count()):
		if Geometry.is_point_in_polygon(point, navpoly.get_outline(i)):
			return false
	
	return true

func _draw() -> void:
	if not Engine.editor_hint:  # Solo en runtime
		var nav_instance = get_node("NavigationPolygonInstance")
		if nav_instance and nav_instance.navpoly:
			# Dibujar el polígono base
			var base_outline = nav_instance.navpoly.get_outline(0)
			draw_polyline(base_outline, Color.green, 2.0)
			
			# Dibujar los obstáculos
			for i in range(1, nav_instance.navpoly.get_outline_count()):
				var obstacle_outline = nav_instance.navpoly.get_outline(i)
				draw_polyline(obstacle_outline, Color.red, 2.0)

func group_nearby_breakables(breakables: Array, nav_instance: Node2D) -> Array:
	var groups = []
	var processed = []
	
	for breakable in breakables:
		if breakable.is_orbiting or processed.has(breakable):
			continue
		
		var current_group = [breakable]
		processed.append(breakable)
		
		# Buscar breakables cercanos
		for other in breakables:
			if other == breakable or other.is_orbiting or processed.has(other):
				continue
				
			var pos1 = nav_instance.to_local(breakable.global_position)
			var pos2 = nav_instance.to_local(other.global_position)
			var distance = pos1.distance_to(pos2)
			
			# Si están cerca, añadir al grupo
			if distance <= (breakable.obstacle_radius + other.obstacle_radius) * 1.5:
				current_group.append(other)
				processed.append(other)
				print("Breakable agrupado: distancia = ", distance)
		
		groups.append(current_group)
		print("Grupo creado con ", current_group.size(), " breakables")
	
	return groups

func create_merged_obstacle(breakables: Array, nav_instance: Node2D) -> PoolVector2Array:
	if breakables.empty():
		return PoolVector2Array()
	
	print("Creando obstáculo para ", breakables.size(), " breakables")
	
	# Si solo hay un breakable, usar la lógica normal
	if breakables.size() == 1:
		var pos = nav_instance.to_local(breakables[0].global_position)
		return create_single_obstacle(pos, breakables[0].obstacle_radius)
	
	# Para múltiples breakables, calcular el centro
	var center = Vector2.ZERO
	for breakable in breakables:
		var pos = nav_instance.to_local(breakable.global_position)
		center += pos
	center = center / breakables.size()
	
	# Calcular el radio necesario basado en la distancia al breakable más lejano
	var max_radius = 0
	for breakable in breakables:
		var pos = nav_instance.to_local(breakable.global_position)
		var distance_to_center = center.distance_to(pos)
		# El radio necesario es la distancia al centro más el radio del breakable
		var required_radius = distance_to_center + breakable.obstacle_radius
		max_radius = max(max_radius, required_radius)
	
	# Añadir un pequeño margen de seguridad (10%)
	max_radius *= 0.9
	
	print("Radio calculado para grupo: ", max_radius)
	return create_single_obstacle(center, max_radius)

func create_single_obstacle(position: Vector2, radius: float) -> PoolVector2Array:
	var points = PoolVector2Array()
	var num_sides = 8
	var adjusted_radius = min(radius, 32.0)  # Reducido a 32.0 para ser más conservador
	
	# IMPORTANTE: Generamos los puntos en sentido horario para los "agujeros"
	for i in range(num_sides):
		var angle = i * 2 * PI / num_sides  # Removido el negativo para cambiar la dirección
		var point = Vector2(
			position.x + cos(angle) * adjusted_radius,
			position.y + sin(angle) * adjusted_radius
		)
		points.push_back(point)
	
	print("Creado obstáculo con ", points.size(), " puntos y radio ", adjusted_radius)
	return points

func create_convex_hull(points: PoolVector2Array) -> PoolVector2Array:
	# Implementación simple del algoritmo Gift Wrapping (Jarvis March)
	if points.size() < 3:
		return points
		
	var hull = PoolVector2Array()
	
	# Encontrar el punto más a la izquierda
	var leftmost = 0
	for i in range(1, points.size()):
		if points[i].x < points[leftmost].x:
			leftmost = i
	
	var p = leftmost
	var q = 0
	
	# Repetir hasta volver al punto inicial
	while true:
		hull.push_back(points[p])
		
		q = (p + 1) % points.size()
		for i in range(points.size()):
			if i == p:
				continue
			# Si el punto i está más a la izquierda que el punto actual q
			if orientation(points[p], points[i], points[q]) == 2:
				q = i
		
		p = q
		
		# Si hemos vuelto al principio, terminar
		if p == leftmost:
			break
	
	return hull

func orientation(p: Vector2, q: Vector2, r: Vector2) -> int:
	var val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y)
	if val == 0:
		return 0
	return 1 if val > 0 else 2

func restore_base_navigation() -> void:
	var nav_instance = get_node("NavigationPolygonInstance")
	if nav_instance and nav_instance.navpoly:
		var base_navpoly = nav_instance.navpoly.duplicate()
		Navigation2DServer.region_set_navpoly(nav_region, base_navpoly)
		print("Navegación restaurada a estado base")

func create_obstacle_points(position: Vector2, radius: float) -> PoolVector2Array:
	var points = PoolVector2Array()
	var num_sides = 8
	
	# Ajustar el radio si es muy grande
	var adjusted_radius = min(radius, 32.0)  # Limitar el radio máximo
	
	for i in range(num_sides):
		var angle = -i * 2 * PI / num_sides
		var point = Vector2(
			position.x + cos(angle) * adjusted_radius,
			position.y + sin(angle) * adjusted_radius
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
