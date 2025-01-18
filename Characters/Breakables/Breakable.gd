extends Character
class_name Breakable

var held_breakable: Node = null
var player setget set_player
onready var tween: Tween = get_node("Tween")
onready var tooltip: Label = get_node("Node2D/Tooltip")
#onready var animated_sprite: AnimatedSprite = get_node("AnimatedSprite")
# onready var collision_area: Area2D = get_node("Area2D")
onready var hitbox: Area2D = get_node("Hitbox")
var initial_tooltip_position: Vector2
var damage: int = 10 # Ajusta el daño según sea necesario
var knockback_direction: Vector2 = Vector2.ZERO
var knockback_force: int = 50

var nav_region: RID
export var obstacle_radius: float = 14.0 # Adjust based on your breakable size

export var shape_color: Color = Color(255.0, 0.0, 0.0, 0.5)
export var debug_draw: bool = true
var original_navpoly: NavigationPolygon = null
var nav_instance: NavigationPolygonInstance
var last_position: Vector2
var is_nav_dirty: bool = true
var base_navigation_outline: Array = []
var is_orbiting: bool = false
var dungeon_room: Node2D  # Referencia a la room padre

# Cargar el shader
onready var outline_shader = preload("res://Shaders/outline_shader.gdshader")
onready var original_material = null
onready var outline_material = ShaderMaterial.new()

func _ready():
	add_to_group("breakables")
	is_interpolating = false
	has_blood = false
	tooltip.visible = false
	var font = DynamicFont.new()
	font.size = 12
	tooltip.add_font_override("font", font)
	outline_material.shader = outline_shader
	#collision_area.connect("body_entered", self, "_on_CollisionArea_body_entered")
	hitbox.connect("body_entered", self, "_on_Hitbox_body_entered")
	hitbox.monitoring = false # Inicialmente desactivar la hitbox

	nav_instance = get_parent().get_node("NavigationPolygonInstance")
	
	dungeon_room = get_parent()

	if not dungeon_room:
		push_error("Breakable debe ser hijo de DungeonRoom")
		return


func set_player(new_player):
	if player and player.is_connected("breakable_picked_up", self, "_on_Player_breakable_picked_up"):
		# Desconectar señales del player anterior si existe y está conectado
		player.disconnect("breakable_picked_up", self, "_on_Player_breakable_picked_up")
		player.disconnect("breakable_dropped", self, "_on_Player_breakable_dropped")
	
	player = new_player
	
	if player:
		# Conectar señales al nuevo player
		if !player.is_connected("breakable_picked_up", self, "_on_Player_breakable_picked_up"):
			player.connect("breakable_picked_up", self, "_on_Player_breakable_picked_up")
			player.connect("breakable_dropped", self, "_on_Player_breakable_dropped")

func _on_Player_breakable_picked_up(breakable_node):
	if breakable_node == self:
		print("Este breakable fue recogido")
		# Cuando es recogido, restauramos la navegación original 
		# para que los NPCs no intenten evitar la posición anterior
		restore_original_navigation()

func _on_Player_breakable_dropped(breakable_node):
	if breakable_node == self:
		if dungeon_room:
			dungeon_room.update_navigation_with_all_breakables()

func _on_navigation_ready(region: RID):
	print("Señal navigation_ready recibida con región: ", region)
	nav_region = region
	#setup_navigation_obstacle()

func is_point_inside_polygon(point: Vector2, polygon: PoolVector2Array) -> bool:
	# Encontrar los límites del polígono
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	
	for p in polygon:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)
	
	# Primero, verificación rápida de bounds
	if point.x < min_x or point.x > max_x or point.y < min_y or point.y > max_y:
		print("Punto fuera de bounds: ", point)
		print("Bounds: ", Vector2(min_x, min_y), " -> ", Vector2(max_x, max_y))
		return false
	
	# Si pasa la verificación de bounds, considerarlo dentro
	return true

func setup_navigation_obstacle():
	if not nav_region:
		print("ERROR: No nav_region available")
		return
	
	var working_navpoly = NavigationPolygon.new()
	print("Outlines base count: ", base_navigation_outline.size())
	
	if base_navigation_outline.size() == 0:
		print("ERROR: No hay outlines base")
		return
		
	# Añadir el outline exterior
	var exterior_outline = duplicate_outline(base_navigation_outline[0])
	working_navpoly.add_outline(exterior_outline)
	
	# Encontrar bounds con margen
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	var MARGIN = 10.0  # Margen de tolerancia
	
	for p in exterior_outline:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)
	
	min_x -= MARGIN
	max_x += MARGIN
	min_y -= MARGIN
	max_y += MARGIN
	
	# Convertir posición global a local y ajustarla si está fuera
	var local_pos = nav_instance.to_local(global_position)
	local_pos.x = clamp(local_pos.x, min_x + obstacle_radius, max_x - obstacle_radius)
	local_pos.y = clamp(local_pos.y, min_y + obstacle_radius, max_y - obstacle_radius)
	
	print("Posición original: ", nav_instance.to_local(global_position))
	print("Posición ajustada: ", local_pos)
	
	# Crear el hueco octagonal
	var obstacle_points = PoolVector2Array()
	var num_sides = 8
	var radius = obstacle_radius
	
	for i in range(num_sides):
		var angle = -i * 2 * PI / num_sides
		var point = Vector2(
			local_pos.x + cos(angle) * radius,
			local_pos.y + sin(angle) * radius
		)
		obstacle_points.push_back(point)

	working_navpoly.add_outline(obstacle_points)
	
	for i in range(1, base_navigation_outline.size()):
		working_navpoly.add_outline(duplicate_outline(base_navigation_outline[i]))
	
	working_navpoly.make_polygons_from_outlines()
	
	if working_navpoly.get_polygon_count() > 0:
		Navigation2DServer.region_set_navpoly(nav_region, working_navpoly)
		Navigation2DServer.map_force_update(NavigationManager.nav_map)
		print("Navigation updated with obstacle")
		if debug_draw:
			update()
	else:
		print("ERROR: No polygons generated!")

func _draw():
	if debug_draw:
		# Dibuja el área del obstáculo en rojo semitransparente
		var color = Color(1, 0, 0, 0.3)
		draw_circle(Vector2.ZERO, obstacle_radius * 1.5, color)

func debug_navigation_state():
	print("------------- Navigation Debug -------------")
	print("Current position: ", global_position)
	print("Is navigation map active: ", Navigation2DServer.map_is_active(NavigationManager.nav_map))
	
	# Verificar si el punto actual está en una región navegable
	var closest_point = Navigation2DServer.map_get_closest_point(NavigationManager.nav_map, global_position)
	print("Closest navigable point: ", closest_point)
	print("Distance to closest point: ", global_position.distance_to(closest_point))
	print("----------------------------------------")

func duplicate_outline(outline: PoolVector2Array) -> PoolVector2Array:
	var new_outline = PoolVector2Array()
	for point in outline:
		new_outline.push_back(Vector2(point.x, point.y))
	return new_outline

func restore_original_navigation():
	if nav_region:
		print("Restoring original navigation")
		var clean_navpoly = original_navpoly.duplicate()
		Navigation2DServer.region_set_navpoly(nav_region, clean_navpoly)
		Navigation2DServer.map_force_update(NavigationManager.nav_map)
		is_nav_dirty = true

func _on_Area2D_body_entered(body):
	if body is Player:
		body.near_breakable = self
		apply_outline()
		tooltip.visible = false

func _on_Area2D_body_exited(body):
	if body is Player:
		body.near_breakable = null
		remove_outline()

func apply_outline():
	if original_material == null:
		original_material = animated_sprite.material
	animated_sprite.material = outline_material

func remove_outline():
	animated_sprite.material = original_material

func interpolate_pos(initial_pos: Vector2, final_pos: Vector2) -> void:
	is_interpolating = true
	is_orbiting = false
	hitbox.set_collision_mask_bit(0, false)
	tween.interpolate_property(self, "global_position", initial_pos, final_pos, 0.8, Tween.TRANS_QUART, Tween.EASE_OUT)
	tween.start()
	hitbox.monitoring = true
	knockback_direction = (final_pos - initial_pos).normalized()
	tween.connect("tween_completed", self, "_on_tween_completed")
	is_nav_dirty = true  # Mark navigation as needing update

func _on_CollisionArea_body_entered(body):
	if is_interpolating and (body is TileMap or body is StaticBody2D):
		# TODO: Esto debe de monitorizarlo el tilemap
		if body is TileMap:
			print(body)
			var local_position = body.to_local(self.global_position)
			var map_position = body.world_to_map(local_position)
			var WALL_TILE_ID = 2
			var BROKEN_WALL_TILE_ID = 27
			if (body.get_cellv(map_position + Vector2.UP) == WALL_TILE_ID):
				body.set_cellv(map_position + Vector2.UP, BROKEN_WALL_TILE_ID)
		tween.stop_all()
		hitbox.monitoring = false # Desactivar la hitbox al detenerse
		hitbox.set_collision_mask_bit(0, true) # Reactivar colisión con sí mismo
		print("Colisión con pared detectada")
		knockback_direction = Vector2.ZERO
		self.take_damage(damage, knockback_direction, knockback_force)

func _on_Hitbox_body_entered(body):
	if is_interpolating and (body != self and body.has_method("take_damage")):
		print('knockback', knockback_direction)
		body.take_damage(damage, knockback_direction, knockback_force)
		knockback_direction = Vector2.ZERO
		self.take_damage(damage, knockback_direction, knockback_force)
		print("Colisión con entidad detectada, causando daño")

func _on_tween_completed(object, key):
	if object == self and key == "global_position":
		hitbox.monitoring = false # Desactivar la hitbox después de la interpolación
		hitbox.set_collision_mask_bit(0, true) # Reactivar colisión con sí mismo
		is_interpolating = false
		tween.disconnect("tween_completed", self, "_on_tween_completed")

func _physics_process(_delta):
	if not is_orbiting and global_position.distance_to(last_position) > 1.0:
		last_position = global_position
		if dungeon_room:
			dungeon_room.update_navigation_with_all_breakables()

func update_navigation():
	if not nav_instance:
		return

func move_breakable(mouse_position: Vector2) -> void:
	if player and is_orbiting:
		var direction: Vector2 = (mouse_position - player.global_position).normalized()
		var distance: float = 18
		global_position = player.global_position + direction * distance

		# Mientras está siendo llevado, no necesitamos actualizar constantemente
		# el navigation polygon, simplemente mantenemos el original
		# if nav_instance and nav_instance.navpoly != original_navpoly:
		# 	restore_original_navigation()

func _process(delta):
	if player and is_orbiting:
		move_breakable(get_global_mouse_position())
	# elif not is_orbiting and is_nav_dirty:
	# 	# Solo actualizamos la navegación si:
	# 	# 1. No está siendo llevado
	# 	# 2. La flag is_nav_dirty está activa
	# 	var nav_instance = get_parent().get_node("NavigationPolygonInstance")
	# 	if nav_instance:
	# 		setup_navigation_obstacle(nav_instance)
	# 		is_nav_dirty = false


# func _exit_tree() -> void:
# 	print("Breakable: Cleaning up navigation obstacle")
# 	restore_original_navigation()
